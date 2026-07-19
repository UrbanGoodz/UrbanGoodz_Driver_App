import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:urban_goodz_driver/controllers/dedicated_route_controller.dart';
import 'package:urban_goodz_driver/models/dedicated_route_model.dart';
import 'package:urban_goodz_driver/services/api_client.dart';
import 'package:urban_goodz_driver/services/driver_api_service.dart';

// A faked/mocked API service for the test suite
class FakeDriverApiService extends DriverApiService {
  bool getAssignedRoutesCalled = false;
  bool getRouteDetailCalled = false;
  bool resequenceRouteCalled = false;
  bool startRouteCalled = false;
  bool completeRouteCalled = false;
  bool scanPickupCalled = false;
  bool scanDropoffCalled = false;
  bool scanExceptionCalled = false;

  @override
  Future<List<dynamic>> getAssignedRoutes() async {
    getAssignedRoutesCalled = true;
    return [
      {
        'id': 101,
        'route_name': 'A',
        'route_type': 'bulk_delivery',
        'pickup_location': 'Pickup Hub East',
        'pickup_lat': 29.7600000,
        'pickup_lng': -95.3600000,
        'status': 'planned',
        'total_packages': 2,
        'completed_packages': 0,
        'failed_packages': 0,
        'driver_pay_per_package': 10.0,
        'instant_payout_allowed': true,
        'weekly_payout_allowed': true,
        'vehicle_type_required': 'cargo_van',
      }
    ];
  }

  @override
  Future<Map<String, dynamic>> getRouteDetail(int routeId) async {
    getRouteDetailCalled = true;
    if (routeId == 404) {
      throw Exception('Network Exception');
    }
    return {
      'route': {
        'id': 101,
        'route_name': 'A',
        'route_type': 'bulk_delivery',
        'pickup_location': 'Pickup Hub East',
        'pickup_lat': 29.7600000,
        'pickup_lng': -95.3600000,
        'status': 'planned',
        'total_packages': 2,
        'completed_packages': 0,
        'failed_packages': 0,
        'driver_pay_per_package': 10.0,
        'instant_payout_allowed': true,
        'weekly_payout_allowed': true,
        'vehicle_type_required': 'cargo_van',
      },
      'stops': [
        {
          'package_id': 1001,
          'tracking_id': 'TRK-1001',
          'barcode': 'BAR-1001',
          'dropoff_name': 'Alice Smith',
          'dropoff_address': '123 Main St',
          'dropoff_lat': 29.7700000,
          'dropoff_lng': -95.3700000,
          'status': 'pending',
          'age_restricted': false,
          'requires_id_verification': false,
          'no_contactless_delivery': false,
          'delivery_completion_locked_until_verified': true, // Locked stop order 1
          'stop_order': 1,
        },
        {
          'package_id': 1002,
          'tracking_id': 'TRK-1002',
          'barcode': 'BAR-1002',
          'dropoff_name': 'Bob Jones',
          'dropoff_address': '123 Main St', // Consolidated stop
          'dropoff_lat': 29.7700000,
          'dropoff_lng': -95.3700000,
          'status': 'pending',
          'age_restricted': false,
          'requires_id_verification': false,
          'no_contactless_delivery': false,
          'delivery_completion_locked_until_verified': false,
          'stop_order': 1,
        }
      ]
    };
  }

  @override
  Future<Map<String, dynamic>> resequenceRoute(int routeId, String endpointType) async {
    resequenceRouteCalled = true;
    return {'requires_approval': false};
  }

  @override
  Future<Map<String, dynamic>> startRoute(int routeId) async {
    startRouteCalled = true;
    return {'status': 'started'};
  }

  @override
  Future<Map<String, dynamic>> completeRoute(int routeId) async {
    completeRouteCalled = true;
    return {'status': 'completed'};
  }

  @override
  Future<Map<String, dynamic>> scanPickup(int routeId, {required String barcode, required double lat, required double lng}) async {
    scanPickupCalled = true;
    return {'status': 'picked_up'};
  }

  @override
  Future<Map<String, dynamic>> scanDropoff(int routeId, {required String barcode, required double lat, required double lng, String? proofPhoto, String? signature}) async {
    scanDropoffCalled = true;
    return {'status': 'delivered'};
  }

  @override
  Future<Map<String, dynamic>> scanException(int routeId, {required String barcode, required String reason}) async {
    scanExceptionCalled = true;
    return {'status': 'failed'};
  }
}

void main() {
  late FakeDriverApiService fakeApi;
  late DedicatedRouteController controller;

  setUp(() {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
    
    // Inject ApiClient & FakeDriverApiService
    Get.put(ApiClient());
    fakeApi = FakeDriverApiService();
    Get.put<DriverApiService>(fakeApi);
    
    controller = Get.put(DedicatedRouteController());
  });

  tearDown(() {
    Get.reset();
  });

  group('Dedicated Route Models Serialization', () {
    test('DedicatedRouteModel parses correctly from json', () {
      final json = {
        'id': 101,
        'route_name': 'A',
        'route_type': 'bulk_delivery',
        'pickup_location': 'Pickup Hub East',
        'pickup_lat': 29.76,
        'pickup_lng': -95.36,
        'status': 'planned',
        'total_packages': 10,
        'completed_packages': 2,
        'failed_packages': 1,
        'driver_pay_per_package': 12.5,
        'instant_payout_allowed': 1,
        'weekly_payout_allowed': true,
        'vehicle_type_required': 'cargo_van',
      };

      final model = DedicatedRouteModel.fromJson(json);
      expect(model.id, 101);
      expect(model.routeName, 'A');
      expect(model.pickupLat, 29.76);
      expect(model.instantPayoutAllowed, true);
      expect(model.weeklyPayoutAllowed, true);
      expect(model.driverPayPerPackage, 12.5);
    });

    test('RoutePackageModel parses correctly from json', () {
      final json = {
        'package_id': 1001,
        'tracking_id': 'TRK-1001',
        'barcode': 'BAR-1001',
        'dropoff_name': 'Alice Smith',
        'dropoff_address': '123 Main St',
        'dropoff_lat': 29.77,
        'dropoff_lng': -95.37,
        'status': 'pending',
        'age_restricted': 0,
        'requires_id_verification': 1,
        'no_contactless_delivery': true,
        'delivery_completion_locked_until_verified': true,
        'stop_order': 2,
      };

      final pkg = RoutePackageModel.fromJson(json);
      expect(pkg.id, 1001);
      expect(pkg.trackingId, 'TRK-1001');
      expect(pkg.requiresIdVerification, true);
      expect(pkg.noContactlessDelivery, true);
      expect(pkg.deliveryCompletionLockedUntilVerified, true);
      expect(pkg.stopOrder, 2);
    });
  });

  group('DedicatedRouteController Actions & Workflow State', () {
    test('fetchAssignedRoutes successfully fetches and caches routes list', () async {
      await controller.fetchAssignedRoutes();

      expect(fakeApi.getAssignedRoutesCalled, true);
      expect(controller.assignedRoutes.length, 1);
      expect(controller.assignedRoutes.first.id, 101);
      expect(controller.isOffline.value, false);

      // Verify cached correctly
      final prefs = await SharedPreferences.getInstance();
      final cacheStr = prefs.getString('dedicated_routes_list_cache');
      expect(cacheStr, isNotNull);
      expect(json.decode(cacheStr!)[0]['id'], 101);
    });

    test('fetchRouteDetail dynamically parses and groups consolidated stops', () async {
      await controller.fetchRouteDetail(101);

      expect(fakeApi.getRouteDetailCalled, true);
      expect(controller.currentRoute.value, isNotNull);
      expect(controller.currentRoute.value!.id, 101);

      // Assert stops grouping (two packages consolidated at the same address / stop order 1)
      expect(controller.stops.length, 1);
      final stop = controller.stops.first;
      expect(stop.stopOrder, 1);
      expect(stop.packages.length, 2);
      expect(stop.isLocked, true); // Since package 1001 requires verification lock
    });

    test('offline mode loads route detail from shared preferences cache fallback', () async {
      // Setup local cache manually in fake SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'route': {
          'id': 404,
          'route_name': 'B',
          'pickup_location': 'Pickup Hub West',
          'status': 'planned',
        },
        'stops': []
      };
      await prefs.setString('dedicated_route_detail_cache_404', json.encode(cacheData));

      // Fetch detail, should read cache successfully because 404 throws network exception
      await controller.fetchRouteDetail(404);

      expect(controller.isOffline.value, true);
      expect(controller.currentRoute.value, isNotNull);
      expect(controller.currentRoute.value!.id, 404);
      expect(controller.currentRoute.value!.routeName, 'B');
    });

    test('offline action queuing and optimistic UI updates', () async {
      // 1. Setup route with stop and pending package
      await controller.fetchRouteDetail(101);
      controller.isOffline.value = true; // Switch to offline

      // 2. Perform loading scan offline
      await controller.recordLoadingScan(101, 'BAR-1001');

      // 3. Verify optimistic status update (package status changes immediately)
      final stop = controller.stops.first;
      final pkg = stop.packages.firstWhere((p) => p.barcode == 'BAR-1001');
      expect(pkg.status, 'picked_up');

      // 4. Verify action queued to storage
      expect(controller.pendingActions.length, 1);
      expect(controller.pendingActions.first['type'], 'pickup');
      expect(controller.pendingActions.first['data']['barcode'], 'BAR-1001');
    });

    test('syncOfflineActions flushes local queued events to backend', () async {
      // Fetch route details online first to populate stops
      await controller.fetchRouteDetail(101);
      controller.isOffline.value = true;

      // Queue an offline pickup scan and an offline dropoff delivery
      await controller.recordLoadingScan(101, 'BAR-1001');
      await controller.recordDeliveryDropoff(101, 'BAR-1002', proofPhoto: '/images/a.png', signature: 'Jane');

      expect(controller.pendingActions.length, 2);

      // Restore online and run sync
      controller.isOffline.value = false;
      await controller.syncOfflineActions();

      // Verify queued actions successfully syncd and queue cleared
      expect(controller.pendingActions.length, 0);
      expect(fakeApi.scanPickupCalled, true);
      expect(fakeApi.scanDropoffCalled, true);
    });
  });
}
