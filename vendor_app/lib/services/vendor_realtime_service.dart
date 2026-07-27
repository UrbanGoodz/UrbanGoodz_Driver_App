import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:urban_goodz_vendor/services/vendor_api_client.dart';

class VendorRealtimeContract {
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
      '${VendorApiClient.baseUrl}/realtime/vendor/broadcasting/auth';

  static String ordersChannel(int vendorId) =>
      'private-ug.vendor.$vendorId.orders';

  static String paymentChannel(int vendorId) =>
      'private-ug.payment.vendor.$vendorId.statuses';

  static Map<String, String> authorizationHeaders(String token) => {
    'Accept': 'application/json',
    'Authorization': 'Bearer ${token.trim()}',
    'vendorType': 'owner',
  };

  static PusherChannelsOptions options() {
    if (!isConfigured) {
      throw StateError('Vendor realtime is not configured.');
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

class VendorRealtimeService {
  PusherChannelsClient? _client;
  final List<PrivateChannel> _channels = [];
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  bool get isConfigured => VendorRealtimeContract.isConfigured;

  Future<bool> connect({
    required int vendorId,
    required String bearerToken,
    required void Function(Map<String, dynamic> payload) onOrderUpdated,
    required void Function(Map<String, dynamic> payload) onPaymentUpdated,
  }) async {
    await disconnect();
    if (!isConfigured || vendorId <= 0 || bearerToken.trim().isEmpty) {
      return false;
    }

    final client = PusherChannelsClient.websocket(
      options: VendorRealtimeContract.options(),
      connectionErrorHandler: (exception, trace, refresh) async {
        log(
          'Vendor realtime connection failed: ${exception.runtimeType}',
          name: 'UrbanGoodzRealtime',
        );
        refresh();
      },
    );
    _client = client;

    final authorization =
        EndpointAuthorizableChannelTokenAuthorizationDelegate.forPrivateChannel(
          authorizationEndpoint: Uri.parse(
            VendorRealtimeContract.authorizationEndpoint,
          ),
          headers: VendorRealtimeContract.authorizationHeaders(bearerToken),
        );

    final orders = client.privateChannel(
      VendorRealtimeContract.ordersChannel(vendorId),
      authorizationDelegate: authorization,
    );
    final payments = client.privateChannel(
      VendorRealtimeContract.paymentChannel(vendorId),
      authorizationDelegate: authorization,
    );
    _channels.addAll([orders, payments]);

    _subscriptions.add(
      orders.bind('vendor.order.updated').listen((event) {
        final payload = _decodePayload(event.data);
        if (payload != null) onOrderUpdated(payload);
      }),
    );
    _subscriptions.add(
      payments.bind('payment.status.updated').listen((event) {
        final payload = _decodePayload(event.data);
        if (payload != null) onPaymentUpdated(payload);
      }),
    );
    _subscriptions.add(
      client.onConnectionEstablished.listen((_) {
        for (final channel in _channels) {
          channel.subscribeIfNotUnsubscribed();
        }
      }),
    );

    await client.connect();
    orders.subscribeIfNotUnsubscribed();
    payments.subscribeIfNotUnsubscribed();
    return true;
  }

  Future<void> disconnect() async {
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
}
