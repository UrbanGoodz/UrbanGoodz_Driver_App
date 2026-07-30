/// A marketplace delivery order as the delivery-man API returns it.
///
/// Field names mirror the backend payload rather than being renamed, so a
/// mismatch is visible at the boundary instead of being hidden behind a
/// translation layer.
class MarketplaceOrder {
  final int id;
  final String orderStatus;
  final String paymentStatus;
  final String paymentMethod;
  final String orderType;
  final double orderAmount;
  final double deliveryCharge;
  final int? deliveryManId;
  final String? otp;
  final String? scheduleAt;
  final String? createdAt;
  final String? storeName;
  final String? storeAddress;
  final double? storeLat;
  final double? storeLng;
  final String? customerName;
  final String? customerPhone;
  final String? deliveryAddress;
  final double? deliveryLat;
  final double? deliveryLng;
  final int itemCount;

  const MarketplaceOrder({
    required this.id,
    required this.orderStatus,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.orderType,
    required this.orderAmount,
    required this.deliveryCharge,
    this.deliveryManId,
    this.otp,
    this.scheduleAt,
    this.createdAt,
    this.storeName,
    this.storeAddress,
    this.storeLat,
    this.storeLng,
    this.customerName,
    this.customerPhone,
    this.deliveryAddress,
    this.deliveryLat,
    this.deliveryLng,
    this.itemCount = 0,
  });

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static double? _toNullableDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  factory MarketplaceOrder.fromJson(Map<String, dynamic> json) {
    final store = json['store'] as Map<String, dynamic>?;
    final customer = json['customer'] as Map<String, dynamic>?;
    final address = json['delivery_address'];
    final addressMap = address is Map<String, dynamic> ? address : null;

    return MarketplaceOrder(
      id: _toInt(json['id']),
      orderStatus: (json['order_status'] ?? 'pending').toString(),
      paymentStatus: (json['payment_status'] ?? 'unpaid').toString(),
      paymentMethod: (json['payment_method'] ?? '').toString(),
      orderType: (json['order_type'] ?? 'delivery').toString(),
      orderAmount: _toDouble(json['order_amount']),
      deliveryCharge: _toDouble(json['delivery_charge']),
      deliveryManId: json['delivery_man_id'] == null
          ? null
          : _toInt(json['delivery_man_id']),
      otp: json['otp']?.toString(),
      scheduleAt: json['schedule_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      storeName: store?['name']?.toString(),
      storeAddress: store?['address']?.toString(),
      storeLat: _toNullableDouble(store?['latitude']),
      storeLng: _toNullableDouble(store?['longitude']),
      customerName: customer == null
          ? null
          : '${customer['f_name'] ?? ''} ${customer['l_name'] ?? ''}'.trim(),
      customerPhone: customer?['phone']?.toString(),
      deliveryAddress:
          addressMap?['address']?.toString() ??
          (address is String ? address : null),
      deliveryLat: _toNullableDouble(addressMap?['latitude']),
      deliveryLng: _toNullableDouble(addressMap?['longitude']),
      itemCount: json['details_count'] == null
          ? _toInt((json['details'] as List?)?.length)
          : _toInt(json['details_count']),
    );
  }

  bool get isAssigned => deliveryManId != null;

  /// The canonical backend enum for delivery-man status updates.
  static const List<String> driverStatuses = [
    'confirmed',
    'picked_up',
    'delivered',
    'handover',
    'canceled',
  ];

  /// The next status this order can move to, or null when the driver has no
  /// action left. Mirrors the lifecycle the backend accepts; the vendor owns
  /// `processing` and `handover` for non-parcel orders.
  String? get nextDriverStatus {
    switch (orderStatus) {
      case 'pending':
        return 'confirmed';
      case 'confirmed':
      case 'processing':
      case 'handover':
        return 'picked_up';
      case 'picked_up':
        return 'delivered';
      default:
        return null;
    }
  }

  String get nextDriverActionLabel {
    switch (nextDriverStatus) {
      case 'confirmed':
        return 'Confirm order';
      case 'picked_up':
        return 'Mark picked up';
      case 'delivered':
        return 'Mark delivered';
      default:
        return 'No action available';
    }
  }

  bool get isComplete =>
      orderStatus == 'delivered' ||
      orderStatus == 'canceled' ||
      orderStatus == 'refunded';
}
