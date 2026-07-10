import 'package:get/get.dart';
import 'package:urban_goodz_driver/config/api_config.dart';
import 'package:urban_goodz_driver/services/api_client.dart';
import 'package:urban_goodz_driver/models/business_job_model.dart';
import 'package:urban_goodz_driver/models/capability_model.dart';
import 'package:urban_goodz_driver/models/discovery_item_model.dart';
import 'package:urban_goodz_driver/models/notification_model.dart';

/// Real driver API integration for the 4 Session 2 endpoint groups.
/// All calls require the bearer token (injected by ApiClient). Errors are
/// normalized into ApiException. Discovery rows are read-only (can_claim false).
class DriverApiService extends GetxService {
  final ApiClient _client = Get.find<ApiClient>();

  Future<dynamic> _ok(Response res) async {
    final code = res.statusCode ?? 0;
    if (code >= 200 && code < 300) return res.body;
    final body = res.body;
    final msg = body is Map && body['message'] != null
        ? body['message'].toString()
        : 'Request failed (HTTP $code)';
    final errors = body is Map ? (body['errors'] as Map?) : null;
    throw ApiException(code, msg, errors);
  }

  // ---------- Business Courier (9) ----------

  Future<List<BusinessJobModel>> getBusinessJobs() async {
    final body = await _ok(await _client.get(ApiConfig.businessJobs));
    final raw = (body is Map && body['jobs'] is List) ? body['jobs'] as List : [];
    return raw.map((e) => BusinessJobModel.fromJson(e)).toList();
  }

  Future<BusinessJobModel> getBusinessJobDetail(int jobId) async {
    final body = await _ok(await _client.get(ApiConfig.businessJobDetail(jobId)));
    return BusinessJobModel.fromJson((body is Map ? body['job'] : null) ?? <String, dynamic>{});
  }

  Future<BusinessJobModel> acceptBusinessJob(int jobId) async {
    final body = await _ok(await _client.post(ApiConfig.businessJobAccept(jobId), {}));
    return BusinessJobModel.fromJson((body is Map ? body['job'] : null) ?? <String, dynamic>{});
  }

  Future<BusinessJobModel> startBusinessJob(int jobId) async {
    final body = await _ok(await _client.post(ApiConfig.businessJobStart(jobId), {}));
    return BusinessJobModel.fromJson((body is Map ? body['job'] : null) ?? <String, dynamic>{});
  }

  Future<BusinessJobModel> pickupBusinessJob(int jobId) async {
    final body = await _ok(await _client.post(ApiConfig.businessJobPickup(jobId), {}));
    return BusinessJobModel.fromJson((body is Map ? body['job'] : null) ?? <String, dynamic>{});
  }

  Future<BusinessJobModel> deliverBusinessJob(int jobId) async {
    final body = await _ok(await _client.post(ApiConfig.businessJobDelivery(jobId), {}));
    return BusinessJobModel.fromJson((body is Map ? body['job'] : null) ?? <String, dynamic>{});
  }

  Future<String> submitPickupProof(int jobId,
      {required String proofUrl, String? notes}) async {
    final body = await _ok(await _client.post(ApiConfig.businessJobProofPickup(jobId), {
      'proof_url': proofUrl,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    }));
    return body is Map && body['proof_of_pickup'] != null
        ? body['proof_of_pickup'].toString()
        : proofUrl;
  }

  Future<String> submitDeliveryProof(int jobId,
      {required String proofUrl, String? notes}) async {
    final body = await _ok(await _client.post(ApiConfig.businessJobProofDelivery(jobId), {
      'proof_url': proofUrl,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    }));
    return body is Map && body['proof_of_delivery'] != null
        ? body['proof_of_delivery'].toString()
        : proofUrl;
  }

  Future<BusinessJobModel> reportException(int jobId,
      {required String reason, String? notes}) async {
    final body = await _ok(await _client.post(ApiConfig.businessJobException(jobId),
        {'reason': reason, if (notes != null && notes.isNotEmpty) 'notes': notes}));
    return BusinessJobModel.fromJson((body is Map ? body['job'] : null) ?? <String, dynamic>{});
  }

  // ---------- Capability (8) ----------

  Future<(CapabilityProfile profile, CapabilityAllowedValues allowed)>
      getCapabilityProfile() async {
    final body = await _ok(await _client.get(ApiConfig.capabilityProfile));
    final profile = CapabilityProfile.fromJson(
        (body is Map ? body['profile'] : null) ?? <String, dynamic>{});
    final allowed = CapabilityAllowedValues.fromJson(
        (body is Map ? body['allowed_values'] : null) ?? <String, dynamic>{});
    return (profile, allowed);
  }

  Future<CapabilitySummary> getCapabilitySummary() async {
    final body = await _ok(await _client.get(ApiConfig.capabilitySummary));
    return CapabilitySummary.fromJson(
        (body is Map ? body['normalized_capability_summary'] : null) ??
            <String, dynamic>{});
  }

  Future<CapabilityProfile> saveVehicle(
      {String? vehicleType, int? vehicleId}) async {
    final body = await _ok(await _client.post(ApiConfig.capabilityVehicle, {
      if (vehicleType != null) 'vehicle_type': vehicleType,
      if (vehicleId != null) 'vehicle_id': vehicleId,
    }));
    return CapabilityProfile.fromJson((body is Map ? body['profile'] : null) ?? <String, dynamic>{});
  }

  Future<CapabilityProfile> saveCargo({
    String? cargoCapacityNotes,
    int? maxPackageCount,
    double? maxWeightLbs,
    bool? hasCargoSpace,
    bool? hasCoolerBag,
    bool? hasMedicalCourierTraining,
    bool? hasLiftgate,
  }) async {
    final body = await _ok(await _client.post(ApiConfig.capabilityCargo, {
      if (cargoCapacityNotes != null) 'cargo_capacity_notes': cargoCapacityNotes,
      if (maxPackageCount != null) 'max_package_count': maxPackageCount,
      if (maxWeightLbs != null) 'max_weight_lbs': maxWeightLbs,
      if (hasCargoSpace != null) 'has_cargo_space': hasCargoSpace,
      if (hasCoolerBag != null) 'has_cooler_bag': hasCoolerBag,
      if (hasMedicalCourierTraining != null)
        'has_medical_courier_training': hasMedicalCourierTraining,
      if (hasLiftgate != null) 'has_liftgate': hasLiftgate,
    }));
    return CapabilityProfile.fromJson((body is Map ? body['profile'] : null) ?? <String, dynamic>{});
  }

  Future<CapabilityProfile> saveZones(List<String> zones) async {
    final body = await _ok(await _client
        .post(ApiConfig.capabilityZones, {'preferred_zones': zones}));
    return CapabilityProfile.fromJson((body is Map ? body['profile'] : null) ?? <String, dynamic>{});
  }

  Future<CapabilityProfile> saveWorkTypes(List<String> workTypes) async {
    final body = await _ok(await _client
        .post(ApiConfig.capabilityWorkTypes, {'preferred_work_types': workTypes}));
    return CapabilityProfile.fromJson((body is Map ? body['profile'] : null) ?? <String, dynamic>{});
  }

  Future<CapabilityProfile> saveTags(List<String> tags) async {
    final body = await _ok(
        await _client.post(ApiConfig.capabilityTags, {'capability_tags': tags}));
    return CapabilityProfile.fromJson((body is Map ? body['profile'] : null) ?? <String, dynamic>{});
  }

  Future<CapabilityProfile> saveAvailability({
    String? availabilityPreference,
    bool? availableForBusinessCourier,
    bool? availableForPackageRoutes,
    bool? availableForOrderAnywhere,
    bool? availableForMedicalCourier,
  }) async {
    final body = await _ok(await _client.post(ApiConfig.capabilityAvailability, {
      if (availabilityPreference != null)
        'availability_preference': availabilityPreference,
      if (availableForBusinessCourier != null)
        'available_for_business_courier': availableForBusinessCourier,
      if (availableForPackageRoutes != null)
        'available_for_package_routes': availableForPackageRoutes,
      if (availableForOrderAnywhere != null)
        'available_for_order_anywhere': availableForOrderAnywhere,
      if (availableForMedicalCourier != null)
        'available_for_medical_courier': availableForMedicalCourier,
    }));
    return CapabilityProfile.fromJson((body is Map ? body['profile'] : null) ?? <String, dynamic>{});
  }

  // ---------- Job Discovery (3) ----------

  Future<List<DiscoveryItem>> getDiscovery() async {
    final body = await _ok(await _client.get(ApiConfig.jobDiscovery));
    final raw = (body is Map && body['discovery'] is List)
        ? body['discovery'] as List
        : [];
    return raw.map((e) => DiscoveryItem.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> getDiscoverySummary() async {
    final body = await _ok(await _client.get(ApiConfig.jobDiscoverySummary));
    return (body is Map && body['summary'] is Map)
        ? Map<String, dynamic>.from(body['summary'])
        : {};
  }

  Future<DiscoveryItem> getDiscoveryDetail(String type, int id) async {
    final body = await _ok(await _client.get(ApiConfig.jobDiscoveryDetail(type, id)));
    return DiscoveryItem.fromJson((body is Map ? body['job'] : null) ?? <String, dynamic>{});
  }

  // ---------- Dispatch Notifications (5) ----------

  Future<(List<DispatchNotification> items, int unreadCount, int total)>
      getNotifications() async {
    final body = await _ok(await _client.get(ApiConfig.dispatchNotifications));
    final raw = (body is Map && body['notifications'] is List)
        ? body['notifications'] as List
        : [];
    final items =
        raw.map((e) => DispatchNotification.fromJson(e)).toList();
    final unreadCount =
        body is Map ? int.tryParse(body['unread_count']?.toString() ?? '0') ?? 0 : 0;
    final total =
        body is Map ? int.tryParse(body['total']?.toString() ?? '0') ?? 0 : 0;
    return (items, unreadCount, total);
  }

  Future<int> getUnreadCount() async {
    final body = await _ok(await _client.get(ApiConfig.dispatchUnreadCount));
    return body is Map
        ? int.tryParse(body['unread_count']?.toString() ?? '0') ?? 0
        : 0;
  }

  Future<void> markNotificationRead(int id) async {
    await _ok(await _client.post(ApiConfig.dispatchRead(id), {}));
  }

  Future<void> markAllNotificationsRead() async {
    await _ok(await _client.post(ApiConfig.dispatchReadAll, {}));
  }

  Future<void> dismissNotification(int id) async {
    await _ok(await _client.post(ApiConfig.dispatchDismiss(id), {}));
  }
}
