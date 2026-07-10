class DiscoveryItem {
  final String jobType; // business_courier | package_pool | dedicated_route
  final int jobId;
  final String title;
  final String status;
  final String? zoneName;
  final String? pickupAddress;
  final String? dropoffAddress;
  final String? vehicleTypeRequired;
  final bool requiresMedicalTraining;
  final bool ageRestricted;
  final List<String> matchReasons;
  final List<String> reviewFlags;
  final bool canView;
  final bool canClaim; // ALWAYS false per contract

  DiscoveryItem({
    required this.jobType,
    required this.jobId,
    required this.title,
    required this.status,
    this.zoneName,
    this.pickupAddress,
    this.dropoffAddress,
    this.vehicleTypeRequired,
    this.requiresMedicalTraining = false,
    this.ageRestricted = false,
    this.matchReasons = const [],
    this.reviewFlags = const [],
    this.canView = true,
    this.canClaim = false,
  });

  factory DiscoveryItem.fromJson(Map<String, dynamic> j) => DiscoveryItem(
        jobType: j['job_type']?.toString() ?? '',
        jobId: int.tryParse(j['job_id']?.toString() ?? '') ?? 0,
        title: j['title']?.toString() ?? '',
        status: j['status']?.toString() ?? '',
        zoneName: j['zone_name']?.toString(),
        pickupAddress: j['pickup_address']?.toString(),
        dropoffAddress: j['dropoff_address']?.toString(),
        vehicleTypeRequired: j['vehicle_type_required']?.toString(),
        requiresMedicalTraining: j['requires_medical_training'] == true,
        ageRestricted: j['age_restricted'] == true,
        matchReasons: List<String>.from(j['match_reasons'] ?? []),
        reviewFlags: List<String>.from(j['review_flags'] ?? []),
        canView: j['can_view'] != false,
        canClaim: j['can_claim'] == true,
      );

  bool get isAgeOrMedicalFlagged =>
      ageRestricted || reviewFlags.contains('age_restricted_review') ||
      requiresMedicalTraining || reviewFlags.contains('medical_review_required');
}
