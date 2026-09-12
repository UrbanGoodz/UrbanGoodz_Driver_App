class DedicatedRouteModel {
  final int id;
  final String routeName;
  final String routeType;
  final String pickupLocation;
  final double pickupLat;
  final double pickupLng;
  final String status;
  final int totalPackages;
  final int completedPackages;
  final int failedPackages;
  final double driverPayPerPackage;
  final bool instantPayoutAllowed;
  final bool weeklyPayoutAllowed;
  final String vehicleTypeRequired;

  DedicatedRouteModel({
    required this.id,
    required this.routeName,
    required this.routeType,
    required this.pickupLocation,
    required this.pickupLat,
    required this.pickupLng,
    required this.status,
    required this.totalPackages,
    required this.completedPackages,
    required this.failedPackages,
    required this.driverPayPerPackage,
    required this.instantPayoutAllowed,
    required this.weeklyPayoutAllowed,
    required this.vehicleTypeRequired,
  });

  /// Parses a number that the API may send as either a JSON number or a
  /// string.
  ///
  /// MySQL DECIMAL columns are serialised by PHP as strings - `pickup_lat`
  /// arrives as `"29.7604000"` and `driver_pay_per_package` as `"0.00"`, not
  /// as numbers. A bare `as num?` cast therefore throws
  /// "type 'String' is not a subtype of type 'num?' in type cast", which took
  /// down the entire Assigned Dedicated Routes screen for any driver who
  /// actually had a route. The screen only looked healthy because no route
  /// was ever assigned in testing.
  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  /// Same problem for counts, which can arrive as "6" rather than 6.
  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  factory DedicatedRouteModel.fromJson(Map<String, dynamic> json) {
    return DedicatedRouteModel(
      id: _toInt(json['id']),
      routeName: json['route_name'] ?? '',
      routeType: json['route_type'] ?? '',
      pickupLocation: json['pickup_location'] ?? '',
      pickupLat: _toDouble(json['pickup_lat']),
      pickupLng: _toDouble(json['pickup_lng']),
      status: json['status'] ?? 'planned',
      totalPackages: _toInt(json['total_packages']),
      completedPackages: _toInt(json['completed_packages']),
      failedPackages: _toInt(json['failed_packages']),
      driverPayPerPackage: _toDouble(json['driver_pay_per_package']),
      instantPayoutAllowed: json['instant_payout_allowed'] == 1 || json['instant_payout_allowed'] == true,
      weeklyPayoutAllowed: json['weekly_payout_allowed'] == 1 || json['weekly_payout_allowed'] == true,
      vehicleTypeRequired: json['vehicle_type_required'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'route_name': routeName,
      'route_type': routeType,
      'pickup_location': pickupLocation,
      'pickup_lat': pickupLat,
      'pickup_lng': pickupLng,
      'status': status,
      'total_packages': totalPackages,
      'completed_packages': completedPackages,
      'failed_packages': failedPackages,
      'driver_pay_per_package': driverPayPerPackage,
      'instant_payout_allowed': instantPayoutAllowed,
      'weekly_payout_allowed': weeklyPayoutAllowed,
      'vehicle_type_required': vehicleTypeRequired,
    };
  }
}

class RoutePackageModel {
  final int id;
  final String trackingId;
  final String barcode;
  final String dropoffName;
  final String dropoffAddress;
  final double dropoffLat;
  final double dropoffLng;
  final String? deliveryWindowStart;
  final String? deliveryWindowEnd;
  final String status;
  final String? exceptionReason;
  final bool ageRestricted;
  final bool requiresIdVerification;
  final bool noContactlessDelivery;
  final bool deliveryCompletionLockedUntilVerified;
  final String? ageVerificationStatus;
  final int stopOrder;

  RoutePackageModel({
    required this.id,
    required this.trackingId,
    required this.barcode,
    required this.dropoffName,
    required this.dropoffAddress,
    required this.dropoffLat,
    required this.dropoffLng,
    this.deliveryWindowStart,
    this.deliveryWindowEnd,
    required this.status,
    this.exceptionReason,
    required this.ageRestricted,
    required this.requiresIdVerification,
    required this.noContactlessDelivery,
    required this.deliveryCompletionLockedUntilVerified,
    this.ageVerificationStatus,
    required this.stopOrder,
  });

  factory RoutePackageModel.fromJson(Map<String, dynamic> json) {
    return RoutePackageModel(
      id: DedicatedRouteModel._toInt(json['package_id'] ?? json['id']),
      trackingId: json['tracking_id'] ?? '',
      barcode: json['barcode'] ?? '',
      dropoffName: json['dropoff_name'] ?? '',
      dropoffAddress: json['dropoff_address'] ?? '',
      // Same string-vs-number problem as the route coordinates above.
      dropoffLat: DedicatedRouteModel._toDouble(json['dropoff_lat']),
      dropoffLng: DedicatedRouteModel._toDouble(json['dropoff_lng']),
      deliveryWindowStart: json['delivery_window_start'],
      deliveryWindowEnd: json['delivery_window_end'],
      status: json['status'] ?? 'pending',
      exceptionReason: json['exception_reason'],
      ageRestricted: json['age_restricted'] == 1 || json['age_restricted'] == true,
      requiresIdVerification: json['requires_id_verification'] == 1 || json['requires_id_verification'] == true,
      noContactlessDelivery: json['no_contactless_delivery'] == 1 || json['no_contactless_delivery'] == true,
      deliveryCompletionLockedUntilVerified: json['delivery_completion_locked_until_verified'] == 1 || json['delivery_completion_locked_until_verified'] == true,
      ageVerificationStatus: json['age_verification_status'],
      stopOrder: json['stop_order'] == null ? 1 : DedicatedRouteModel._toInt(json['stop_order']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'package_id': id,
      'id': id,
      'tracking_id': trackingId,
      'barcode': barcode,
      'dropoff_name': dropoffName,
      'dropoff_address': dropoffAddress,
      'dropoff_lat': dropoffLat,
      'dropoff_lng': dropoffLng,
      'delivery_window_start': deliveryWindowStart,
      'delivery_window_end': deliveryWindowEnd,
      'status': status,
      'exception_reason': exceptionReason,
      'age_restricted': ageRestricted,
      'requires_id_verification': requiresIdVerification,
      'no_contactless_delivery': noContactlessDelivery,
      'delivery_completion_locked_until_verified': deliveryCompletionLockedUntilVerified,
      'age_verification_status': ageVerificationStatus,
      'stop_order': stopOrder,
    };
  }
}

class RouteStopModel {
  final int stopOrder;
  final String address;
  final double lat;
  final double lng;
  final List<RoutePackageModel> packages;

  RouteStopModel({
    required this.stopOrder,
    required this.address,
    required this.lat,
    required this.lng,
    required this.packages,
  });

  bool get isLocked => packages.any((p) => p.deliveryCompletionLockedUntilVerified);
  bool get isCompleted => packages.every((p) => p.status == 'delivered' || p.status == 'failed' || p.status == 'returned');
  bool get isArrived => packages.any((p) => p.status == 'arrived');
  bool get isLoaded => packages.every((p) => p.status != 'pending'); // loaded or processed
}
