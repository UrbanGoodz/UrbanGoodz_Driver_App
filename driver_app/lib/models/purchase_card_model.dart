/// Order Anywhere purchase-card contract for the Driver app.
///
/// The backend is the single source of truth for the card lifecycle. This model
/// never invents a value: every money field is nullable and renders as
/// "unavailable" rather than a fabricated `$0.00`, and every unrecognised
/// status collapses to [CardLifecycleState.unknown], which the UI presents as a
/// truthful generic support state instead of guessing.
library;

/// The canonical driver-facing lifecycle.
///
/// Sourced from the backend `workflow_status` field. `card_status` is the raw
/// provider-level status and is deliberately NOT used for gating — it carries
/// provider vocabulary ("used", "requested") that does not map one-to-one onto
/// what the driver is allowed to do.
enum CardLifecycleState {
  awaitingCustomerPayment('awaiting_customer_payment'),
  awaitingDriverAssignment('awaiting_driver_assignment'),
  awaitingProviderConfiguration('awaiting_provider_configuration'),
  issuancePending('issuance_pending'),
  cardAvailable('card_available'),
  secureRevealAvailable('secure_reveal_available'),
  purchaseAuthorized('purchase_authorized'),
  purchaseCompleted('purchase_completed'),
  receiptRequired('receipt_required'),
  reconciliationPending('reconciliation_pending'),
  reconciled('reconciled'),
  frozen('frozen'),
  canceled('canceled'),
  expired('expired'),
  issuanceFailed('issuance_failed'),
  supportRequired('support_required'),

  /// Anything the backend sends that this build does not recognise. Fails safe:
  /// no card actions are offered and the driver is pointed at support.
  unknown('unknown');

  const CardLifecycleState(this.wireValue);

  final String wireValue;

  /// Maps a backend string onto the lifecycle, tolerating both the US and UK
  /// spellings of "cancelled" because the Laravel side stores `cancelled`
  /// while the driver contract publishes `canceled`.
  static CardLifecycleState parse(String? raw) {
    if (raw == null) return CardLifecycleState.unknown;
    final value = raw.trim().toLowerCase();
    if (value.isEmpty) return CardLifecycleState.unknown;
    if (value == 'cancelled') return CardLifecycleState.canceled;
    for (final state in CardLifecycleState.values) {
      if (state.wireValue == value) return state;
    }
    return CardLifecycleState.unknown;
  }

  /// States in which no card exists yet and none is expected imminently, so the
  /// UI must not imply the driver is waiting on a card that is being made.
  bool get isPreIssuance =>
      this == awaitingCustomerPayment ||
      this == awaitingDriverAssignment ||
      this == awaitingProviderConfiguration;

  /// States in which the card is finished and no further driver action applies.
  bool get isTerminal =>
      this == reconciled ||
      this == canceled ||
      this == expired ||
      this == issuanceFailed;

  /// Whether a receipt may be submitted. Deliberately narrow: submitting a
  /// receipt against a card that has not been used corrupts reconciliation.
  bool get allowsReceiptUpload =>
      this == receiptRequired ||
      this == purchaseCompleted ||
      this == purchaseAuthorized;

  /// Whether failure reporting is meaningful. Excluded before assignment and
  /// after reconciliation, where there is nothing for support to act on.
  bool get allowsFailureReport =>
      this != awaitingDriverAssignment &&
      this != awaitingCustomerPayment &&
      this != reconciled;
}

/// Provider configuration state, reported by the backend independently of any
/// individual card. While this is not `configured`, no card can exist and the
/// app must never offer issuance or reveal.
enum ProviderConfigurationStatus {
  configured('configured'),
  notConfigured('not_configured'),
  emergencyDisabled('emergency_disabled'),
  unknown('unknown');

  const ProviderConfigurationStatus(this.wireValue);

  final String wireValue;

  static ProviderConfigurationStatus parse(String? raw) {
    if (raw == null) return ProviderConfigurationStatus.unknown;
    final value = raw.trim().toLowerCase();
    for (final status in ProviderConfigurationStatus.values) {
      if (status.wireValue == value) return status;
    }
    return ProviderConfigurationStatus.unknown;
  }

  bool get isUsable => this == ProviderConfigurationStatus.configured;
}

/// A money amount that knows the difference between "zero" and "not known".
///
/// This distinction is the whole point of the type: rendering an unavailable
/// balance as `$0.00` tells the driver they have no spending room when in fact
/// the app simply has not been told.
class CardMoney {
  const CardMoney._(this.amount, this.currency);

  /// The amount, or null when the backend did not supply one.
  final double? amount;

  final String? currency;

  /// True when there is a real figure to show.
  bool get isAvailable => amount != null;

  /// Parses a backend money field. Accepts num or numeric string; anything
  /// else — including an empty string — is treated as unavailable rather than
  /// coerced to zero.
  factory CardMoney.parse(dynamic raw, {String? currency}) {
    if (raw == null) return CardMoney._(null, currency);
    if (raw is num) return CardMoney._(raw.toDouble(), currency);
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return CardMoney._(null, currency);
      return CardMoney._(double.tryParse(trimmed), currency);
    }
    return CardMoney._(null, currency);
  }

  const CardMoney.unavailable({String? currency}) : this._(null, currency);

  /// Formatted for display, or null when unavailable. Callers must render the
  /// null case as explicit unavailable text — never as a zero amount.
  String? get display {
    final value = amount;
    if (value == null) return null;
    final symbol = _symbolFor(currency);
    return '$symbol${value.toStringAsFixed(2)}';
  }

  /// Subtraction that stays unavailable if either side is unavailable, so a
  /// missing figure never silently becomes a derived zero.
  CardMoney minus(CardMoney other) {
    final a = amount;
    final b = other.amount;
    if (a == null || b == null) return CardMoney.unavailable(currency: currency);
    return CardMoney._(a - b, currency ?? other.currency);
  }

  static String _symbolFor(String? currency) {
    switch (currency?.trim().toUpperCase()) {
      case null:
      case '':
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return '${currency!.trim().toUpperCase()} ';
    }
  }
}

/// The full purchase-card view for one Order Anywhere assignment.
class PurchaseCardState {
  const PurchaseCardState({
    required this.requestId,
    required this.lifecycle,
    required this.providerConfiguration,
    required this.hasCard,
    required this.approvedLimit,
    required this.remaining,
    required this.receiptSubmitted,
    required this.receiptTotal,
    this.rawCardStatus,
    this.statusLabel,
    this.last4,
    this.expiresAt,
    this.merchantName,
    this.orderAnywhereReference,
    this.instructions,
    this.failureCategory,
    this.updatedAt,
    this.revealFlagFromBackend = false,
  });

  final int requestId;
  final CardLifecycleState lifecycle;
  final ProviderConfigurationStatus providerConfiguration;

  /// Whether the backend returned an actual card record. False in every
  /// pre-issuance state, including provider-not-configured.
  final bool hasCard;

  final CardMoney approvedLimit;
  final CardMoney remaining;
  final bool receiptSubmitted;
  final CardMoney receiptTotal;

  final String? rawCardStatus;
  final String? statusLabel;
  final String? last4;
  final DateTime? expiresAt;
  final String? merchantName;
  final String? orderAnywhereReference;
  final String? instructions;
  final String? failureCategory;
  final DateTime? updatedAt;

  /// The backend's own `secure_reveal_available` flag. Never trusted on its
  /// own — see [canReveal].
  final bool revealFlagFromBackend;

  /// Amount consumed so far, derived only when both sides are known.
  CardMoney get amountUsed => approvedLimit.minus(remaining);

  /// The single gate for offering secure reveal.
  ///
  /// Requires all of: an issued card, a usable provider, a lifecycle state in
  /// which a live card legitimately exists, and the backend's explicit flag.
  /// Any one of these being false hides the reveal affordance entirely, which
  /// is what keeps a provider-unconfigured build from requesting a placeholder
  /// reveal session.
  bool get canReveal {
    if (!hasCard) return false;
    if (!providerConfiguration.isUsable) return false;
    if (!revealFlagFromBackend) return false;
    return lifecycle == CardLifecycleState.cardAvailable ||
        lifecycle == CardLifecycleState.secureRevealAvailable ||
        lifecycle == CardLifecycleState.purchaseAuthorized;
  }

  /// Whether the receipt controls should be offered.
  bool get canUploadReceipt => hasCard && lifecycle.allowsReceiptUpload;

  /// Whether the failure-report control should be offered.
  bool get canReportFailure => lifecycle.allowsFailureReport;

  /// The driver must never trigger routine issuance; the backend issues
  /// automatically once eligibility and provider configuration are satisfied.
  /// Exposed so the UI can assert the absence of an issue-card affordance.
  bool get showsManualIssueControl => false;

  /// Builds state from the backend envelope.
  ///
  /// Both shapes are handled: the no-card response carries `card_status`,
  /// `workflow_status` and `provider_configuration_status` at the top level
  /// with a null `data`, while the card response nests them inside `data`.
  factory PurchaseCardState.fromEnvelope(
    Map<String, dynamic> envelope, {
    required int requestId,
  }) {
    final data = envelope['data'];
    final card = data is Map ? Map<String, dynamic>.from(data) : null;

    // Prefer the nested value, fall back to the top level. This is what keeps
    // the provider-pending response — which has no `data` — readable.
    dynamic pick(String key) => card?[key] ?? envelope[key];

    final currency = pick('currency')?.toString();
    final limit = CardMoney.parse(pick('spending_limit'), currency: currency);
    final remaining = CardMoney.parse(
      pick('remaining_balance'),
      currency: currency,
    );

    final provider = ProviderConfigurationStatus.parse(
      pick('provider_configuration_status')?.toString(),
    );

    var lifecycle = CardLifecycleState.parse(
      pick('workflow_status')?.toString(),
    );

    // An unusable provider outranks whatever lifecycle the backend computed:
    // no card can legitimately be live, so the driver is shown the truthful
    // provider-pending state rather than a card-available one.
    if (!provider.isUsable &&
        provider != ProviderConfigurationStatus.unknown &&
        card == null) {
      lifecycle = CardLifecycleState.awaitingProviderConfiguration;
    }

    return PurchaseCardState(
      requestId: requestId,
      lifecycle: lifecycle,
      providerConfiguration: provider,
      hasCard: card != null,
      approvedLimit: limit,
      remaining: remaining,
      receiptSubmitted: pick('receipt_submitted') == true,
      receiptTotal: CardMoney.parse(pick('receipt_total'), currency: currency),
      rawCardStatus: pick('card_status')?.toString(),
      statusLabel: pick('card_status_label')?.toString(),
      last4: _nonEmpty(pick('last4')?.toString()),
      expiresAt: _parseDate(pick('expires_at')),
      merchantName:
          _nonEmpty(pick('merchant_name')?.toString()) ??
          _nonEmpty(pick('allowed_merchant')?.toString()),
      orderAnywhereReference: _nonEmpty(
        pick('order_anywhere_reference')?.toString(),
      ),
      instructions: _nonEmpty(pick('instructions')?.toString()),
      failureCategory: _nonEmpty(pick('failure_category')?.toString()),
      updatedAt: _parseDate(pick('updated_at')),
      revealFlagFromBackend: pick('secure_reveal_available') == true,
    );
  }

  static String? _nonEmpty(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') return null;
    return trimmed;
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }
}

/// A short-lived provider-hosted reveal session.
///
/// Holds a URL and an expiry only. PAN, CVC and expiry digits are rendered by
/// the provider inside the hosted page and never cross into Dart.
class CardRevealSession {
  const CardRevealSession({required this.revealUrl, required this.expiresAt});

  final String revealUrl;
  final DateTime? expiresAt;

  bool get isExpired {
    final expiry = expiresAt;
    if (expiry == null) return false;
    return DateTime.now().isAfter(expiry);
  }

  /// Returns null when the backend did not supply a usable URL, so the caller
  /// surfaces a failure instead of opening a blank secure view.
  static CardRevealSession? fromJson(Map<String, dynamic> json) {
    final url = json['reveal_url']?.toString().trim();
    if (url == null || url.isEmpty) return null;
    if (!url.startsWith('https://')) return null;
    return CardRevealSession(
      revealUrl: url,
      expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? ''),
    );
  }

  /// Never include the URL — it is a bearer credential for the hosted page.
  @override
  String toString() => 'CardRevealSession(expiresAt: $expiresAt)';
}

/// Driver-reportable failure categories.
///
/// The backend validates against a fixed six-value enum. The richer driver
/// wording is carried in the free-text detail field so the driver sees the
/// specific problem they hit while the request still validates server-side.
enum CardFailureCategory {
  cardUnavailable('other', 'Card unavailable'),
  revealFailed('reveal_failed', 'Secure reveal failed'),
  purchaseDeclined('declined', 'Purchase declined'),
  merchantRestriction('merchant_restricted', 'Merchant restriction issue'),
  incorrectLimit('other', 'Incorrect approved limit'),
  receiptUploadFailure('other', 'Receipt upload failure'),
  transactionMismatch('other', 'Transaction mismatch'),
  cardAlreadyUsed('other', 'Card already used'),
  cardExpired('expired', 'Card expired'),
  cardDamaged('damaged', 'Card unusable or damaged'),
  supportRequired('other', 'Support required');

  const CardFailureCategory(this.wireValue, this.label);

  /// One of: declined, reveal_failed, merchant_restricted, expired, damaged,
  /// other — the only values the backend accepts.
  final String wireValue;

  final String label;

  /// Detail text prefixed with the specific category so that categories which
  /// collapse onto `other` remain distinguishable to support.
  String detailFor(String? driverNotes) {
    final notes = driverNotes?.trim();
    if (notes == null || notes.isEmpty) return label;
    return '$label: $notes';
  }
}
