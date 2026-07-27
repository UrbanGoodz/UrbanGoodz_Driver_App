import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:urban_goodz_driver/main.dart' as driver_app;
import 'package:urban_goodz_driver/services/driver_realtime_service.dart';

void main() {
  test('driver realtime uses the driver auth and assignment channels', () {
    expect(driver_app.MyApp, isNotNull);
    expect(
      DriverRealtimeContract.authorizationEndpoint,
      'https://admin.urbangoodzdelivery.com/api/v1/realtime/driver/broadcasting/auth',
    );
    expect(
      DriverRealtimeContract.assignmentsChannel(61),
      'private-ug.driver.61.assignments',
    );
    expect(
      DriverRealtimeContract.paymentChannel(61),
      'private-ug.payment.driver.61.statuses',
    );
  });

  test(
    'driver authorization uses bearer token without browser CORS headers',
    () {
      final headers = DriverRealtimeContract.authorizationHeaders('test-token');

      expect(headers['Authorization'], 'Bearer test-token');
      expect(headers.keys, isNot(contains('Access-Control-Allow-Origin')));
    },
  );

  test('driver realtime fails closed and contains no unsafe defaults', () {
    expect(DriverRealtimeContract.isConfigured, isFalse);

    final source = File(
      'lib/services/driver_realtime_service.dart',
    ).readAsStringSync();
    expect(source, isNot(contains('publicChannel(')));
    expect(source, isNot(contains('dm_location')));
    expect(source, isNot(contains('localhost')));
    expect(source, isNot(contains('127.0.0.1')));
    expect(source, isNot(contains('PUSHER_APP_SECRET')));
    expect(source, contains("scheme: 'wss'"));
  });
}
