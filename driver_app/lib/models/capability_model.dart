class CapabilityProfile {
  final int driverId;
  final String? vehicleType;
  final int? vehicleId;
  final String? cargoCapacityNotes;
  final int? maxPackageCount;
  final double? maxWeightLbs;
  final bool hasCargoSpace;
  final bool hasCoolerBag;
  final bool hasMedicalCourierTraining;
  final bool hasLiftgate;
  final List<String> preferredZones;
  final List<String> preferredWorkTypes;
  final List<String> capabilityTags;
  final String availabilityPreference;
  final bool availableForBusinessCourier;
  final bool availableForPackageRoutes;
  final bool availableForOrderAnywhere;
  final bool availableForMedicalCourier;

  CapabilityProfile({
    required this.driverId,
    this.vehicleType,
    this.vehicleId,
    this.cargoCapacityNotes,
    this.maxPackageCount,
    this.maxWeightLbs,
    this.hasCargoSpace = false,
    this.hasCoolerBag = false,
    this.hasMedicalCourierTraining = false,
    this.hasLiftgate = false,
    this.preferredZones = const [],
    this.preferredWorkTypes = const [],
    this.capabilityTags = const [],
    this.availabilityPreference = 'standard',
    this.availableForBusinessCourier = false,
    this.availableForPackageRoutes = false,
    this.availableForOrderAnywhere = false,
    this.availableForMedicalCourier = false,
  });

  factory CapabilityProfile.fromJson(Map<String, dynamic> p) =>
      CapabilityProfile(
        driverId: int.tryParse(p['driver_id']?.toString() ?? '') ?? 0,
        vehicleType: p['vehicle_type']?.toString(),
        vehicleId: p['vehicle_id'] == null
            ? null
            : int.tryParse(p['vehicle_id'].toString()),
        cargoCapacityNotes: p['cargo_capacity_notes']?.toString(),
        maxPackageCount: p['max_package_count'] == null
            ? null
            : int.tryParse(p['max_package_count'].toString()),
        maxWeightLbs: p['max_weight_lbs'] == null
            ? null
            : double.tryParse(p['max_weight_lbs'].toString()),
        hasCargoSpace: p['has_cargo_space'] == true,
        hasCoolerBag: p['has_cooler_bag'] == true,
        hasMedicalCourierTraining: p['has_medical_courier_training'] == true,
        hasLiftgate: p['has_liftgate'] == true,
        preferredZones: List<String>.from(p['preferred_zones'] ?? []),
        preferredWorkTypes: List<String>.from(p['preferred_work_types'] ?? []),
        capabilityTags: List<String>.from(p['capability_tags'] ?? []),
        availabilityPreference:
            p['availability_preference']?.toString() ?? 'standard',
        availableForBusinessCourier:
            p['available_for_business_courier'] == true,
        availableForPackageRoutes: p['available_for_package_routes'] == true,
        availableForOrderAnywhere: p['available_for_order_anywhere'] == true,
        availableForMedicalCourier: p['available_for_medical_courier'] == true,
      );
}

class CapabilityAllowedValues {
  final List<String> vehicleTypes;
  final List<String> capabilityTags;
  final List<String> preferredWorkTypes;
  final List<String> availabilityPreferences;

  CapabilityAllowedValues({
    this.vehicleTypes = const [],
    this.capabilityTags = const [],
    this.preferredWorkTypes = const [],
    this.availabilityPreferences = const [],
  });

  factory CapabilityAllowedValues.fromJson(Map<String, dynamic> a) =>
      CapabilityAllowedValues(
        vehicleTypes: _options(a['vehicle_types']),
        capabilityTags: _options(a['capability_tags']),
        // The backend sends this as `work_types`; `preferred_work_types` is
        // accepted too so either shape keeps working.
        preferredWorkTypes: _options(
          a['work_types'] ?? a['preferred_work_types'],
        ),
        availabilityPreferences: _options(a['availability_preferences']),
      );

  /// Reads an option list that the backend may send as either a JSON array or
  /// a JSON object.
  ///
  /// Several of these are PHP associative arrays — VEHICLE_TYPES is
  /// `['car' => 'Car', ...]` — so they serialise as objects keyed by the value
  /// the API expects back. Passing one of those to `List.from` throws, because
  /// a Map is not Iterable, and that single failure used to abort the whole
  /// allowed-values parse and leave *every* dropdown on the capability screen
  /// empty and unselectable.
  static List<String> _options(dynamic raw) {
    if (raw == null) return const [];
    if (raw is Map) {
      return raw.keys.map((k) => k.toString()).toList();
    }
    if (raw is Iterable) {
      return raw.map((v) => v.toString()).toList();
    }
    return const [];
  }
}

class CapabilitySummary {
  final bool canHandleMedicalCourier;

  CapabilitySummary({this.canHandleMedicalCourier = false});

  factory CapabilitySummary.fromJson(Map<String, dynamic> s) {
    final dm = s['dispatch_matching'] ?? {};
    return CapabilitySummary(
      canHandleMedicalCourier: dm['can_handle_medical_courier'] == true,
    );
  }
}

/// A service zone the driver can mark as preferred.
///
/// Sourced from the platform zone list so the selector grows automatically as
/// new zones are opened, rather than being a hard-coded or free-text list.
class ZoneOption {
  final int? id;
  final String name;
  final bool isActive;

  const ZoneOption({this.id, required this.name, this.isActive = true});

  factory ZoneOption.fromJson(Map<String, dynamic> json) {
    final dynamic status = json['status'];
    return ZoneOption(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
      name: (json['display_name'] ?? json['name'] ?? '').toString(),
      isActive:
          status == null || status == 1 || status == '1' || status == true,
    );
  }
}
