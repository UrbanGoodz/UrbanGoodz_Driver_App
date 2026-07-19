import 'package:get/get.dart';
import 'package:urban_goodz_driver/config/api_config.dart';
import 'package:urban_goodz_driver/services/api_client.dart';
import 'package:urban_goodz_driver/models/business_job_model.dart';
import 'package:urban_goodz_driver/models/capability_model.dart';
import 'package:urban_goodz_driver/models/discovery_item_model.dart';
import 'package:urban_goodz_driver/models/notification_model.dart';

/// Real driver API integration for the Session 2 endpoint groups.
/// All calls require the token (injected by ApiClient as ?token= query param).
class DriverApiService extends GetxService {
  final ApiClient _client = Get.find<ApiClient>();

  Future<dynamic> _ok(Response res) async {
    final code = res.statusCode ?? 0;
    if (code >= 200 && code < 300) return res.body;
    final body = res.body;
    final msg = body is Map && body['message'] != null
        ? body['message'].toString()
        : 'Request failed (HTTP $code)';
    final errors = body is Map
        ? (body['errors'] as Map<String, dynamic>?)
        : null;
    throw ApiException(code, msg, errors);
  }

  // ---------- Auth ----------

  Future<Map<String, dynamic>> login(String phone, String password) async {
    final res = await _client.post(ApiConfig.driverLogin, {
      'phone': phone,
      'password': password,
    });
    final body = await _ok(res);
    return body is Map ? Map<String, dynamic>.from(body) : {};
  }

  Future<void> updateFcmToken(String fcmToken) async {
    await _ok(
      await _client.authPut(ApiConfig.updateFcmToken, {'fcm_token': fcmToken}),
    );
  }

  // ---------- Driver Profile ----------

  Future<Map<String, dynamic>> getProfile() async {
    final body = await _ok(await _client.authGet(ApiConfig.driverProfile));
    return body is Map ? Map<String, dynamic>.from(body) : {};
  }

  // ---------- Business Courier (9) ----------

  Future<List<BusinessJobModel>> getBusinessJobs() async {
    final body = await _ok(await _client.authGet(ApiConfig.businessJobs));
    final raw = (body is Map && body['jobs'] is List)
        ? body['jobs'] as List
        : [];
    return raw.map((e) => BusinessJobModel.fromJson(e)).toList();
  }

  Future<BusinessJobModel> getBusinessJobDetail(int jobId) async {
    final body = await _ok(
      await _client.authGet(ApiConfig.businessJobDetail(jobId)),
    );
    return BusinessJobModel.fromJson(
      (body is Map ? body['job'] : null) ?? <String, dynamic>{},
    );
  }

  Future<BusinessJobModel> acceptBusinessJob(int jobId) async {
    final body = await _ok(
      await _client.authPost(ApiConfig.businessJobAccept(jobId), {}),
    );
    return BusinessJobModel.fromJson(
      (body is Map ? body['job'] : null) ?? <String, dynamic>{},
    );
  }

  Future<BusinessJobModel> startBusinessJob(int jobId) async {
    final body = await _ok(
      await _client.authPost(ApiConfig.businessJobStart(jobId), {}),
    );
    return BusinessJobModel.fromJson(
      (body is Map ? body['job'] : null) ?? <String, dynamic>{},
    );
  }

  Future<BusinessJobModel> pickupBusinessJob(int jobId) async {
    final body = await _ok(
      await _client.authPost(ApiConfig.businessJobPickup(jobId), {}),
    );
    return BusinessJobModel.fromJson(
      (body is Map ? body['job'] : null) ?? <String, dynamic>{},
    );
  }

  Future<BusinessJobModel> deliverBusinessJob(int jobId) async {
    final body = await _ok(
      await _client.authPost(ApiConfig.businessJobDelivery(jobId), {}),
    );
    return BusinessJobModel.fromJson(
      (body is Map ? body['job'] : null) ?? <String, dynamic>{},
    );
  }

  Future<String> submitPickupProof(
    int jobId, {
    required String proofUrl,
    String? notes,
  }) async {
    final body = await _ok(
      await _client.authPost(ApiConfig.businessJobProofPickup(jobId), {
        'proof_url': proofUrl,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      }),
    );
    return body is Map && body['proof_of_pickup'] != null
        ? body['proof_of_pickup'].toString()
        : proofUrl;
  }

  Future<String> submitDeliveryProof(
    int jobId, {
    required String proofUrl,
    String? notes,
  }) async {
    final body = await _ok(
      await _client.authPost(ApiConfig.businessJobProofDelivery(jobId), {
        'proof_url': proofUrl,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      }),
    );
    return body is Map && body['proof_of_delivery'] != null
        ? body['proof_of_delivery'].toString()
        : proofUrl;
  }

  Future<BusinessJobModel> reportException(
    int jobId, {
    required String reason,
    String? notes,
  }) async {
    final body = await _ok(
      await _client.authPost(ApiConfig.businessJobException(jobId), {
        'reason': reason,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      }),
    );
    return BusinessJobModel.fromJson(
      (body is Map ? body['job'] : null) ?? <String, dynamic>{},
    );
  }

  // ---------- Capability (8) ----------

  Future<(CapabilityProfile profile, CapabilityAllowedValues allowed)>
  getCapabilityProfile() async {
    final body = await _ok(await _client.authGet(ApiConfig.capabilityProfile));
    final profile = CapabilityProfile.fromJson(
      (body is Map ? body['profile'] : null) ?? <String, dynamic>{},
    );
    final allowed = CapabilityAllowedValues.fromJson(
      (body is Map ? body['allowed_values'] : null) ?? <String, dynamic>{},
    );
    return (profile, allowed);
  }

  Future<CapabilitySummary> getCapabilitySummary() async {
    final body = await _ok(await _client.authGet(ApiConfig.capabilitySummary));
    return CapabilitySummary.fromJson(
      (body is Map ? body['normalized_capability_summary'] : null) ??
          <String, dynamic>{},
    );
  }

  Future<CapabilityProfile> saveVehicle({
    String? vehicleType,
    int? vehicleId,
  }) async {
    final body = await _ok(
      await _client.authPost(ApiConfig.capabilityVehicle, {
        'vehicle_type': ?vehicleType,
        'vehicle_id': ?vehicleId,
      }),
    );
    return CapabilityProfile.fromJson(
      (body is Map ? body['profile'] : null) ?? <String, dynamic>{},
    );
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
    final body = await _ok(
      await _client.authPost(ApiConfig.capabilityCargo, {
        'cargo_capacity_notes': ?cargoCapacityNotes,
        'max_package_count': ?maxPackageCount,
        'max_weight_lbs': ?maxWeightLbs,
        'has_cargo_space': ?hasCargoSpace,
        'has_cooler_bag': ?hasCoolerBag,
        'has_medical_courier_training': ?hasMedicalCourierTraining,
        'has_liftgate': ?hasLiftgate,
      }),
    );
    return CapabilityProfile.fromJson(
      (body is Map ? body['profile'] : null) ?? <String, dynamic>{},
    );
  }

  Future<CapabilityProfile> saveZones(List<String> zones) async {
    final body = await _ok(
      await _client.authPost(ApiConfig.capabilityZones, {
        'preferred_zones': zones,
      }),
    );
    return CapabilityProfile.fromJson(
      (body is Map ? body['profile'] : null) ?? <String, dynamic>{},
    );
  }

  Future<CapabilityProfile> saveWorkTypes(List<String> workTypes) async {
    final body = await _ok(
      await _client.authPost(ApiConfig.capabilityWorkTypes, {
        'preferred_work_types': workTypes,
      }),
    );
    return CapabilityProfile.fromJson(
      (body is Map ? body['profile'] : null) ?? <String, dynamic>{},
    );
  }

  Future<CapabilityProfile> saveTags(List<String> tags) async {
    final body = await _ok(
      await _client.authPost(ApiConfig.capabilityTags, {
        'capability_tags': tags,
      }),
    );
    return CapabilityProfile.fromJson(
      (body is Map ? body['profile'] : null) ?? <String, dynamic>{},
    );
  }

  Future<CapabilityProfile> saveAvailability({
    String? availabilityPreference,
    bool? availableForBusinessCourier,
    bool? availableForPackageRoutes,
    bool? availableForOrderAnywhere,
    bool? availableForMedicalCourier,
  }) async {
    final body = await _ok(
      await _client.authPost(ApiConfig.capabilityAvailability, {
        'availability_preference': ?availabilityPreference,
        'available_for_business_courier': ?availableForBusinessCourier,
        'available_for_package_routes': ?availableForPackageRoutes,
        'available_for_order_anywhere': ?availableForOrderAnywhere,
        'available_for_medical_courier': ?availableForMedicalCourier,
      }),
    );
    return CapabilityProfile.fromJson(
      (body is Map ? body['profile'] : null) ?? <String, dynamic>{},
    );
  }

  // ---------- Job Discovery (3) ----------

  Future<List<DiscoveryItem>> getDiscovery() async {
    final body = await _ok(await _client.authGet(ApiConfig.jobDiscovery));
    final raw = (body is Map && body['discovery'] is List)
        ? body['discovery'] as List
        : [];
    return raw.map((e) => DiscoveryItem.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> getDiscoverySummary() async {
    final body = await _ok(
      await _client.authGet(ApiConfig.jobDiscoverySummary),
    );
    return (body is Map && body['summary'] is Map)
        ? Map<String, dynamic>.from(body['summary'])
        : {};
  }

  Future<DiscoveryItem> getDiscoveryDetail(String type, int id) async {
    final body = await _ok(
      await _client.authGet(ApiConfig.jobDiscoveryDetail(type, id)),
    );
    return DiscoveryItem.fromJson(
      (body is Map ? body['job'] : null) ?? <String, dynamic>{},
    );
  }

  // ---------- Dispatch Notifications (5) ----------

  Future<(List<DispatchNotification> items, int unreadCount, int total)>
  getNotifications() async {
    final body = await _ok(
      await _client.authGet(ApiConfig.dispatchNotifications),
    );
    final raw = (body is Map && body['notifications'] is List)
        ? body['notifications'] as List
        : [];
    final items = raw.map((e) => DispatchNotification.fromJson(e)).toList();
    final unreadCount = body is Map
        ? int.tryParse(body['unread_count']?.toString() ?? '0') ?? 0
        : 0;
    final total = body is Map
        ? int.tryParse(body['total']?.toString() ?? '0') ?? 0
        : 0;
    return (items, unreadCount, total);
  }

  Future<int> getUnreadCount() async {
    final body = await _ok(
      await _client.authGet(ApiConfig.dispatchUnreadCount),
    );
    return body is Map
        ? int.tryParse(body['unread_count']?.toString() ?? '0') ?? 0
        : 0;
  }

  Future<void> markNotificationRead(int id) async {
    await _ok(await _client.authPost(ApiConfig.dispatchRead(id), {}));
  }

  Future<void> markAllNotificationsRead() async {
    await _ok(await _client.authPost(ApiConfig.dispatchReadAll, {}));
  }

  Future<void> dismissNotification(int id) async {
    await _ok(await _client.authPost(ApiConfig.dispatchDismiss(id), {}));
  }

  // ---------- Earnings & Payouts ----------

  Future<Map<String, dynamic>> getEarnings() async {
    final body = await _ok(await _client.authGet(ApiConfig.earnings));
    return body is Map ? Map<String, dynamic>.from(body) : {};
  }

  Future<Map<String, dynamic>> requestPayout(double amount) async {
    final body = await _ok(
      await _client.authPost(ApiConfig.payoutRequest, {'amount': amount}),
    );
    return body is Map ? Map<String, dynamic>.from(body) : {};
  }

  Future<Map<String, dynamic>> getPayoutHistory() async {
    final body = await _ok(await _client.authGet(ApiConfig.payoutHistory));
    return body is Map ? Map<String, dynamic>.from(body) : {};
  }

  // ---------- Active Jobs (6) ----------

  Future<List<Map<String, dynamic>>> getActiveJobs() async {
    final body = await _ok(await _client.authGet(ApiConfig.activeJobs));
    final raw = (body is Map && body['jobs'] is List)
        ? body['jobs'] as List
        : [];
    return raw.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> getActiveJobDetail(int jobId) async {
    final body = await _ok(
      await _client.authGet(ApiConfig.activeJobDetail(jobId)),
    );
    return (body is Map && body['job'] is Map)
        ? Map<String, dynamic>.from(body['job'])
        : {};
  }

  Future<Map<String, dynamic>> startActiveJob(int jobId) async {
    final body = await _ok(
      await _client.authPost(ApiConfig.activeJobStart(jobId), {}),
    );
    return (body is Map && body['job'] is Map)
        ? Map<String, dynamic>.from(body['job'])
        : {};
  }

  Future<Map<String, dynamic>> completeActiveJob(int jobId) async {
    final body = await _ok(
      await _client.authPost(ApiConfig.activeJobComplete(jobId), {}),
    );
    return (body is Map && body['job'] is Map)
        ? Map<String, dynamic>.from(body['job'])
        : {};
  }

  Future<Map<String, dynamic>> cancelActiveJob(int jobId) async {
    final body = await _ok(
      await _client.authPost(ApiConfig.activeJobCancel(jobId), {}),
    );
    return body is Map ? Map<String, dynamic>.from(body) : {};
  }

  Future<Map<String, dynamic>> updateActiveJobStatus(
    int jobId,
    String status,
  ) async {
    final body = await _ok(
      await _client.authPost(ApiConfig.activeJobStatus(jobId), {
        'driver_task_status': status,
      }),
    );
    return (body is Map && body['job'] is Map)
        ? Map<String, dynamic>.from(body['job'])
        : {};
  }

  // ---------- Load Board (3) ----------

  Future<Map<String, dynamic>> getLoadBoard({int page = 1}) async {
    final body = await _ok(
      await _client.authGet('${ApiConfig.loadBoard}?page=$page'),
    );
    return body is Map ? Map<String, dynamic>.from(body) : {};
  }

  Future<Map<String, dynamic>> bidOnLoad(
    int loadId,
    double bidAmount, {
    String? notes,
  }) async {
    final body = await _ok(
      await _client.authPost(ApiConfig.loadBoardBid(loadId), {
        'bid_amount': bidAmount,
        'notes': ?notes,
      }),
    );
    return body is Map ? Map<String, dynamic>.from(body) : {};
  }

  Future<Map<String, dynamic>> acceptLoad(int loadId) async {
    final body = await _ok(
      await _client.authPost(ApiConfig.loadBoardAccept(loadId), {}),
    );
    return (body is Map && body['job'] is Map)
        ? Map<String, dynamic>.from(body['job'])
        : {};
  }

  // ---------- Opportunities (2) ----------

  Future<Map<String, dynamic>> getOpportunities({
    String? type,
    int page = 1,
  }) async {
    final params = <String, String>{'page': page.toString()};
    if (type != null) params['type'] = type;
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    final body = await _ok(
      await _client.authGet('${ApiConfig.opportunities}?$query'),
    );
    return body is Map ? Map<String, dynamic>.from(body) : {};
  }

  Future<Map<String, dynamic>> claimOpportunity(int opportunityId) async {
    final body = await _ok(
      await _client.authPost(ApiConfig.opportunityClaim(opportunityId), {}),
    );
    return body is Map ? Map<String, dynamic>.from(body) : {};
  }

  // ---------- Vehicles (1) ----------

  Future<List<Map<String, dynamic>>> getVehicles() async {
    final body = await _ok(await _client.authGet(ApiConfig.vehicles));
    final raw = (body is Map && body['vehicles'] is List)
        ? body['vehicles'] as List
        : [];
    return raw.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // ---------- Certifications (3) ----------

  Future<List<Map<String, dynamic>>> getCertifications() async {
    final body = await _ok(await _client.authGet(ApiConfig.certifications));
    final raw = (body is Map && body['certifications'] is List)
        ? body['certifications'] as List
        : [];
    return raw.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> uploadCertDocument(
    int certId,
    String filePath,
  ) async {
    final body = await _ok(
      await _client.authPost(ApiConfig.certificationUpload(certId), {
        'document': filePath,
      }),
    );
    return body is Map ? Map<String, dynamic>.from(body) : {};
  }

  Future<Map<String, dynamic>> renewCertification(int certId) async {
    final body = await _ok(
      await _client.authPost(ApiConfig.certificationRenew(certId), {}),
    );
    return body is Map ? Map<String, dynamic>.from(body) : {};
  }

  // ---------- Public Onboarding API ----------

  Future<List<Map<String, dynamic>>> getPublicZones() async {
    final res = await _client.get('/api/v1/zone/list');
    final body = await _ok(res);
    if (body is List) {
      return body.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getPublicVehicles() async {
    final res = await _client.get('/api/v1/get-vehicles');
    final body = await _ok(res);
    if (body is List) {
      return body.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> registerDriver(Map<String, dynamic> data) async {
    final res = await _client.post('/api/v1/auth/delivery-man/store', data);
    final body = await _ok(res);
    return body is Map ? Map<String, dynamic>.from(body) : {};
  }

  // ---------- Order Anywhere Purchase Card ----------

  Future<Map<String, dynamic>> getPurchaseCard(int requestId) async {
    final body = await _ok(
      await _client.authGet(
        '${ApiConfig.driverApiPrefix}/order-anywhere/$requestId/purchase-card',
      ),
    );
    return body is Map && body['data'] != null
        ? Map<String, dynamic>.from(body['data'])
        : {};
  }

  Future<Map<String, dynamic>> authorizePurchaseCard(
    int requestId,
    double amount,
    String merchantName,
  ) async {
    final body = await _ok(
      await _client.authPost(
        '${ApiConfig.driverApiPrefix}/order-anywhere/$requestId/purchase-card/authorize',
        {'amount': amount, 'merchant_name': merchantName},
      ),
    );
    return body is Map && body['data'] != null
        ? Map<String, dynamic>.from(body['data'])
        : {};
  }

  Future<Map<String, dynamic>> completePurchaseCard(
    int requestId,
    double capturedAmount,
  ) async {
    final body = await _ok(
      await _client.authPost(
        '${ApiConfig.driverApiPrefix}/order-anywhere/$requestId/purchase-card/complete',
        {'captured_amount': capturedAmount},
      ),
    );
    return body is Map && body['data'] != null
        ? Map<String, dynamic>.from(body['data'])
        : {};
  }

  // ---------- Dedicated Routes (Stage A & B) ----------

  Future<List<dynamic>> getAssignedRoutes() async {
    final body = await _ok(await _client.authGet(ApiConfig.assignedRoutes));
    return (body is Map && body['routes'] is List) ? body['routes'] as List : [];
  }

  Future<Map<String, dynamic>> getRouteDetail(int routeId) async {
    final body = await _ok(await _client.authGet(ApiConfig.routeDetail(routeId)));
    return body is Map ? Map<String, dynamic>.from(body) : {};
  }

  Future<Map<String, dynamic>> resequenceRoute(int routeId, String endpointType) async {
    final body = await _ok(
      await _client.authPost(ApiConfig.resequenceRoute(routeId), {'endpoint_type': endpointType}),
    );
    return body is Map ? Map<String, dynamic>.from(body) : {};
  }

  Future<Map<String, dynamic>> startRoute(int routeId) async {
    final body = await _ok(await _client.authPost(ApiConfig.routeStarted(routeId), {}));
    return body is Map ? Map<String, dynamic>.from(body) : {};
  }

  Future<Map<String, dynamic>> completeRoute(int routeId) async {
    final body = await _ok(await _client.authPost(ApiConfig.routeCompleted(routeId), {}));
    return body is Map ? Map<String, dynamic>.from(body) : {};
  }

  Future<Map<String, dynamic>> scanPickup(
    int routeId, {
    required String barcode,
    required double lat,
    required double lng,
  }) async {
    final body = await _ok(
      await _client.authPost(ApiConfig.scanPickup(routeId), {
        'barcode': barcode,
        'lat': lat,
        'lng': lng,
      }),
    );
    return body is Map ? Map<String, dynamic>.from(body) : {};
  }

  Future<Map<String, dynamic>> scanDropoff(
    int routeId, {
    required String barcode,
    required double lat,
    required double lng,
    String? proofPhoto,
    String? signature,
  }) async {
    final body = await _ok(
      await _client.authPost(ApiConfig.scanDropoff(routeId), {
        'barcode': barcode,
        'lat': lat,
        'lng': lng,
        if (proofPhoto != null) 'proof_photo': proofPhoto,
        if (signature != null) 'signature': signature,
      }),
    );
    return body is Map ? Map<String, dynamic>.from(body) : {};
  }

  Future<Map<String, dynamic>> scanException(
    int routeId, {
    required String barcode,
    required String reason,
  }) async {
    final body = await _ok(
      await _client.authPost(ApiConfig.scanException(routeId), {
        'barcode': barcode,
        'reason': reason,
      }),
    );
    return body is Map ? Map<String, dynamic>.from(body) : {};
  }
}
