import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:urban_goodz_vendor/controllers/dashboard_controller.dart';
import 'package:urban_goodz_vendor/controllers/vendor_auth_controller.dart';
import 'package:urban_goodz_vendor/repositories/vendor_repository.dart';
import 'package:urban_goodz_vendor/screens/dashboard_screen.dart';
import 'package:urban_goodz_vendor/services/vendor_api_client.dart';
import 'package:urban_goodz_vendor/theme/app_theme.dart';

/// The revenue chart divided by its own maximum. `revenueChart` starts as
/// seven zeros and no endpoint populates it, so every vendor reaching the
/// dashboard computed `0 / 0` -> NaN. `clamp` does not preserve NaN; it
/// returns the upper bound, so all seven bars were drawn at the full 120px,
/// which never fitted the 140px row alongside two 9pt labels. A successful
/// login therefore landed on a dashboard overflowing by 14px on every bar.
///
/// Nothing here fabricates revenue: the zero series is asserted to render an
/// explicit empty state, and only the tests that check scaling supply values.
void main() {
  group('barFractions never produces an unusable height', () {
    test('an all-zero series yields zero-height bars, not NaN', () {
      final fractions = DashboardController.barFractions(
        List<double>.filled(7, 0),
      );

      expect(fractions, hasLength(7));
      expect(fractions, everyElement(0.0));
      expect(fractions.every((f) => f.isFinite), isTrue);
      // The regression itself, pinned so the reasoning cannot rot: dividing by
      // a zero maximum gives NaN, and clamp does not preserve NaN - it returns
      // the UPPER bound. The old code therefore drew every bar at full height
      // for a vendor with no revenue, rather than drawing nothing.
      expect((0 / 0).isNaN, isTrue);
      expect((0 / 0).clamp(0.0, 1.0), 1.0);
    });

    test('an empty series yields no bars and does not throw', () {
      expect(DashboardController.barFractions(const []), isEmpty);
    });

    test('positive revenue scales against the tallest day', () {
      final fractions = DashboardController.barFractions(
        [0, 500, 1000, 250, 0, 0, 0],
      );

      expect(fractions, [0.0, 0.5, 1.0, 0.25, 0.0, 0.0, 0.0]);
    });

    test('a single non-zero day fills the row without exceeding it', () {
      final fractions = DashboardController.barFractions([0, 0, 0, 42, 0, 0, 0]);

      expect(fractions[3], 1.0);
      expect(fractions.where((f) => f > 0), hasLength(1));
    });

    test('every fraction stays finite and within 0..1', () {
      // double.tryParse accepts 'NaN' and 'Infinity', so the API can deliver
      // both through DashboardController._double.
      final series = <double>[
        double.nan,
        double.infinity,
        double.negativeInfinity,
        -500,
        0,
        750,
        1500,
      ];

      final fractions = DashboardController.barFractions(series);

      expect(fractions, hasLength(series.length));
      for (final fraction in fractions) {
        expect(fraction.isFinite, isTrue, reason: '$fraction is not finite');
        expect(fraction, inInclusiveRange(0.0, 1.0));
      }
      // Infinity is not plottable, so 1500 is the tallest real value.
      expect(fractions[6], 1.0);
      expect(fractions[5], closeTo(0.5, 0.001));
      expect(fractions[0], 0.0);
      expect(fractions[1], 0.0);
      expect(fractions[2], 0.0);
      expect(fractions[3], 0.0);
    });
  });

  group('the dashboard chart renders for every revenue state', () {
    Future<DashboardController> pumpDashboard(WidgetTester tester) async {
      Get.testMode = true;
      SharedPreferences.setMockInitialValues({});
      final api = VendorApiClient(client: _OfflineClient());
      final repository = _FakeRepository(api);
      Get.put<VendorApiClient>(api);
      Get.put<VendorRepository>(repository);
      Get.put<VendorAuthController>(VendorAuthController(repository, api));

      await tester.pumpWidget(
        GetMaterialApp(theme: AppTheme.lightTheme, home: DashboardScreen()),
      );
      await tester.pumpAndSettle();
      return Get.find<DashboardController>();
    }

    tearDown(Get.reset);

    testWidgets('the default all-zero series renders an empty state and no '
        'layout exception', (tester) async {
      final controller = await pumpDashboard(tester);

      expect(controller.revenueChart, everyElement(0.0));
      expect(controller.hasNoRevenue, isTrue);
      expect(find.byKey(const Key('revenue_chart_empty')), findsOneWidget);
      expect(find.byKey(const Key('revenue_bar_0')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an empty series renders the empty state', (tester) async {
      final controller = await pumpDashboard(tester);

      controller.revenueChart.clear();
      await tester.pumpAndSettle();

      expect(controller.hasNoRevenue, isTrue);
      expect(find.byKey(const Key('revenue_chart_empty')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('positive revenue draws bars inside the fixed row',
        (tester) async {
      final controller = await pumpDashboard(tester);

      controller.revenueChart.assignAll([0, 500, 1000, 250, 0, 0, 0]);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('revenue_chart_empty')), findsNothing);
      // The chart's row is a fixed 140px; an overflow here is the defect.
      expect(tester.takeException(), isNull);

      // The row the bars live in, measured rather than assumed: bar pixels are
      // a fraction of whatever Expanded leaves after the two labels.
      final rowHeight = tester
          .getSize(find.byType(FractionallySizedBox).first)
          .height;
      double barHeight(int i) =>
          tester.getSize(find.byKey(Key('revenue_bar_$i'))).height;

      for (var i = 0; i < 7; i++) {
        expect(
          find.byKey(Key('revenue_bar_$i')),
          findsOneWidget,
          reason: 'bar $i is missing',
        );
        expect(barHeight(i).isFinite, isTrue);
        expect(barHeight(i), inInclusiveRange(0.0, rowHeight));
      }
      // 1000 is the tallest day, 500 is half of it, 0 draws nothing.
      expect(barHeight(2), closeTo(rowHeight, 0.001));
      expect(barHeight(1), closeTo(rowHeight / 2, 0.5));
      expect(barHeight(3), closeTo(rowHeight / 4, 0.5));
      expect(barHeight(0), 0.0);
    });

    testWidgets('a series shorter than a week still labels its bars',
        (tester) async {
      final controller = await pumpDashboard(tester);

      controller.revenueChart.assignAll([100, 200, 300]);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('revenue_bar_2')), findsOneWidget);
      expect(find.byKey(const Key('revenue_bar_3')), findsNothing);
      expect(find.text('Wed'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

/// Answers every request from memory: under TestWidgetsFlutterBinding a real
/// HttpClient returns 400 to everything, so the dashboard must not use one.
class _OfflineClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async =>
      http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode({}))),
        200,
        request: request,
      );
}

/// Serves the dashboard's initial fetch with an empty, well-formed payload -
/// the state a brand-new vendor sees.
class _FakeRepository extends VendorRepository {
  _FakeRepository(super.api);

  @override
  Future<Map<String, dynamic>> profile() async => {
    'stores': <String, dynamic>{'name': 'Test Store', 'active': 1},
  };

  @override
  Future<List<Map<String, dynamic>>> currentOrders() async => [];

  @override
  Future<Map<String, dynamic>> items({
    int limit = 100,
    int offset = 1,
    String? search,
  }) async => {'items': <Map<String, dynamic>>[]};

  @override
  Future<List<Map<String, dynamic>>> notifications() async => [];

  @override
  Future<List<Map<String, dynamic>>> fashionRequests({String? status}) async =>
      [];
}
