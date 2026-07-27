import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:urban_goodz_driver/config/api_config.dart';

class DriverRealtimeContract {
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
      '${ApiConfig.baseUrl}/api/v1/realtime/driver/broadcasting/auth';

  static String assignmentsChannel(int driverId) =>
      'private-ug.driver.$driverId.assignments';

  static String paymentChannel(int driverId) =>
      'private-ug.payment.driver.$driverId.statuses';

  static Map<String, String> authorizationHeaders(String token) => {
    'Accept': 'application/json',
    'Authorization': 'Bearer ${token.trim()}',
  };

  static PusherChannelsOptions options() {
    if (!isConfigured) {
      throw StateError('Driver realtime is not configured.');
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

class DriverRealtimeService {
  PusherChannelsClient? _client;
  final List<PrivateChannel> _channels = [];
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  bool get isConfigured => DriverRealtimeContract.isConfigured;

  Future<bool> connect({
    required int driverId,
    required String bearerToken,
    required void Function(Map<String, dynamic> payload) onAssignmentUpdated,
    required void Function(Map<String, dynamic> payload) onPaymentUpdated,
  }) async {
    await disconnect();
    if (!isConfigured || driverId <= 0 || bearerToken.trim().isEmpty) {
      return false;
    }

    final client = PusherChannelsClient.websocket(
      options: DriverRealtimeContract.options(),
      connectionErrorHandler: (exception, trace, refresh) async {
        log(
          'Driver realtime connection failed: ${exception.runtimeType}',
          name: 'UrbanGoodzRealtime',
        );
        refresh();
      },
    );
    _client = client;

    final authorization =
        EndpointAuthorizableChannelTokenAuthorizationDelegate.forPrivateChannel(
          authorizationEndpoint: Uri.parse(
            DriverRealtimeContract.authorizationEndpoint,
          ),
          headers: DriverRealtimeContract.authorizationHeaders(bearerToken),
        );

    final assignments = client.privateChannel(
      DriverRealtimeContract.assignmentsChannel(driverId),
      authorizationDelegate: authorization,
    );
    final payments = client.privateChannel(
      DriverRealtimeContract.paymentChannel(driverId),
      authorizationDelegate: authorization,
    );
    _channels.addAll([assignments, payments]);

    _subscriptions.add(
      assignments.bind('driver.assignment.updated').listen((event) {
        final payload = _decodePayload(event.data);
        if (payload != null) onAssignmentUpdated(payload);
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
    assignments.subscribeIfNotUnsubscribed();
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
