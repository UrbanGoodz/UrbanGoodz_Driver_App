import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:urban_goodz_vendor/main.dart' as vendor_app;
import 'package:urban_goodz_vendor/services/vendor_realtime_service.dart';

void main() {
  test('vendor realtime uses the vendor auth and account channels', () {
    expect(vendor_app.MyApp, isNotNull);
    expect(
      VendorRealtimeContract.authorizationEndpoint,
      'https://admin.urbangoodzdelivery.com/api/v1/realtime/vendor/broadcasting/auth',
    );
    expect(
      VendorRealtimeContract.ordersChannel(51),
      'private-ug.vendor.51.orders',
    );
    expect(
      VendorRealtimeContract.paymentChannel(51),
      'private-ug.payment.vendor.51.statuses',
    );
  });

  test('vendor authorization carries its existing role token contract', () {
    final headers = VendorRealtimeContract.authorizationHeaders('test-token');

    expect(headers['Authorization'], 'Bearer test-token');
    expect(headers['vendorType'], 'owner');
    expect(headers.keys, isNot(contains('Access-Control-Allow-Origin')));
  });

  test('vendor realtime fails closed and contains no unsafe defaults', () {
    expect(VendorRealtimeContract.isConfigured, isFalse);

    final source = File(
      'lib/services/vendor_realtime_service.dart',
    ).readAsStringSync();
    expect(source, isNot(contains('publicChannel(')));
    expect(source, isNot(contains('localhost')));
    expect(source, isNot(contains('127.0.0.1')));
    expect(source, isNot(contains('PUSHER_APP_SECRET')));
    expect(source, contains("scheme: 'wss'"));
  });
}
