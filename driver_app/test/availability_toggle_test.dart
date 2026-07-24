import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:urban_goodz_driver/config/api_config.dart';
import 'package:urban_goodz_driver/controllers/dashboard_controller.dart';
import 'package:urban_goodz_driver/controllers/driver_auth_controller.dart';
import 'package:urban_goodz_driver/services/location_provider.dart';
import 'package:urban_goodz_driver/services/location_service.dart';

import 'support/fakes.dart';
import 'support/location_fakes.dart';

/// The availability route is a server-side toggle and takes no body.
const _statusPath = '/api/v1/delivery-man/update-active-status';
const _profilePath = '/api/v1/delivery-man/profile';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeApiClient client;
  late FakeLocationProvider provider;
  late LocationService location;
  late DriverAuthController auth;
  late FakeDriverApiService api;
  late DashboardController controller;

  setUp(() {
    Get.testMode = true;
    client = FakeApiClient();
    provider = FakeLocationProvider(fix: positionAt());
    location = LocationService(provider: provider, client: client);
    auth = DriverAuthController();
    api = FakeDriverApiService(client: client);
    controller = DashboardController(
      client: client,
      location: location,
      auth: auth,
      api: api,
    );
    // Start from the real default: a driver is offline until they say so.
    controller.driverStatus.value = 'offline';
  });

  tearDown(() async {
    await location.reset();
    await provider.dispose();
    Get.reset();
  });

  const okStatus = Response(statusCode: 200, body: {'message': 'updated'});
  const okLocation = Response(statusCode: 200, body: {'message': 'recorded'});

  group('going online', () {
    test('starts GPS reporting and marks the driver available', () async {
      client.stub(_statusPath, okStatus);
      client.stub(ApiConfig.recordLocation, okLocation, times: 5);

      await controller.toggleOnlineStatus();

      expect(controller.driverStatus.value, 'online');
      expect(auth.availabilityStatus.value, 'online');
      expect(location.isReporting.value, isTrue);

      // This is the pipeline Admin depends on: the status flip AND a position.
      final paths = client.calls.map((c) => c.path).toList();
      expect(paths, contains(_statusPath));
      expect(
        paths,
        contains(ApiConfig.recordLocation),
        reason: 'an available driver with no reported position is invisible '
            'to dispatch — this is why Admin listed drivers but none available',
      );
      expect(location.isStale, isFalse);
    });

    test('aborts without changing status when location permission is refused',
        () async {
      provider.permission = LocationPermissionState.denied;
      client.stub(_statusPath, okStatus);

      await controller.toggleOnlineStatus();

      expect(controller.driverStatus.value, 'offline',
          reason: 'never tell a driver they are available when they cannot be');
      expect(location.isReporting.value, isFalse);
      expect(
        client.calls.where((c) => c.path == _statusPath),
        isEmpty,
        reason: 'the backend must not be told the driver is available',
      );
    });

    test('aborts when device location services are switched off', () async {
      provider.permission = LocationPermissionState.serviceDisabled;

      await controller.toggleOnlineStatus();

      expect(controller.driverStatus.value, 'offline');
      expect(client.calls, isEmpty);
    });

    test('rolls GPS back when the backend rejects the status change', () async {
      client.stub(
        _statusPath,
        const Response(statusCode: 500, body: {'message': 'Server Error'}),
      );
      client.stub(ApiConfig.recordLocation, okLocation, times: 5);

      await controller.toggleOnlineStatus();

      expect(controller.driverStatus.value, 'offline');
      expect(location.isReporting.value, isFalse,
          reason: 'do not keep publishing GPS for a status the backend refused');
    });

    test('rolls GPS back when the network drops mid-toggle', () async {
      client.stub(ApiConfig.recordLocation, okLocation, times: 5);
      // First call is the location report; the status POST then throws.
      await location.start();
      client.throwOnNextCall = Exception('SocketException');

      await controller.toggleOnlineStatus();

      expect(controller.driverStatus.value, 'offline');
      expect(location.isReporting.value, isFalse);
    });

    test("honours the server's own flag over an optimistic local flip", () async {
      // The route is a toggle: if the account was already active server-side,
      // the flip lands on offline and the app must not claim otherwise.
      client.stub(
        _statusPath,
        const Response(statusCode: 200, body: {'active': 0}),
      );
      client.stub(ApiConfig.recordLocation, okLocation, times: 5);

      await controller.toggleOnlineStatus();

      expect(controller.driverStatus.value, 'offline');
      expect(location.isReporting.value, isFalse);
    });
  });

  group('going offline', () {
    test('stops GPS reporting so a resting driver is not tracked', () async {
      client.stub(_statusPath, okStatus, times: 2);
      client.stub(ApiConfig.recordLocation, okLocation, times: 5);

      await controller.toggleOnlineStatus();
      expect(location.isReporting.value, isTrue);

      await controller.toggleOnlineStatus();

      expect(controller.driverStatus.value, 'offline');
      expect(auth.availabilityStatus.value, 'offline');
      expect(location.isReporting.value, isFalse);
      expect(location.isStale, isTrue);
    });

    test('does not re-request location permission when going offline', () async {
      client.stub(_statusPath, okStatus, times: 2);
      client.stub(ApiConfig.recordLocation, okLocation, times: 5);

      await controller.toggleOnlineStatus();
      final requestsWhenOnline = provider.permissionRequests;

      await controller.toggleOnlineStatus();

      expect(provider.permissionRequests, requestsWhenOnline);
    });
  });

  test('ignores a second tap while a toggle is in flight', () async {
    client.stub(_statusPath, okStatus, times: 2);
    client.stub(ApiConfig.recordLocation, okLocation, times: 5);

    final first = controller.toggleOnlineStatus();
    final second = controller.toggleOnlineStatus();
    await Future.wait([first, second]);

    expect(
      client.calls.where((c) => c.path == _statusPath),
      hasLength(1),
      reason: 'double-tapping must not flip availability twice',
    );
  });

  group('dashboard load', () {
    test('reflects the availability the backend reports', () async {
      client.stub(
        _profilePath,
        const Response(
          statusCode: 200,
          body: {
            'active': '1',
            'avg_rating': '4.8',
            'order_count': 12,
            'this_week_earning': '340.50',
          },
        ),
      );

      await controller.fetchDashboard();

      expect(controller.driverStatus.value, 'online');
      expect(controller.rating.value, 4.8);
      expect(controller.completedJobs.value, 12);
      expect(controller.weeklyEarnings.value, 340.50);
      expect(controller.isLoading.value, isFalse);
    });

    test('never synthesises a per-day earnings chart', () async {
      client.stub(
        _profilePath,
        const Response(
          statusCode: 200,
          body: {'this_week_earning': '700.00', 'active': 1},
        ),
      );

      await controller.fetchDashboard();

      expect(
        controller.weeklyEarningsChart,
        isEmpty,
        reason: 'the backend returns no daily series; inventing one showed '
            'every driver the same fabricated curve',
      );
      expect(controller.weeklyEarnings.value, 700.00);
    });

    test('surfaces a real backend error instead of an empty dashboard', () async {
      client.stub(
        _profilePath,
        const Response(
          statusCode: 500,
          body: {
            'errors': [
              {'code': 'server', 'message': 'Database unavailable'},
            ],
          },
        ),
      );

      await controller.fetchDashboard();

      expect(controller.errorMessage.value, 'Database unavailable');
      expect(controller.isLoading.value, isFalse);
    });
  });
}
