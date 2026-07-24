import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:urban_goodz_driver/config/api_config.dart';
import 'package:urban_goodz_driver/controllers/driver_auth_controller.dart';
import 'package:urban_goodz_driver/services/api_client.dart';
import 'package:urban_goodz_driver/services/location_provider.dart';

/// Streams the driver's GPS position to the backend while they are online.
///
/// Before this existed the driver app never called
/// `/api/v1/delivery-man/record-location-data` at all — the constant was
/// declared in [ApiConfig] and referenced nowhere, and the Android manifest
/// requested no location permission. That is the root cause of Admin listing
/// registered drivers while showing none as available: the backend had a
/// `delivery_man` row for each driver but no location row and no recent
/// timestamp to mark them dispatchable.
class LocationService extends GetxService {
  LocationService({LocationProvider? provider, ApiClient? client})
    : _provider = provider ?? const GeolocatorLocationProvider(),
      _injectedClient = client;

  final LocationProvider _provider;
  final ApiClient? _injectedClient;

  ApiClient get _client => _injectedClient ?? Get.find<ApiClient>();

  /// A fix older than this is not trustworthy for dispatch.
  static const staleAfter = Duration(minutes: 5);

  /// Consecutive upload failures before the driver is told reporting is
  /// degraded. One dropped request in a tunnel should not raise an alarm.
  static const failuresBeforeWarning = 3;

  StreamSubscription<DriverPosition>? _subscription;

  final isReporting = false.obs;
  final permissionState = Rx<LocationPermissionState?>(null);
  final lastFixAt = Rx<DateTime?>(null);
  final lastAcceptedAt = Rx<DateTime?>(null);
  final lastLatitude = Rx<double?>(null);
  final lastLongitude = Rx<double?>(null);
  final consecutiveFailures = 0.obs;
  final lastError = ''.obs;

  /// True when reporting is on but the backend has not accepted a fix inside
  /// the staleness window — Admin will treat this driver as offline.
  bool get isStale {
    if (!isReporting.value) return true;
    final at = lastAcceptedAt.value;
    if (at == null) return true;
    return DateTime.now().difference(at) > staleAfter;
  }

  /// Starts reporting. Returns the permission outcome so the caller can show
  /// the right prompt; reporting only begins when permission is granted.
  Future<LocationPermissionState> start() async {
    final state = await _provider.ensurePermission();
    permissionState.value = state;
    if (state != LocationPermissionState.granted) {
      await stop();
      return state;
    }

    if (_subscription != null) return state;

    // Send one fix immediately so the driver becomes dispatchable as soon as
    // they go online, rather than after they next move far enough to trip the
    // stream's distance filter.
    final initial = await _provider.currentPosition();
    if (initial != null) await _report(initial);

    _subscription = _provider
        .positionStream(distanceFilterMeters: 25)
        .listen(
          _report,
          onError: (Object e) {
            lastError.value = e.toString();
          },
        );
    isReporting.value = true;
    return state;
  }

  /// Restarts reporting on app launch when the driver was already online and
  /// the OS permission is still granted — without prompting.
  Future<void> resumeIfAvailable() async {
    try {
      final auth = Get.find<DriverAuthController>();
      if (auth.availabilityStatus.value != 'online') return;
    } catch (_) {
      return;
    }
    await start();
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    isReporting.value = false;
  }

  /// Clears reporting state at logout/session expiry so a subsequent driver on
  /// the same device does not inherit the previous one's position.
  Future<void> reset() async {
    await stop();
    lastFixAt.value = null;
    lastAcceptedAt.value = null;
    lastLatitude.value = null;
    lastLongitude.value = null;
    consecutiveFailures.value = 0;
    lastError.value = '';
    permissionState.value = null;
  }

  /// POST /api/v1/delivery-man/record-location-data
  ///
  /// Route confirmed deployed: it answers 401 without a token, whereas
  /// unregistered paths on this backend answer 405. The request body could not
  /// be confirmed against a live driver token during this pass, so the field
  /// names follow the platform's existing convention and BACKEND_CONTRACTS.md
  /// carries a request for Claude 3 to confirm the exact schema and echo the
  /// stored values back in the response.
  Future<bool> _report(DriverPosition position) async {
    lastFixAt.value = position.timestamp;
    lastLatitude.value = position.latitude;
    lastLongitude.value = position.longitude;

    try {
      final res = await _client.authPost(ApiConfig.recordLocation, {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'location_timestamp': position.timestamp.toUtc().toIso8601String(),
        if (position.accuracyMeters != null)
          'accuracy': position.accuracyMeters,
      });

      final code = res.statusCode ?? 0;
      if (code >= 200 && code < 300) {
        lastAcceptedAt.value = DateTime.now();
        consecutiveFailures.value = 0;
        lastError.value = '';
        return true;
      }

      // A 401 here has already tripped ApiClient.onUnauthorized, which ends the
      // session and calls reset(); there is nothing to retry.
      if (code == 401) {
        lastError.value = 'Session expired.';
        return false;
      }

      consecutiveFailures.value++;
      lastError.value = ApiException.fromResponse(res).message;
      return false;
    } catch (e) {
      // Network drop: keep the subscription alive so the next fix retries.
      consecutiveFailures.value++;
      lastError.value = e.toString();
      return false;
    }
  }

  /// Exposed for tests: pushes a fix through the same path the stream uses.
  @visibleForTesting
  Future<bool> reportForTest(DriverPosition position) => _report(position);

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
