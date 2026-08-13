import 'package:get/get.dart';
import 'package:urban_goodz_driver/config/api_config.dart';
import 'package:urban_goodz_driver/models/marketplace_order.dart';
import 'package:urban_goodz_driver/services/api_client.dart';

/// Marketplace order lifecycle for the driver.
///
/// The backend enforces the rules; this class only speaks the contract:
///   - only the assigned driver may change an order's status
///   - `confirmed` is rejected when the platform runs the store confirmation
///     model, which surfaces as the `order-confirmation-model` error code
///   - `delivered` requires the customer OTP when delivery verification is on
class MarketplaceOrderService {
  final ApiClient _client;

  MarketplaceOrderService({ApiClient? client})
    : _client = client ?? Get.find<ApiClient>();

  /// Orders currently in the driver's hands.
  Future<List<MarketplaceOrder>> currentOrders({
    int limit = 25,
    int offset = 1,
  }) async {
    final res = await _client.authGet(
      ApiConfig.marketplaceCurrentOrders,
      query: {'limit': '$limit', 'offset': '$offset'},
    );

    if (res.statusCode != 200) {
      throw MarketplaceOrderException.fromResponse(res);
    }

    final body = res.body;
    final orders = body is Map ? (body['orders'] as List? ?? []) : (body as List? ?? []);

    return orders
        .whereType<Map<String, dynamic>>()
        .map(MarketplaceOrder.fromJson)
        .toList();
  }

  /// Newly assigned orders the driver has not acted on yet.
  Future<List<MarketplaceOrder>> latestOrders() async {
    final res = await _client.authGet(ApiConfig.marketplaceLatestOrders);

    if (res.statusCode != 200) {
      throw MarketplaceOrderException.fromResponse(res);
    }

    final list = res.body as List? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(MarketplaceOrder.fromJson)
        .toList();
  }

  Future<MarketplaceOrder> order(int orderId) async {
    final res = await _client.authGet(
      ApiConfig.marketplaceOrder,
      query: {'order_id': '$orderId'},
    );

    if (res.statusCode != 200) {
      throw MarketplaceOrderException.fromResponse(res);
    }

    return MarketplaceOrder.fromJson(
      Map<String, dynamic>.from(res.body as Map),
    );
  }

  /// Claim an unassigned order. Orders assigned by an admin are already the
  /// driver's and will be refused here — that is expected, not an error state.
  Future<void> acceptOrder(int orderId, {double? lat, double? lng}) async {
    final res = await _client.authPut(ApiConfig.marketplaceAcceptOrder, {
      'order_id': '$orderId',
      if (lat != null) 'lat': '$lat',
      if (lng != null) 'lng': '$lng',
    });

    if (res.statusCode != 200) {
      throw MarketplaceOrderException.fromResponse(res);
    }
  }

  /// Move the order along. [otp] is required for `delivered` when the platform
  /// has delivery verification enabled.
  Future<void> updateStatus(
    int orderId,
    String status, {
    String? otp,
    String? reason,
  }) async {
    assert(
      MarketplaceOrder.driverStatuses.contains(status),
      'status must be one of ${MarketplaceOrder.driverStatuses}',
    );

    final res = await _client.authPut(ApiConfig.marketplaceUpdateOrderStatus, {
      'order_id': '$orderId',
      'status': status,
      if (otp != null && otp.isNotEmpty) 'otp': otp,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });

    if (res.statusCode != 200) {
      throw MarketplaceOrderException.fromResponse(res);
    }
  }

  /// Ask the backend to send the delivery OTP to the customer.
  Future<void> sendDeliveryOtp(int orderId) async {
    final res = await _client.authPut(ApiConfig.marketplaceSendOrderOtp, {
      'order_id': '$orderId',
    });

    if (res.statusCode != 200) {
      throw MarketplaceOrderException.fromResponse(res);
    }
  }
}

/// A typed error carrying the backend's own code so the UI can react to the
/// cases that are not failures — an order confirmation model mismatch, or an
/// OTP the customer read out wrongly.
class MarketplaceOrderException implements Exception {
  final int statusCode;
  final String code;
  final String message;

  const MarketplaceOrderException(this.statusCode, this.code, this.message);

  factory MarketplaceOrderException.fromResponse(Response res) {
    final body = res.body;
    String code = 'error';
    String message = res.statusText ?? 'Request failed';

    if (body is Map && body['errors'] is List && (body['errors'] as List).isNotEmpty) {
      final first = (body['errors'] as List).first;
      if (first is Map) {
        code = (first['code'] ?? code).toString();
        message = (first['message'] ?? message).toString();
      }
    } else if (body is Map && body['message'] != null) {
      message = body['message'].toString();
    }

    return MarketplaceOrderException(res.statusCode ?? 0, code, message);
  }

  /// The platform is configured so the store confirms orders, not the driver.
  bool get isConfirmationModelMismatch => code == 'order-confirmation-model';

  bool get isOtpMismatch => code == 'otp';

  /// The order is not this driver's to change.
  bool get isNotAssigned => code == 'not_found';

  @override
  String toString() => 'MarketplaceOrderException($statusCode/$code): $message';
}
