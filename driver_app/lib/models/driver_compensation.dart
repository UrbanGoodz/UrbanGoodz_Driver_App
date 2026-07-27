/// The driver-facing compensation contract.
///
/// The backend compensation engine is not deployed yet. This file is the app
/// side of the contract only: it parses what the backend will send and refuses
/// to invent anything it did not.
///
/// Three rules drive the whole design.
///
/// 1. Money is integer cents, from the backend, always. No doubles, no string
///    parsing of formatted currency, and no arithmetic that produces a figure
///    the backend did not state. [totalCents] is read from the backend's own
///    final/estimated field; this class never sums the components to derive
///    it. If the backend's total disagrees with its components, the backend's
///    total is what the driver is shown, because the backend is the payer of
///    record.
///
/// 2. Absent is not zero. Every amount is a nullable `int?`. A field the
///    backend omitted stays `null` and is not rendered. Rendering an omitted
///    field as `$0.00` would tell a driver they earned nothing for a leg that
///    simply has not been computed, which is the specific failure this class
///    exists to prevent.
///
/// 3. No compensation block means no compensation UI. When the backend sends
///    nothing usable, [DriverCompensation.tryParse] returns `null` and the
///    caller shows [DriverCompensation.unavailableMessage]. It does not show
///    an empty breakdown, and it does not show `$0.00`.
library;

/// How settled the amounts are.
///
/// Ordered by how much the driver can rely on the figure. The distinction
/// matters because a driver who reads an estimate as final pay has been
/// misled, and one who reads an adjusted figure as unchanged has lost the
/// signal that support altered it.
enum CompensationStage {
  /// Backend has computed a projection; the figure can still move.
  estimate,

  /// The driver accepted the job at this figure. Still not settled, but no
  /// longer a bare projection.
  accepted,

  /// Backend has settled the job; the figure will not move again.
  settled,

  /// Settled, then changed afterwards by an adjustment. Distinct from
  /// [settled] so the change is visible rather than silent.
  adjusted,

  /// The backend did not say. Treated as unknown, never as settled.
  unknown,
}

/// Where the money is in the payout pipeline.
enum PayoutStatus { pending, processing, paid, failed, unknown }

/// One labelled line of the breakdown.
class CompensationLine {
  final String label;
  final int cents;

  const CompensationLine(this.label, this.cents);

  String get formatted => DriverCompensation.formatCents(cents);
}

class DriverCompensation {
  /// Shown whenever the backend did not supply a usable compensation block.
  static const String unavailableMessage = 'Compensation details unavailable';

  /// The backend's own total. Never derived in the app.
  final int? totalCents;

  final int? basePayCents;
  final int? mileageCents;
  final int? deadheadCents;
  final int? stopsCents;
  final int? packagesCents;
  final int? bonusesCents;
  final int? detentionCents;

  /// Reimbursements the driver fronted (tolls, fuel, lumper). Pass-through:
  /// the platform is repaying a cost, not paying for labour.
  final int? passThroughCents;

  /// Corrections applied by support. May be negative.
  final int? adjustmentsCents;

  final CompensationStage stage;
  final PayoutStatus payoutStatus;
  final String currency;

  const DriverCompensation({
    this.totalCents,
    this.basePayCents,
    this.mileageCents,
    this.deadheadCents,
    this.stopsCents,
    this.packagesCents,
    this.bonusesCents,
    this.detentionCents,
    this.passThroughCents,
    this.adjustmentsCents,
    this.stage = CompensationStage.unknown,
    this.payoutStatus = PayoutStatus.unknown,
    this.currency = 'USD',
  });

  /// Parses a compensation block, or returns `null` when the backend sent
  /// nothing usable.
  ///
  /// `null` is the signal to display [unavailableMessage]. It is returned when
  /// [json] is null, or when every monetary field is absent: a block carrying
  /// only a status and no money cannot be shown as a compensation figure.
  ///
  /// Accepts the block either at the top level or nested under `compensation`,
  /// since the assignment payload will carry it as a sub-object.
  static DriverCompensation? tryParse(Map<String, dynamic>? json) {
    if (json == null) return null;

    final block = json['compensation'] is Map
        ? Map<String, dynamic>.from(json['compensation'] as Map)
        : json;

    final parsed = DriverCompensation(
      totalCents: _cents(block, const [
        'final_amount_cents',
        'estimated_driver_amount_cents',
        'total_cents',
      ]),
      basePayCents: _cents(block, const ['base_pay_cents']),
      mileageCents: _cents(block, const ['mileage_cents']),
      deadheadCents: _cents(block, const ['deadhead_cents']),
      stopsCents: _cents(block, const ['stops_cents']),
      packagesCents: _cents(block, const ['packages_cents']),
      bonusesCents: _cents(block, const ['bonuses_cents']),
      detentionCents: _cents(block, const ['detention_cents']),
      passThroughCents: _cents(block, const [
        'pass_through_cents',
        'reimbursements_cents',
      ]),
      adjustmentsCents: _cents(block, const ['adjustments_cents']),
      stage: _stage(block),
      payoutStatus: _payout(block),
      currency: (block['currency'] as String?)?.toUpperCase() ?? 'USD',
    );

    return parsed.hasAnyAmount ? parsed : null;
  }

  /// True when the backend supplied at least one monetary figure.
  bool get hasAnyAmount =>
      totalCents != null ||
      basePayCents != null ||
      mileageCents != null ||
      deadheadCents != null ||
      stopsCents != null ||
      packagesCents != null ||
      bonusesCents != null ||
      detentionCents != null ||
      passThroughCents != null ||
      adjustmentsCents != null;

  /// The breakdown lines the backend actually sent, in display order.
  /// Omitted components are absent from this list, not zeroed into it.
  List<CompensationLine> get lines => <CompensationLine>[
    if (basePayCents != null) CompensationLine('Base pay', basePayCents!),
    if (mileageCents != null) CompensationLine('Mileage', mileageCents!),
    if (deadheadCents != null) CompensationLine('Deadhead', deadheadCents!),
    if (stopsCents != null) CompensationLine('Stops', stopsCents!),
    if (packagesCents != null) CompensationLine('Packages', packagesCents!),
    if (bonusesCents != null) CompensationLine('Bonuses', bonusesCents!),
    if (detentionCents != null) CompensationLine('Detention', detentionCents!),
    if (passThroughCents != null)
      CompensationLine('Reimbursements', passThroughCents!),
    if (adjustmentsCents != null)
      CompensationLine('Adjustments', adjustmentsCents!),
  ];

  /// The total as text, or `null` when the backend stated no total.
  ///
  /// Deliberately does not fall back to summing [lines]: a total the backend
  /// did not state is a total the app must not claim.
  String? get formattedTotal =>
      totalCents == null ? null : formatCents(totalCents!);

  /// How the total should be labelled, so an estimate is never read as
  /// settled pay.
  String get totalLabel => switch (stage) {
    CompensationStage.estimate => 'Estimated total',
    CompensationStage.accepted => 'Accepted total',
    CompensationStage.settled => 'Final total',
    CompensationStage.adjusted => 'Adjusted total',
    CompensationStage.unknown => 'Total',
  };

  /// True only when the backend says the figure will not move again.
  /// [adjusted] counts: it is settled, just settled at a changed figure.
  bool get isSettled =>
      stage == CompensationStage.settled || stage == CompensationStage.adjusted;

  String get payoutLabel => switch (payoutStatus) {
    PayoutStatus.pending => 'Payout pending',
    PayoutStatus.processing => 'Payout processing',
    PayoutStatus.paid => 'Paid',
    PayoutStatus.failed => 'Payout failed',
    PayoutStatus.unknown => 'Payout status unavailable',
  };

  /// Formats integer cents as currency. Negative amounts (adjustments,
  /// clawbacks) render with a leading minus rather than wrapping to a
  /// nonsensical positive.
  static String formatCents(int cents) {
    final negative = cents < 0;
    final abs = cents.abs();
    final dollars = abs ~/ 100;
    final remainder = (abs % 100).toString().padLeft(2, '0');
    return '${negative ? '-' : ''}\$$dollars.$remainder';
  }

  /// Reads an integer-cents field, trying each accepted key in order.
  ///
  /// Rejects formatted strings and non-integral doubles outright. A backend
  /// that sends `12.34` where cents were specified has broken the contract,
  /// and silently coercing it would turn $12.34 into 12 cents. Returning
  /// `null` surfaces the break as "unavailable" rather than as a wrong number.
  static int? _cents(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is int) return value;
      // Some encoders emit 1200.0 for 1200. Accept only exactly-integral
      // doubles; anything with a fractional part is a contract violation.
      if (value is double && value == value.roundToDouble()) {
        return value.toInt();
      }
    }
    return null;
  }

  static CompensationStage _stage(Map<String, dynamic> json) {
    final raw = (json['compensation_status'] ?? json['stage'] ?? json['status'])
        ?.toString()
        .toLowerCase();
    return switch (raw) {
      'estimate' || 'estimated' || 'projected' => CompensationStage.estimate,
      'accepted' || 'agreed' => CompensationStage.accepted,
      'final' || 'settled' => CompensationStage.settled,
      'adjusted' || 'amended' || 'corrected' => CompensationStage.adjusted,
      // An unrecognised stage is never promoted to settled: a driver must
      // not read an unknown state as pay they can count on.
      _ => CompensationStage.unknown,
    };
  }

  static PayoutStatus _payout(Map<String, dynamic> json) {
    final raw = json['payout_status']?.toString().toLowerCase();
    return switch (raw) {
      'pending' => PayoutStatus.pending,
      'processing' || 'in_transit' => PayoutStatus.processing,
      'paid' || 'settled' || 'complete' || 'completed' => PayoutStatus.paid,
      'failed' || 'returned' => PayoutStatus.failed,
      _ => PayoutStatus.unknown,
    };
  }
}
