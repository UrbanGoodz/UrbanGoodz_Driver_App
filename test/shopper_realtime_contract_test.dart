import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/features/order/screens/order_tracking_screen.dart';
import 'package:sixam_mart/helper/pusher_helper.dart';

void main() {
  test('shopper realtime uses only role-scoped private channels', () {
    expect(OrderTrackingScreen, isNotNull);
    expect(
      ShopperRealtimeContract.authorizationEndpoint,
      'https://admin.urbangoodzdelivery.com/api/v1/realtime/shopper/broadcasting/auth',
    );
    expect(
      ShopperRealtimeContract.ordersChannel(41),
      'private-ug.shopper.41.orders',
    );
    expect(
      ShopperRealtimeContract.paymentChannel(41),
      'private-ug.payment.shopper.41.statuses',
    );
  });

  test('shopper realtime fails closed without build configuration', () {
    expect(ShopperRealtimeContract.isConfigured, isFalse);
  });

  test(
    'shopper source has no public driver location or local socket default',
    () {
      final source = File('lib/helper/pusher_helper.dart').readAsStringSync();

      expect(source, isNot(contains('publicChannel(')));
      expect(source, isNot(contains('dm_location')));
      expect(source, isNot(contains('192.168.')));
      expect(source, isNot(contains("key: '6ammart'")));
      expect(source, contains("scheme: 'wss'"));
    },
  );
}
