class DriverJobModel {
  final String id;
  final String type;
  final String title;
  final String description;
  final String pickupAddress;
  final String dropoffAddress;
  final String status;
  final double earnings;
  final double distance;
  final String estimatedDuration;
  final String customerName;
  final String customerPhone;
  final String scheduledDate;
  final String scheduledTime;
  final String vehicleType;
  final bool isUrgent;
  final List<String> tags;
  final Map<String, dynamic>? specialRequirements;

  DriverJobModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.status,
    required this.earnings,
    required this.distance,
    required this.estimatedDuration,
    required this.customerName,
    required this.customerPhone,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.vehicleType,
    this.isUrgent = false,
    this.tags = const [],
    this.specialRequirements,
  });

  factory DriverJobModel.fromJson(Map<String, dynamic> json) {
    return DriverJobModel(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      pickupAddress: json['pickup_address'] as String,
      dropoffAddress: json['dropoff_address'] as String,
      status: json['status'] as String,
      earnings: (json['earnings'] as num).toDouble(),
      distance: (json['distance'] as num).toDouble(),
      estimatedDuration: json['estimated_duration'] as String,
      customerName: json['customer_name'] as String,
      customerPhone: json['customer_phone'] as String,
      scheduledDate: json['scheduled_date'] as String,
      scheduledTime: json['scheduled_time'] as String,
      vehicleType: json['vehicle_type'] as String,
      isUrgent: json['is_urgent'] as bool? ?? false,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      specialRequirements:
          json['special_requirements'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'pickup_address': pickupAddress,
      'dropoff_address': dropoffAddress,
      'status': status,
      'earnings': earnings,
      'distance': distance,
      'estimated_duration': estimatedDuration,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'scheduled_date': scheduledDate,
      'scheduled_time': scheduledTime,
      'vehicle_type': vehicleType,
      'is_urgent': isUrgent,
      'tags': tags,
      'special_requirements': specialRequirements,
    };
  }
}
