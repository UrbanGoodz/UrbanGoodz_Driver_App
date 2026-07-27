import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/util/app_constants.dart';

/// Compile-time public connection metadata. No Pusher secret belongs in a
/// Shopper build. Production supplies these values with `--dart-define`.
class ShopperRealtimeContract {
  static const String appKey = String.fromEnvironment('UG_PUSHER_APP_KEY');
  static const String cluster = String.fromEnvironment('UG_PUSHER_APP_CLUSTER');
  static const String host = String.fromEnvironment('UG_PUSHER_HOST');
  static const int port = int.fromEnvironment(
    'UG_PUSHER_PORT',
    defaultValue: 443,
  );

  static bool get isConfigured =>
      appKey.trim().isNotEmpty && cluster.trim().isNotEmpty;

  static String get authorizationEndpoint =>
      '${AppConstants.baseUrl}/api/v1/realtime/shopper/broadcasting/auth';

  static String ordersChannel(int customerId) =>
      'private-ug.shopper.$customerId.orders';

  static String paymentChannel(int customerId) =>
      'private-ug.payment.shopper.$customerId.statuses';

  static PusherChannelsOptions options() {
    if (!isConfigured) {
      throw StateError('Shopper realtime is not configured.');
    }

    if (host.trim().isNotEmpty) {
      return PusherChannelsOptions.fromHost(
        scheme: 'wss',
        host: host.trim(),
        key: appKey.trim(),
        port: port,
        shouldSupplyMetadataQueries: true,
        metadata: PusherChannelsOptionsMetadata.byDefault(),
      );
    }

    return PusherChannelsOptions.fromCluster(
      scheme: 'wss',
      cluster: cluster.trim(),
      key: appKey.trim(),
      host: 'pusher.com',
      port: port,
      shouldSupplyMetadataQueries: true,
      metadata: PusherChannelsOptionsMetadata.byDefault(),
    );
  }
}

class PusherHelper {
  static PusherChannelsClient? _client;
  static final List<PrivateChannel> _channels = [];
  static final List<StreamSubscription<dynamic>> _subscriptions = [];

  static Future<bool> initializePusher() async {
    if (!ShopperRealtimeContract.isConfigured) return false;
    if (_client != null) return true;

    final client = PusherChannelsClient.websocket(
      options: ShopperRealtimeContract.options(),
      connectionErrorHandler: (exception, trace, refresh) async {
        log(
          'Shopper realtime connection failed: ${exception.runtimeType}',
          name: 'UrbanGoodzRealtime',
        );
        refresh();
      },
    );
    _client = client;

    _subscriptions.add(
      client.onConnectionEstablished.listen((_) {
        _setConnectionStatus('Connected');
        for (final channel in _channels) {
          channel.subscribeIfNotUnsubscribed();
        }
      }),
    );
    _subscriptions.add(
      client.lifecycleStream.listen((event) {
        if (!event.toString().toLowerCase().contains('established')) {
          _setConnectionStatus('Disconnected');
        }
      }),
    );

    await client.connect();
    return true;
  }

  static Future<bool> subscribeShopperAccount({
    required int customerId,
    required String bearerToken,
    required void Function(Map<String, dynamic> payload) onOrderUpdated,
    void Function(Map<String, dynamic> payload)? onPaymentUpdated,
  }) async {
    if (customerId <= 0 || bearerToken.trim().isEmpty) return false;
    if (!await initializePusher()) return false;

    final authorization =
        EndpointAuthorizableChannelTokenAuthorizationDelegate.forPrivateChannel(
          authorizationEndpoint: Uri.parse(
            ShopperRealtimeContract.authorizationEndpoint,
          ),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer ${bearerToken.trim()}',
          },
        );

    final orders = _client!.privateChannel(
      ShopperRealtimeContract.ordersChannel(customerId),
      authorizationDelegate: authorization,
    );
    _channels.add(orders);
    _subscriptions.add(
      orders.bind('order.status.updated').listen((event) {
        final payload = _decodePayload(event.data);
        if (payload != null) onOrderUpdated(payload);
      }),
    );
    _subscriptions.add(
      orders.bind('pusher:subscription_error').listen((_) {
        log(
          'Shopper order-channel authorization failed.',
          name: 'UrbanGoodzRealtime',
        );
      }),
    );

    final payments = _client!.privateChannel(
      ShopperRealtimeContract.paymentChannel(customerId),
      authorizationDelegate: authorization,
    );
    _channels.add(payments);
    if (onPaymentUpdated != null) {
      _subscriptions.add(
        payments.bind('payment.status.updated').listen((event) {
          final payload = _decodePayload(event.data);
          if (payload != null) onPaymentUpdated(payload);
        }),
      );
    }

    orders.subscribeIfNotUnsubscribed();
    payments.subscribeIfNotUnsubscribed();
    return true;
  }

  static Future<void> disconnect() async {
    for (final channel in _channels) {
      channel.unsubscribe();
    }
    _channels.clear();

    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();

    await _client?.disconnect();
    _client = null;
    _setConnectionStatus(null);
  }

  static Map<String, dynamic>? _decodePayload(String? data) {
    if (data == null || data.isEmpty) return null;
    try {
      final decoded = jsonDecode(data);
      return decoded is Map
          ? decoded.map((key, value) => MapEntry(key.toString(), value))
          : null;
    } catch (_) {
      return null;
    }
  }

  static void _setConnectionStatus(String? status) {
    try {
      Get.find<SplashController>().setPusherStatus(status);
    } catch (_) {
      // Splash dependencies are not available in isolated contract tests.
    }
  }
}
