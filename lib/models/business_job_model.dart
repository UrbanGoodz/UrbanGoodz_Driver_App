class BusinessJobModel {
  final int jobId;
  final String jobNumber;
  final int? businessClientId;
  final String? businessClientName;
  final String jobType;
  final String status;
  final String? description;
  final String? referenceNumber;
  final String? poNumber;
  final JobLocation pickup;
  final JobLocation dropoff;
  final JobRequirements requirements;
  final JobPricing pricing;
  final String? driverNotes;
  final JobException exception;
  final JobProof proof;
  final bool hasException;

  BusinessJobModel({
    required this.jobId,
    required this.jobNumber,
    this.businessClientId,
    this.businessClientName,
    required this.jobType,
    required this.status,
    this.description,
    this.referenceNumber,
    this.poNumber,
    required this.pickup,
    required this.dropoff,
    required this.requirements,
    required this.pricing,
    this.driverNotes,
    required this.exception,
    required this.proof,
    required this.hasException,
  });

  factory BusinessJobModel.fromJson(Map<String, dynamic> j) {
    return BusinessJobModel(
      jobId: int.tryParse(j['job_id']?.toString() ?? '') ?? 0,
      jobNumber: j['job_number']?.toString() ?? '',
      businessClientId: j['business_client_id'] == null
          ? null
          : int.tryParse(j['business_client_id'].toString()),
      businessClientName: j['business_client_name']?.toString(),
      jobType: j['job_type']?.toString() ?? 'business_courier',
      status: j['status']?.toString() ?? 'assigned',
      description: j['description']?.toString(),
      referenceNumber: j['reference_number']?.toString(),
      poNumber: j['po_number']?.toString(),
      pickup: JobLocation.fromJson(j['pickup'] ?? {}),
      dropoff: JobLocation.fromJson(j['dropoff'] ?? {}),
      requirements: JobRequirements.fromJson(j['requirements'] ?? {}),
      pricing: JobPricing.fromJson(j['pricing'] ?? {}),
      driverNotes: j['driver_notes']?.toString(),
      exception: JobException.fromJson(j['exception'] ?? {}),
      proof: JobProof.fromJson(j['proof'] ?? {}),
      hasException: j['exception']?['has_exception'] == true,
    );
  }

  // Display-only rate (NOT a driver payout). Per contract: no payout/payment fields.
  String get displayRate => pricing.rateOffered ?? '—';
}

class JobLocation {
  final String? name;
  final String? address;
  final String? city;
  final String? state;
  final String? contactName;
  final String? contactPhone;
  final String? instructions;
  final String? earliest;
  final String? latest;
  final String? deadline;

  JobLocation({
    this.name,
    this.address,
    this.city,
    this.state,
    this.contactName,
    this.contactPhone,
    this.instructions,
    this.earliest,
    this.latest,
    this.deadline,
  });

  factory JobLocation.fromJson(Map<String, dynamic> j) => JobLocation(
        name: j['name']?.toString(),
        address: j['address']?.toString(),
        city: j['city']?.toString(),
        state: j['state']?.toString(),
        contactName: j['contact_name']?.toString(),
        contactPhone: j['contact_phone']?.toString(),
        instructions: j['pickup_instructions']?.toString() ??
            j['delivery_instructions']?.toString(),
        earliest: j['pickup_earliest']?.toString(),
        latest: j['pickup_latest']?.toString(),
        deadline: j['delivery_deadline']?.toString(),
      );
}

class JobRequirements {
  final String? vehicleTypeNeeded;
  final bool needsLiftgate;
  final bool needsDock;
  final String? specialHandling;
  final String? loadType;
  final String? weight;
  final String? temperatureRequirement;
  final bool courierCertificationRequired;
  final bool chainOfCustodyRequired;
  final String? urgencyLevel;

  JobRequirements({
    this.vehicleTypeNeeded,
    this.needsLiftgate = false,
    this.needsDock = false,
    this.specialHandling,
    this.loadType,
    this.weight,
    this.temperatureRequirement,
    this.courierCertificationRequired = false,
    this.chainOfCustodyRequired = false,
    this.urgencyLevel,
  });

  factory JobRequirements.fromJson(Map<String, dynamic> j) => JobRequirements(
        vehicleTypeNeeded: j['vehicle_type_needed']?.toString(),
        needsLiftgate: j['needs_liftgate'] == true,
        needsDock: j['needs_dock'] == true,
        specialHandling: j['special_handling']?.toString(),
        loadType: j['load_type']?.toString(),
        weight: j['weight']?.toString(),
        temperatureRequirement: j['temperature_requirement']?.toString(),
        courierCertificationRequired: j['courier_certification_required'] == true,
        chainOfCustodyRequired: j['chain_of_custody_required'] == true,
        urgencyLevel: j['urgency_level']?.toString(),
      );
}

class JobPricing {
  final String? rateOffered;
  final String? currency;

  JobPricing({this.rateOffered, this.currency});

  factory JobPricing.fromJson(Map<String, dynamic> j) => JobPricing(
        rateOffered: j['rate_offered']?.toString(),
        currency: j['currency']?.toString(),
      );
}

class JobException {
  final bool hasException;
  final String? reason;
  final String? reportedAt;

  JobException(
      {required this.hasException, this.reason, this.reportedAt});

  factory JobException.fromJson(Map<String, dynamic> j) => JobException(
        hasException: j['has_exception'] == true,
        reason: j['reason']?.toString(),
        reportedAt: j['reported_at']?.toString(),
      );
}

class JobProof {
  final String? proofOfPickup;
  final String? proofOfDelivery;
  final bool pickupProofSubmitted;
  final bool deliveryProofSubmitted;

  JobProof({
    this.proofOfPickup,
    this.proofOfDelivery,
    this.pickupProofSubmitted = false,
    this.deliveryProofSubmitted = false,
  });

  factory JobProof.fromJson(Map<String, dynamic> j) => JobProof(
        proofOfPickup: j['proof_of_pickup']?.toString(),
        proofOfDelivery: j['proof_of_delivery']?.toString(),
        pickupProofSubmitted: j['pickup_proof_submitted'] == true,
        deliveryProofSubmitted: j['delivery_proof_submitted'] == true,
      );
}
