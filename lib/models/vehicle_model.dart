class VehicleModel {
  final String id;
  final String type;
  final String make;
  final String model;
  final int year;
  final String color;
  final String licensePlate;
  final String insuranceProvider;
  final String insuranceExpiry;
  final String registrationExpiry;
  final bool isAvailable;
  final bool isInsured;
  final bool isRegistered;
  final double mileage;
  final String lastMaintenance;
  final String nextMaintenance;
  final List<String> certifications;

  VehicleModel({
    required this.id,
    required this.type,
    required this.make,
    required this.model,
    required this.year,
    required this.color,
    required this.licensePlate,
    required this.insuranceProvider,
    required this.insuranceExpiry,
    required this.registrationExpiry,
    this.isAvailable = true,
    this.isInsured = true,
    this.isRegistered = true,
    this.mileage = 0.0,
    this.lastMaintenance = '',
    this.nextMaintenance = '',
    this.certifications = const [],
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] as String,
      type: json['type'] as String,
      make: json['make'] as String,
      model: json['model'] as String,
      year: json['year'] as int,
      color: json['color'] as String,
      licensePlate: json['license_plate'] as String,
      insuranceProvider: json['insurance_provider'] as String,
      insuranceExpiry: json['insurance_expiry'] as String,
      registrationExpiry: json['registration_expiry'] as String,
      isAvailable: json['is_available'] as bool? ?? true,
      isInsured: json['is_insured'] as bool? ?? true,
      isRegistered: json['is_registered'] as bool? ?? true,
      mileage: (json['mileage'] as num?)?.toDouble() ?? 0.0,
      lastMaintenance: json['last_maintenance'] as String? ?? '',
      nextMaintenance: json['next_maintenance'] as String? ?? '',
      certifications:
          (json['certifications'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'make': make,
      'model': model,
      'year': year,
      'color': color,
      'license_plate': licensePlate,
      'insurance_provider': insuranceProvider,
      'insurance_expiry': insuranceExpiry,
      'registration_expiry': registrationExpiry,
      'is_available': isAvailable,
      'is_insured': isInsured,
      'is_registered': isRegistered,
      'mileage': mileage,
      'last_maintenance': lastMaintenance,
      'next_maintenance': nextMaintenance,
      'certifications': certifications,
    };
  }
}
