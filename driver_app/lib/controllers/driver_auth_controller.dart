import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:urban_goodz_driver/screens/driver_onboarding_screen.dart';
import 'package:urban_goodz_driver/services/api_client.dart';
import 'package:urban_goodz_driver/services/driver_api_service.dart';

/// Outcome of restoring a persisted session on cold start.
enum SessionRestoreResult {
  /// No token was stored — show the login screen.
  none,

  /// Stored token was accepted by the backend.
  valid,

  /// Backend rejected the stored token (401); session has been cleared.
  rejected,

  /// Backend was unreachable. The token is kept so the driver is not logged
  /// out by a dead zone, but nothing has been confirmed yet.
  unreachable,
}

class DriverAuthController extends GetxController {
  var isLoggedIn = false.obs;

  var token = ''.obs;
  var name = ''.obs;
  var phone = ''.obs;
  var email = ''.obs;
  var city = ''.obs;
  var vehicleType = ''.obs;
  var vehicleDetails = ''.obs;
  var availabilityStatus = 'offline'.obs;
  var driverId = 0.obs;

  var serviceOrderAnywhere = true.obs;
  var serviceDelivery = true.obs;
  var serviceCourier = true.obs;
  var serviceMedicalCourier = false.obs;
  var serviceLogistics = false.obs;

  /// Set when a previously valid session was terminated by the backend, so the
  /// login screen can explain why the driver is looking at it again.
  var sessionExpiredNotice = ''.obs;

  /// True while the persisted token has not yet been confirmed with the
  /// backend (offline cold start).
  var sessionUnverified = false.obs;

  static const _tokenKey = 'driver_auth_token';
  static const _nameKey = 'driver_name';
  static const _phoneKey = 'driver_phone';
  static const _emailKey = 'driver_email';
  static const _driverIdKey = 'driver_id';

  /// Invoked on logout and on session expiry so location reporting stops with
  /// the session. Wired by [LocationService]; left null in tests.
  Future<void> Function()? onSessionEnded;

  bool _tearingDown = false;

  /// Restores a persisted session and, critically, *validates it against the
  /// backend* before treating the driver as logged in.
  ///
  /// Previously this trusted any non-empty stored string: a revoked or expired
  /// token booted straight to the dashboard, where every authenticated call
  /// then failed 401 and was swallowed, leaving a permanently empty screen with
  /// no way to recover except reinstalling.
  Future<SessionRestoreResult> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString(_tokenKey) ?? '';
    if (savedToken.isEmpty) {
      isLoggedIn.value = false;
      return SessionRestoreResult.none;
    }

    token.value = savedToken;
    name.value = prefs.getString(_nameKey) ?? '';
    phone.value = prefs.getString(_phoneKey) ?? '';
    email.value = prefs.getString(_emailKey) ?? '';
    driverId.value = prefs.getInt(_driverIdKey) ?? 0;

    final DriverApiService service;
    try {
      service = Get.find<DriverApiService>();
    } catch (_) {
      // No API layer registered (unit tests): accept the stored session.
      isLoggedIn.value = true;
      return SessionRestoreResult.valid;
    }

    try {
      final profile = await service.getProfile();
      applyProfile(profile);
      isLoggedIn.value = true;
      sessionUnverified.value = false;
      return SessionRestoreResult.valid;
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await _clearPersistedSession();
        isLoggedIn.value = false;
        sessionExpiredNotice.value =
            'Your session has expired. Please sign in again.';
        return SessionRestoreResult.rejected;
      }
      // Server reachable but erroring — keep the session, flag it unverified.
      isLoggedIn.value = true;
      sessionUnverified.value = true;
      return SessionRestoreResult.unreachable;
    } catch (_) {
      isLoggedIn.value = true;
      sessionUnverified.value = true;
      return SessionRestoreResult.unreachable;
    }
  }

  /// Copies the fields the driver profile endpoint actually returns onto the
  /// controller. Unknown/absent keys are left untouched rather than replaced
  /// with invented defaults.
  void applyProfile(Map<String, dynamic> profile) {
    final dm = profile['delivery_man'] is Map
        ? Map<String, dynamic>.from(profile['delivery_man'] as Map)
        : profile;

    final first = dm['first_name']?.toString() ?? dm['f_name']?.toString();
    final last = dm['last_name']?.toString() ?? dm['l_name']?.toString();
    final full = [
      first,
      last,
    ].where((p) => p != null && p.isNotEmpty).join(' ').trim();
    if (full.isNotEmpty) name.value = full;

    if (dm['phone'] != null) phone.value = dm['phone'].toString();
    if (dm['email'] != null) email.value = dm['email'].toString();

    final id = int.tryParse(dm['id']?.toString() ?? '');
    if (id != null && id > 0) driverId.value = id;

    if (dm.containsKey('active')) {
      availabilityStatus.value = isTruthy(dm['active']) ? 'online' : 'offline';
    }
  }

  /// The backend serialises booleans inconsistently across routes (`true`, `1`,
  /// `"1"`), so availability is normalised in one place.
  static bool isTruthy(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final s = value?.toString().toLowerCase().trim();
    return s == '1' || s == 'true';
  }

  Future<void> persistSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token.value);
    await prefs.setString(_nameKey, name.value);
    await prefs.setString(_phoneKey, phone.value);
    await prefs.setString(_emailKey, email.value);
    await prefs.setInt(_driverIdKey, driverId.value);
  }

  void setToken(String value) {
    token.value = value.trim();
  }

  void clearToken() {
    token.value = '';
  }

  Future<void> _clearPersistedSession() async {
    clearToken();
    name.value = '';
    phone.value = '';
    email.value = '';
    driverId.value = 0;
    availabilityStatus.value = 'offline';
    sessionUnverified.value = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_nameKey);
      await prefs.remove(_phoneKey);
      await prefs.remove(_emailKey);
      await prefs.remove(_driverIdKey);
    } catch (_) {}
  }

  /// Driver-initiated sign out. Stops location reporting, clears the persisted
  /// token, then returns to the login screen.
  ///
  /// The previous implementation fired `prefs.clear()` without awaiting it and
  /// navigated immediately, so the token could still be on disk when the app
  /// was killed mid-logout — the next launch silently resumed the old session.
  Future<void> logout() async {
    // Revoke the session on the server before dropping the local copy.
    // Clearing only the handset left delivery_men.auth_token valid forever, so
    // a lost or resold phone kept a working bearer and kept receiving this
    // driver's assignments. Best-effort: if the call fails the local session is
    // still torn down, because refusing to log out is the worse failure.
    try {
      await Get.find<DriverApiService>().logout();
    } catch (_) {}

    await _endSession();
    Get.offAll(() => const DriverOnboardingScreen());
  }

  /// Backend rejected the token mid-session (401 on any authenticated call).
  /// Tears the session down once and routes back to login with an explanation.
  Future<void> handleSessionExpired() async {
    if (_tearingDown || !isLoggedIn.value) return;
    _tearingDown = true;
    try {
      await _endSession();
      sessionExpiredNotice.value =
          'Your session has expired. Please sign in again.';
      Get.offAll(() => const DriverOnboardingScreen());
    } finally {
      _tearingDown = false;
    }
  }

  Future<void> _endSession() async {
    isLoggedIn.value = false;
    try {
      await onSessionEnded?.call();
    } catch (_) {}
    await _clearPersistedSession();
  }
}
