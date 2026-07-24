import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:urban_goodz_driver/controllers/driver_auth_controller.dart';
import 'package:urban_goodz_driver/services/api_client.dart';
import 'package:urban_goodz_driver/services/driver_api_service.dart';

import 'support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeDriverApiService api;
  late DriverAuthController auth;

  setUp(() {
    Get.testMode = true;
    api = FakeDriverApiService(client: FakeApiClient());
    Get.put<DriverApiService>(api);
    auth = DriverAuthController();
  });

  tearDown(Get.reset);

  group('session restore', () {
    test('reports none and stays logged out when no token is stored', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await auth.restoreSession();

      expect(result, SessionRestoreResult.none);
      expect(auth.isLoggedIn.value, isFalse);
      expect(api.profileCalls, 0, reason: 'must not call the API without a token');
    });

    test('validates a stored token against the backend before trusting it', () async {
      SharedPreferences.setMockInitialValues({
        'driver_auth_token': 'stored-token',
        'driver_name': 'Old Name',
      });
      api.profile = {
        'id': 42,
        'f_name': 'Dana',
        'l_name': 'Reyes',
        'phone': '+15550101',
        'email': 'dana@urbangoodz.com',
        'active': 1,
      };

      final result = await auth.restoreSession();

      expect(result, SessionRestoreResult.valid);
      expect(api.profileCalls, 1, reason: 'stored token must be verified');
      expect(auth.isLoggedIn.value, isTrue);
      expect(auth.token.value, 'stored-token');
      expect(auth.name.value, 'Dana Reyes');
      expect(auth.driverId.value, 42);
      expect(auth.availabilityStatus.value, 'online');
      expect(auth.sessionUnverified.value, isFalse);
    });

    test('clears the session when the backend rejects the stored token', () async {
      SharedPreferences.setMockInitialValues({
        'driver_auth_token': 'revoked-token',
        'driver_name': 'Dana',
      });
      api.profileError = ApiException(401, 'Unauthenticated.');

      final result = await auth.restoreSession();

      expect(result, SessionRestoreResult.rejected);
      expect(auth.isLoggedIn.value, isFalse,
          reason: 'a revoked token must not reach the dashboard');
      expect(auth.token.value, isEmpty);
      expect(auth.sessionExpiredNotice.value, isNotEmpty);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('driver_auth_token'), isNull,
          reason: 'revoked token must be erased from disk');
    });

    test('keeps the session but flags it unverified when the server is unreachable',
        () async {
      SharedPreferences.setMockInitialValues({
        'driver_auth_token': 'good-token',
      });
      api.profileError = Exception('SocketException: no route to host');

      final result = await auth.restoreSession();

      expect(result, SessionRestoreResult.unreachable);
      expect(auth.isLoggedIn.value, isTrue,
          reason: 'a dead zone must not log the driver out');
      expect(auth.sessionUnverified.value, isTrue);
      expect(auth.token.value, 'good-token');
    });
  });

  group('logout', () {
    test('awaits disk clear, ends location reporting and drops the token', () async {
      SharedPreferences.setMockInitialValues({
        'driver_auth_token': 'live-token',
        'driver_name': 'Dana',
        'driver_id': 42,
      });
      await auth.restoreSession();
      expect(auth.isLoggedIn.value, isTrue);

      var locationStopped = false;
      auth.onSessionEnded = () async => locationStopped = true;

      await auth.logout();

      expect(auth.isLoggedIn.value, isFalse);
      expect(auth.token.value, isEmpty);
      expect(auth.driverId.value, 0);
      expect(locationStopped, isTrue,
          reason: 'a signed-out phone must stop publishing GPS');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('driver_auth_token'), isNull);
      expect(prefs.getInt('driver_id'), isNull);
    });
  });

  group('mid-session expiry', () {
    test('tears the session down once and explains why', () async {
      SharedPreferences.setMockInitialValues({
        'driver_auth_token': 'live-token',
      });
      await auth.restoreSession();

      var stops = 0;
      auth.onSessionEnded = () async => stops++;

      await auth.handleSessionExpired();
      await auth.handleSessionExpired(); // second 401 in flight

      expect(stops, 1, reason: 'teardown must be idempotent');
      expect(auth.isLoggedIn.value, isFalse);
      expect(auth.sessionExpiredNotice.value, contains('expired'));
    });

    test('does nothing when nobody is signed in', () async {
      var stops = 0;
      auth.onSessionEnded = () async => stops++;

      await auth.handleSessionExpired();

      expect(stops, 0);
    });
  });

  group('backend truthiness', () {
    test('normalises the shapes the backend actually returns', () {
      expect(DriverAuthController.isTruthy(true), isTrue);
      expect(DriverAuthController.isTruthy(1), isTrue);
      expect(DriverAuthController.isTruthy('1'), isTrue);
      expect(DriverAuthController.isTruthy('true'), isTrue);
      expect(DriverAuthController.isTruthy(false), isFalse);
      expect(DriverAuthController.isTruthy(0), isFalse);
      expect(DriverAuthController.isTruthy('0'), isFalse);
      expect(DriverAuthController.isTruthy(null), isFalse);
    });
  });
}
