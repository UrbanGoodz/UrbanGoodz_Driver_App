import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:urban_goodz_driver/models/dedicated_route_model.dart';
import 'package:urban_goodz_driver/services/driver_api_service.dart';

class DedicatedRouteController extends GetxController {
  final DriverApiService _api = Get.find<DriverApiService>();

  var assignedRoutes = <DedicatedRouteModel>[].obs;
  var currentRoute = Rxn<DedicatedRouteModel>();
  var stops = <RouteStopModel>[].obs;

  var isLoading = false.obs;
  var isSyncing = false.obs;
  var isOffline = false.obs;
  var errorMessage = ''.obs;

  var pendingActions = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadOfflineQueue();
  }

  void _showSnackbar(String title, String message, {Color? backgroundColor, Color? colorText, Duration? duration}) {
    if (!Get.testMode) {
      Get.snackbar(
        title,
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: backgroundColor ?? Colors.black.withOpacity(0.8),
        colorText: colorText ?? Colors.white,
        duration: duration,
      );
    }
  }

  // ---------- Offline Cache & Queue ----------

  Future<void> _loadOfflineQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('dedicated_routes_offline_queue');
      if (saved != null) {
        final decoded = json.decode(saved) as List;
        pendingActions.value = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
  }

  Future<void> _saveOfflineQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('dedicated_routes_offline_queue', json.encode(pendingActions));
    } catch (_) {}
  }

  Future<void> queueOfflineAction(String type, Map<String, dynamic> data) async {
    pendingActions.add({
      'type': type,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });
    await _saveOfflineQueue();
    _showSnackbar(
      'Offline Mode',
      'Action saved locally. It will sync when online.',
      backgroundColor: Colors.orange.withOpacity(0.9),
      colorText: Colors.white,
    );
  }

  Future<void> syncOfflineActions() async {
    if (pendingActions.isEmpty || isSyncing.value) return;
    isSyncing.value = true;
    errorMessage.value = '';

    List<Map<String, dynamic>> failed = [];

    for (var action in pendingActions) {
      final type = action['type'];
      final data = action['data'] as Map<String, dynamic>;
      final routeId = data['route_id'] as int;

      try {
        if (type == 'pickup') {
          await _api.scanPickup(
            routeId,
            barcode: data['barcode'],
            lat: data['lat'],
            lng: data['lng'],
          );
        } else if (type == 'dropoff') {
          await _api.scanDropoff(
            routeId,
            barcode: data['barcode'],
            lat: data['lat'],
            lng: data['lng'],
            proofPhoto: data['proof_photo'],
            signature: data['signature'],
          );
        } else if (type == 'exception') {
          await _api.scanException(
            routeId,
            barcode: data['barcode'],
            reason: data['reason'],
          );
        } else if (type == 'start') {
          await _api.startRoute(routeId);
        } else if (type == 'complete') {
          await _api.completeRoute(routeId);
        }
      } catch (e) {
        if (e.toString().contains('SocketException') || e.toString().contains('Request failed')) {
          failed.add(action);
        }
      }
    }

    pendingActions.value = failed;
    await _saveOfflineQueue();
    isSyncing.value = false;

    if (failed.isEmpty) {
      _showSnackbar(
        'Sync Complete',
        'All offline scans and updates synchronized successfully!',
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
      );
      if (currentRoute.value != null) {
        fetchRouteDetail(currentRoute.value!.id);
      }
    } else {
      _showSnackbar(
        'Sync Incomplete',
        'Failed to sync ${failed.length} items. Will retry later.',
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
      );
    }
  }

  // ---------- Fetch Operations ----------

  Future<void> fetchAssignedRoutes() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final raw = await _api.getAssignedRoutes();
      assignedRoutes.value = raw.map((e) => DedicatedRouteModel.fromJson(e)).toList();
      isOffline.value = false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('dedicated_routes_list_cache', json.encode(raw));
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('dedicated_routes_list_cache');
      if (cached != null) {
        final decoded = json.decode(cached) as List;
        assignedRoutes.value = decoded.map((e) => DedicatedRouteModel.fromJson(e)).toList();
        isOffline.value = true;
      } else {
        errorMessage.value = e.toString();
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchRouteDetail(int routeId) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final detail = await _api.getRouteDetail(routeId);
      _parseDetailResponse(detail);
      isOffline.value = false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('dedicated_route_detail_cache_$routeId', json.encode(detail));
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('dedicated_route_detail_cache_$routeId');
      if (cached != null) {
        final decoded = json.decode(cached) as Map<String, dynamic>;
        _parseDetailResponse(decoded);
        isOffline.value = true;
      } else {
        errorMessage.value = e.toString();
      }
    } finally {
      isLoading.value = false;
    }
  }

  void _parseDetailResponse(Map<String, dynamic> jsonResponse) {
    if (jsonResponse['route'] == null) return;
    currentRoute.value = DedicatedRouteModel.fromJson(jsonResponse['route']);

    final rawStops = jsonResponse['stops'] as List? ?? [];
    final parsedPackages = rawStops.map((e) => RoutePackageModel.fromJson(e)).toList();

    Map<int, List<RoutePackageModel>> grouped = {};
    for (var pkg in parsedPackages) {
      grouped.putIfAbsent(pkg.stopOrder, () => []).add(pkg);
    }

    stops.value = grouped.entries.map((e) {
      final firstPkg = e.value.first;
      return RouteStopModel(
        stopOrder: e.key,
        address: firstPkg.dropoffAddress,
        lat: firstPkg.dropoffLat,
        lng: firstPkg.dropoffLng,
        packages: e.value,
      );
    }).toList();

    stops.sort((a, b) => a.stopOrder.compareTo(b.stopOrder));
  }

  // ---------- Route Resequencing & Lifecycle ----------

  Future<void> resequenceRoute(int routeId, String endpointPreference) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final res = await _api.resequenceRoute(routeId, endpointPreference);
      await fetchRouteDetail(routeId);

      final reqApproval = res['requires_approval'] == true;
      if (reqApproval) {
        _showSnackbar(
          'Dispatcher Review Required',
          'Route sequence updated but pending dispatcher review due to excessive variance.',
          duration: const Duration(seconds: 5),
          backgroundColor: Colors.amber.shade700,
          colorText: Colors.white,
        );
      } else {
        _showSnackbar(
          'Route Resequenced',
          'Sequence optimized successfully!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      errorMessage.value = e.toString();
      _showSnackbar(
        'Resequencing Failed',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> startActiveRoute(int routeId) async {
    if (isOffline.value) {
      await queueOfflineAction('start', {'route_id': routeId});
      if (currentRoute.value != null) {
        currentRoute.value = DedicatedRouteModel.fromJson({
          ...currentRoute.value!.toJson(),
          'status': 'started',
        });
      }
      return;
    }

    isLoading.value = true;
    try {
      await _api.startRoute(routeId);
      await fetchRouteDetail(routeId);
    } catch (e) {
      _showSnackbar('Error starting route', e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> completeActiveRoute(int routeId) async {
    if (isOffline.value) {
      await queueOfflineAction('complete', {'route_id': routeId});
      if (currentRoute.value != null) {
        currentRoute.value = DedicatedRouteModel.fromJson({
          ...currentRoute.value!.toJson(),
          'status': 'completed',
        });
      }
      return;
    }

    isLoading.value = true;
    try {
      await _api.completeRoute(routeId);
      await fetchRouteDetail(routeId);
    } catch (e) {
      _showSnackbar('Error completing route', e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // ---------- Stop Actions ----------

  Future<void> recordLoadingScan(int routeId, String barcode) async {
    final lat = currentRoute.value?.pickupLat ?? 0.0;
    final lng = currentRoute.value?.pickupLng ?? 0.0;

    _updatePackageStatusLocally(barcode, 'picked_up');

    if (isOffline.value) {
      await queueOfflineAction('pickup', {
        'route_id': routeId,
        'barcode': barcode,
        'lat': lat,
        'lng': lng,
      });
      return;
    }

    try {
      await _api.scanPickup(routeId, barcode: barcode, lat: lat, lng: lng);
      await fetchRouteDetail(routeId);
    } catch (e) {
      await queueOfflineAction('pickup', {
        'route_id': routeId,
        'barcode': barcode,
        'lat': lat,
        'lng': lng,
      });
    }
  }

  Future<void> recordDeliveryDropoff(
    int routeId,
    String barcode, {
    String? proofPhoto,
    String? signature,
  }) async {
    double lat = 0.0;
    double lng = 0.0;
    for (var stop in stops) {
      for (var pkg in stop.packages) {
        if (pkg.barcode == barcode) {
          lat = pkg.dropoffLat;
          lng = pkg.dropoffLng;
        }
      }
    }

    _updatePackageStatusLocally(barcode, 'delivered');

    if (isOffline.value) {
      await queueOfflineAction('dropoff', {
        'route_id': routeId,
        'barcode': barcode,
        'lat': lat,
        'lng': lng,
        'proof_photo': proofPhoto,
        'signature': signature,
      });
      return;
    }

    try {
      await _api.scanDropoff(
        routeId,
        barcode: barcode,
        lat: lat,
        lng: lng,
        proofPhoto: proofPhoto,
        signature: signature,
      );
      await fetchRouteDetail(routeId);
    } catch (e) {
      await queueOfflineAction('dropoff', {
        'route_id': routeId,
        'barcode': barcode,
        'lat': lat,
        'lng': lng,
        'proof_photo': proofPhoto,
        'signature': signature,
      });
    }
  }

  Future<void> recordDeliveryException(
    int routeId,
    String barcode,
    String reason,
  ) async {
    _updatePackageStatusLocally(barcode, 'failed', reason);

    if (isOffline.value) {
      await queueOfflineAction('exception', {
        'route_id': routeId,
        'barcode': barcode,
        'reason': reason,
      });
      return;
    }

    try {
      await _api.scanException(routeId, barcode: barcode, reason: reason);
      await fetchRouteDetail(routeId);
    } catch (e) {
      await queueOfflineAction('exception', {
        'route_id': routeId,
        'barcode': barcode,
        'reason': reason,
      });
    }
  }

  void updatePackageStatusLocally(String barcode, String status, [String? exceptionReason]) {
    _updatePackageStatusLocally(barcode, status, exceptionReason);
  }

  void _updatePackageStatusLocally(String barcode, String status, [String? exceptionReason]) {
    stops.value = stops.map((stop) {
      final updatedPackages = stop.packages.map((pkg) {
        if (pkg.barcode == barcode) {
          return RoutePackageModel(
            id: pkg.id,
            trackingId: pkg.trackingId,
            barcode: pkg.barcode,
            dropoffName: pkg.dropoffName,
            dropoffAddress: pkg.dropoffAddress,
            dropoffLat: pkg.dropoffLat,
            dropoffLng: pkg.dropoffLng,
            deliveryWindowStart: pkg.deliveryWindowStart,
            deliveryWindowEnd: pkg.deliveryWindowEnd,
            status: status,
            exceptionReason: exceptionReason ?? pkg.exceptionReason,
            ageRestricted: pkg.ageRestricted,
            requiresIdVerification: pkg.requiresIdVerification,
            noContactlessDelivery: pkg.noContactlessDelivery,
            deliveryCompletionLockedUntilVerified: pkg.deliveryCompletionLockedUntilVerified,
            ageVerificationStatus: pkg.ageVerificationStatus,
            stopOrder: pkg.stopOrder,
          );
        }
        return pkg;
      }).toList();

      return RouteStopModel(
        stopOrder: stop.stopOrder,
        address: stop.address,
        lat: stop.lat,
        lng: stop.lng,
        packages: updatedPackages,
      );
    }).toList();
  }
}
