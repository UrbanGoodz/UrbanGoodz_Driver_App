import 'package:get/get.dart';
import 'package:urban_goodz_driver/controllers/driver_auth_controller.dart';
import 'package:urban_goodz_driver/services/api_client.dart';
import 'package:urban_goodz_driver/services/driver_api_service.dart';
import 'package:urban_goodz_driver/services/location_provider.dart';
import 'package:urban_goodz_driver/services/location_service.dart';
import 'package:urban_goodz_driver/models/business_job_model.dart';

class DashboardController extends GetxController {
  DashboardController({
    ApiClient? client,
    LocationService? location,
    DriverAuthController? auth,
    DriverApiService? api,
  }) : _injectedClient = client,
       _injectedLocation = location,
       _injectedAuth = auth,
       _injectedApi = api;

  final ApiClient? _injectedClient;
  final LocationService? _injectedLocation;
  final DriverAuthController? _injectedAuth;
  final DriverApiService? _injectedApi;

  ApiClient get _client => _injectedClient ?? Get.find<ApiClient>();
  LocationService get _location =>
      _injectedLocation ?? Get.find<LocationService>();
  DriverAuthController get _auth =>
      _injectedAuth ?? Get.find<DriverAuthController>();
  DriverApiService get _api => _injectedApi ?? Get.find<DriverApiService>();

  var todayEarnings = 0.0.obs;
  var weeklyEarnings = 0.0.obs;
  var monthlyEarnings = 0.0.obs;
  var completedJobs = 0.obs;
  var activeJobs = 0.obs;
  var acceptanceRate = 0.0.obs;
  var rating = 0.0.obs;
  var activeJobsList = <BusinessJobModel>[].obs;
  var weeklyEarningsChart = <double>[].obs;
  var driverStatus = 'online'.obs;
  var isLoading = true.obs;
  var errorMessage = ''.obs;
  var isTogglingStatus = false.obs;

  /// Why the last availability toggle failed. The screen turns this into a
  /// snackbar; the controller stays free of UI so it can be tested headlessly.
  var toggleError = ''.obs;

  @override
  void onInit() {
    fetchDashboard();
    super.onInit();
  }

  Future<void> fetchDashboard() async {
    isLoading.value = true;
    errorMessage.value = '';

    await Future.wait([_loadProfile(), _loadActiveJobs()]);

    isLoading.value = false;
  }

  Future<void> _loadProfile() async {
    try {
      final res = await _client.authGet('/api/v1/delivery-man/profile');
      if (res.statusCode == 200 && res.body is Map) {
        final body = res.body as Map;
        final raw = body['delivery_man'] ?? body;
        final dm = Map<String, dynamic>.from(raw as Map);

        rating.value = double.tryParse(dm['avg_rating']?.toString() ?? '') ?? 0;
        completedJobs.value =
            int.tryParse(dm['order_count']?.toString() ?? '') ?? 0;
        todayEarnings.value =
            double.tryParse(dm['todays_earning']?.toString() ?? '') ?? 0;
        weeklyEarnings.value =
            double.tryParse(dm['this_week_earning']?.toString() ?? '') ?? 0;
        monthlyEarnings.value =
            double.tryParse(dm['this_month_earning']?.toString() ?? '') ?? 0;

        if (dm.containsKey('active')) {
          driverStatus.value = DriverAuthController.isTruthy(dm['active'])
              ? 'online'
              : 'offline';
        }

        // The per-day breakdown is deliberately NOT synthesised. This used to
        // fan `this_week_earning` out across seven fixed percentages
        // (0.12, 0.15, 0.18, ...), producing a chart that looked like real
        // daily history but was the same invented curve for every driver.
        // The profile endpoint returns no daily series; until a backend route
        // provides one (see BACKEND_CONTRACTS.md) the chart stays empty and
        // the dashboard shows the weekly total instead.
        weeklyEarningsChart.clear();
      } else if (res.statusCode != 401) {
        errorMessage.value = ApiException.fromResponse(res).message;
      }
    } catch (_) {
      errorMessage.value = 'Unable to load your profile. Pull down to retry.';
    }
  }

  Future<void> _loadActiveJobs() async {
    try {
      final jobs = await _api.getBusinessJobs();
      activeJobsList.value = jobs;
      activeJobs.value = jobs.length;
    } on ApiException catch (e) {
      if (!e.isUnauthorized) errorMessage.value = e.message;
    } catch (_) {
      // Network failure is already surfaced by the profile load.
    }
  }

  /// Toggles delivery-man availability against the live backend and starts or
  /// stops GPS reporting to match.
  ///
  /// Endpoint verified live 2026-07-23 via direct HTTPS probe against
  /// admin.urbangoodzdelivery.com: POST /api/v1/delivery-man/update-active-status
  /// returns HTTP 401 when tokenless -- the signature every confirmed-real,
  /// auth-protected route on this backend returns, whereas unregistered paths
  /// return HTTP 405. The route is a server-side toggle and takes no body.
  ///
  /// Going online without a position is meaningless: Admin ranks drivers by
  /// last reported location, so a driver flagged active with no fix is
  /// invisible to dispatch. Permission is therefore obtained *before* the
  /// status flip, and a refusal aborts it rather than leaving the driver
  /// believing they are available.
  Future<void> toggleOnlineStatus() async {
    if (isTogglingStatus.value) return;
    final previous = driverStatus.value;
    final goingOnline = previous != 'online';
    isTogglingStatus.value = true;

    try {
      if (goingOnline) {
        final permission = await _location.start();
        if (permission != LocationPermissionState.granted) {
          toggleError.value = _permissionMessage(permission);
          return;
        }
      }

      final res = await _client.authPost(
        '/api/v1/delivery-man/update-active-status',
        {},
      );

      if (res.statusCode == 200) {
        // Trust the server's own view of the flag when it reports one; the
        // route is a toggle, so an optimistic local flip can drift out of sync
        // if two devices toggle the same account.
        final body = res.body;
        final reported = body is Map
            ? (body['active'] ??
                  (body['data'] is Map ? body['data']['active'] : null))
            : null;
        driverStatus.value = reported != null
            ? (DriverAuthController.isTruthy(reported) ? 'online' : 'offline')
            : (goingOnline ? 'online' : 'offline');

        _auth.availabilityStatus.value = driverStatus.value;

        if (driverStatus.value != 'online') {
          await _location.stop();
        }
      } else {
        if (goingOnline) await _location.stop();
        toggleError.value = ApiException.fromResponse(res).message;
      }
    } catch (_) {
      if (goingOnline) await _location.stop();
      toggleError.value =
          'Unable to reach the server. Check your connection and try again.';
    } finally {
      isTogglingStatus.value = false;
    }
  }

  String _permissionMessage(LocationPermissionState state) {
    switch (state) {
      case LocationPermissionState.serviceDisabled:
        return 'Turn on location services to go online and receive jobs.';
      case LocationPermissionState.deniedForever:
        return 'Location permission is blocked. Enable it in Settings to go online.';
      case LocationPermissionState.denied:
      case LocationPermissionState.granted:
        return 'Location access is required to go online and receive jobs.';
    }
  }
}
