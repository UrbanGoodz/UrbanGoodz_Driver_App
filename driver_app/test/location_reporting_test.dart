import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:urban_goodz_driver/config/api_config.dart';
import 'package:urban_goodz_driver/services/location_provider.dart';
import 'package:urban_goodz_driver/services/location_service.dart';

import 'support/fakes.dart';
import 'support/location_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeApiClient client;
  late FakeLocationProvider provider;
  late LocationService service;

  setUp(() {
    Get.testMode = true;
    client = FakeApiClient();
    provider = FakeLocationProvider(fix: positionAt());
    service = LocationService(provider: provider, client: client);
  });

  tearDown(() async {
    await service.reset();
    await provider.dispose();
    Get.reset();
  });

  const ok = Response(statusCode: 200, body: {'message': 'recorded'});

  test('refuses to report and stays stopped when permission is denied', () async {
    provider.permission = LocationPermissionState.denied;

    final state = await service.start();

    expect(state, LocationPermissionState.denied);
    expect(service.isReporting.value, isFalse);
    expect(client.calls, isEmpty, reason: 'no fix means nothing to send');
  });

  test('reports the driver location to the verified backend route on start', () async {
    client.stub(ApiConfig.recordLocation, ok, times: 5);

    final state = await service.start();

    expect(state, LocationPermissionState.granted);
    expect(service.isReporting.value, isTrue);

    // An immediate fix is sent so the driver is dispatchable at once rather
    // than after they next move far enough to trip the distance filter.
    expect(client.calls, hasLength(1));
    expect(client.calls.single.method, 'POST');
    expect(client.calls.single.path, ApiConfig.recordLocation);

    final body = client.calls.single.body as Map;
    expect(body['latitude'], 40.7128);
    expect(body['longitude'], -74.0060);
    expect(
      body['location_timestamp'],
      isNotNull,
      reason: 'Admin needs a timestamp to tell a live driver from a stale one',
    );
  });

  test('streams subsequent fixes as the driver moves', () async {
    client.stub(ApiConfig.recordLocation, ok, times: 5);
    await service.start();

    provider.controller.add(positionAt(lat: 40.75, lng: -73.99));
    await Future<void>.delayed(Duration.zero);

    expect(client.calls, hasLength(2));
    expect((client.calls.last.body as Map)['latitude'], 40.75);
    expect(service.lastLatitude.value, 40.75);
  });

  test('counts upload failures without tearing down the stream', () async {
    client.stub(
      ApiConfig.recordLocation,
      const Response(statusCode: 500, body: {'message': 'Server Error'}),
      times: 3,
    );

    await service.start();

    expect(service.consecutiveFailures.value, 1);
    expect(service.lastError.value, 'Server Error');
    expect(
      service.isReporting.value,
      isTrue,
      reason: 'a failed upload must not stop GPS; the next fix retries',
    );
  });

  test('recovers and clears the failure count once the backend accepts a fix',
      () async {
    client.stub(
      ApiConfig.recordLocation,
      const Response(statusCode: 500, body: {'message': 'Server Error'}),
    );
    client.stub(ApiConfig.recordLocation, ok);

    await service.start();
    expect(service.consecutiveFailures.value, 1);

    provider.controller.add(positionAt());
    await Future<void>.delayed(Duration.zero);

    expect(service.consecutiveFailures.value, 0);
    expect(service.lastError.value, isEmpty);
    expect(service.lastAcceptedAt.value, isNotNull);
  });

  test('survives a socket failure and keeps reporting', () async {
    client.stub(ApiConfig.recordLocation, ok, times: 3);
    client.throwOnNextCall = Exception('SocketException');

    await service.start();

    expect(service.consecutiveFailures.value, 1);
    expect(service.isReporting.value, isTrue);
  });

  group('staleness', () {
    test('is stale while stopped', () {
      expect(service.isStale, isTrue);
    });

    test('is fresh right after the backend accepts a fix', () async {
      client.stub(ApiConfig.recordLocation, ok);
      await service.start();

      expect(service.isStale, isFalse);
    });

    test('is stale when the backend never accepted a fix', () async {
      client.stub(
        ApiConfig.recordLocation,
        const Response(statusCode: 500, body: {'message': 'nope'}),
      );
      await service.start();

      expect(
        service.isStale,
        isTrue,
        reason: 'reporting locally is not the same as the backend knowing',
      );
    });
  });

  test('stop() halts reporting; further movement is not sent', () async {
    client.stub(ApiConfig.recordLocation, ok, times: 5);
    await service.start();
    final sentWhileOnline = client.calls.length;

    await service.stop();
    provider.controller.add(positionAt(lat: 41.0));
    await Future<void>.delayed(Duration.zero);

    expect(service.isReporting.value, isFalse);
    expect(client.calls, hasLength(sentWhileOnline));
  });

  test('reset() wipes the previous driver position from the device', () async {
    client.stub(ApiConfig.recordLocation, ok, times: 5);
    await service.start();
    expect(service.lastLatitude.value, isNotNull);

    await service.reset();

    expect(service.isReporting.value, isFalse);
    expect(service.lastLatitude.value, isNull);
    expect(service.lastLongitude.value, isNull);
    expect(service.lastAcceptedAt.value, isNull);
    expect(service.permissionState.value, isNull);
  });
}
