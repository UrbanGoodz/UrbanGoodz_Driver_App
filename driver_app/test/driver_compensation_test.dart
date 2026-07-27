import 'package:flutter_test/flutter_test.dart';
import 'package:urban_goodz_driver/models/driver_compensation.dart';

/// These tests pin the two behaviours that matter while the backend
/// compensation engine is undeployed:
///
///   * an absent figure must read as "unavailable", never as $0.00
///   * the app must never state a total the backend did not state
void main() {
  group('unavailable rather than fabricated', () {
    test('null payload yields no compensation object', () {
      expect(DriverCompensation.tryParse(null), isNull);
    });

    test('empty payload yields no compensation object', () {
      expect(DriverCompensation.tryParse(<String, dynamic>{}), isNull);
    });

    test('status-only payload carrying no money is not displayable', () {
      final parsed = DriverCompensation.tryParse({
        'compensation_status': 'estimate',
        'payout_status': 'pending',
      });
      expect(
        parsed,
        isNull,
        reason: 'a block with no amounts must fall back to unavailable',
      );
    });

    test('the unavailable message is the exact required wording', () {
      expect(
        DriverCompensation.unavailableMessage,
        'Compensation details unavailable',
      );
    });

    test('omitted components are absent from the breakdown, not zeroed', () {
      final parsed = DriverCompensation.tryParse({
        'base_pay_cents': 2500,
        'compensation_status': 'estimate',
      })!;

      expect(parsed.lines.map((l) => l.label), ['Base pay']);
      expect(parsed.mileageCents, isNull);
      expect(parsed.detentionCents, isNull);
      expect(
        parsed.lines.any((l) => l.formatted == '\$0.00'),
        isFalse,
        reason: 'a field the backend never sent must not render as \$0.00',
      );
    });

    test('an explicit zero from the backend is shown, unlike an omission', () {
      final parsed = DriverCompensation.tryParse({'detention_cents': 0})!;
      expect(parsed.detentionCents, 0);
      expect(parsed.lines.single.formatted, '\$0.00');
    });
  });

  group('the app never computes the total itself', () {
    test('components without a stated total produce no total', () {
      final parsed = DriverCompensation.tryParse({
        'base_pay_cents': 2500,
        'mileage_cents': 1200,
        'bonuses_cents': 500,
      })!;

      expect(
        parsed.formattedTotal,
        isNull,
        reason: 'summing the components would claim a figure the backend '
            'did not state',
      );
    });

    test('a backend total that disagrees with its components still wins', () {
      final parsed = DriverCompensation.tryParse({
        'base_pay_cents': 2500,
        'mileage_cents': 1200,
        'final_amount_cents': 9999,
      })!;

      expect(parsed.totalCents, 9999);
      expect(parsed.formattedTotal, '\$99.99');
    });

    test('final_amount takes precedence over the estimate', () {
      final parsed = DriverCompensation.tryParse({
        'estimated_driver_amount_cents': 4000,
        'final_amount_cents': 4250,
      })!;
      expect(parsed.totalCents, 4250);
    });

    test('estimate is used when no final amount exists', () {
      final parsed = DriverCompensation.tryParse({
        'estimated_driver_amount_cents': 4000,
      })!;
      expect(parsed.totalCents, 4000);
    });
  });

  group('integer cents only', () {
    test('a fractional double is rejected rather than truncated', () {
      final parsed = DriverCompensation.tryParse({'base_pay_cents': 12.34});
      expect(
        parsed,
        isNull,
        reason: 'coercing 12.34 to 12 cents would understate pay by 100x',
      );
    });

    test('a formatted currency string is rejected', () {
      final parsed = DriverCompensation.tryParse({'base_pay_cents': '\$25.00'});
      expect(parsed, isNull);
    });

    test('an integral double is accepted', () {
      final parsed = DriverCompensation.tryParse({'base_pay_cents': 2500.0})!;
      expect(parsed.basePayCents, 2500);
    });
  });

  group('formatting', () {
    test('cents pad to two digits', () {
      expect(DriverCompensation.formatCents(2505), '\$25.05');
      expect(DriverCompensation.formatCents(2550), '\$25.50');
      expect(DriverCompensation.formatCents(5), '\$0.05');
      expect(DriverCompensation.formatCents(0), '\$0.00');
    });

    test('negative adjustments keep their sign', () {
      expect(DriverCompensation.formatCents(-1250), '-\$12.50');
    });
  });

  group('stage and payout status', () {
    test('estimate is labelled as an estimate, never as settled pay', () {
      final parsed = DriverCompensation.tryParse({
        'total_cents': 5000,
        'compensation_status': 'estimate',
      })!;
      expect(parsed.stage, CompensationStage.estimate);
      expect(parsed.totalLabel, 'Estimated total');
    });

    test('settled is labelled final', () {
      final parsed = DriverCompensation.tryParse({
        'total_cents': 5000,
        'compensation_status': 'final',
      })!;
      expect(parsed.stage, CompensationStage.settled);
      expect(parsed.totalLabel, 'Final total');
    });

    test('an unrecognised stage is unknown, not final', () {
      final parsed = DriverCompensation.tryParse({
        'total_cents': 5000,
        'compensation_status': 'something_new',
      })!;
      expect(parsed.stage, CompensationStage.unknown);
      expect(parsed.totalLabel, 'Total');
    });

    test('a missing payout status says so rather than implying pending', () {
      final parsed = DriverCompensation.tryParse({'total_cents': 5000})!;
      expect(parsed.payoutStatus, PayoutStatus.unknown);
      expect(parsed.payoutLabel, 'Payout status unavailable');
    });

    test('payout statuses map to driver-readable labels', () {
      String labelFor(String raw) => DriverCompensation.tryParse({
        'total_cents': 1,
        'payout_status': raw,
      })!.payoutLabel;

      expect(labelFor('pending'), 'Payout pending');
      expect(labelFor('processing'), 'Payout processing');
      expect(labelFor('paid'), 'Paid');
      expect(labelFor('failed'), 'Payout failed');
    });
  });

  test('a nested compensation sub-object is read', () {
    final parsed = DriverCompensation.tryParse({
      'id': 42,
      'compensation': {
        'base_pay_cents': 2500,
        'deadhead_cents': 800,
        'final_amount_cents': 3300,
        'compensation_status': 'final',
        'payout_status': 'paid',
      },
    })!;

    expect(parsed.basePayCents, 2500);
    expect(parsed.deadheadCents, 800);
    expect(parsed.formattedTotal, '\$33.00');
    expect(parsed.totalLabel, 'Final total');
    expect(parsed.payoutLabel, 'Paid');
  });

  test('every required contract field is parsed', () {
    final parsed = DriverCompensation.tryParse({
      'base_pay_cents': 1000,
      'mileage_cents': 2000,
      'deadhead_cents': 300,
      'stops_cents': 400,
      'packages_cents': 500,
      'bonuses_cents': 600,
      'detention_cents': 700,
      'pass_through_cents': 800,
      'adjustments_cents': -900,
      'estimated_driver_amount_cents': 5400,
      'compensation_status': 'estimate',
      'payout_status': 'pending',
    })!;

    expect(parsed.lines.map((l) => l.label), [
      'Base pay',
      'Mileage',
      'Deadhead',
      'Stops',
      'Packages',
      'Bonuses',
      'Detention',
      'Reimbursements',
      'Adjustments',
    ]);
    expect(parsed.adjustmentsCents, -900);
    expect(parsed.formattedTotal, '\$54.00');
  });
}
