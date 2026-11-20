import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:urban_goodz_driver/models/dedicated_route_model.dart';
import 'package:urban_goodz_driver/services/api_client.dart';
import 'package:urban_goodz_driver/services/driver_api_service.dart';
import 'package:urban_goodz_driver/utils/json_number.dart';

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
        backgroundColor: backgroundColor ?? Colors.black.withValues(alpha: 0.8),
        colorText: colorText ?? Colors.white,
        // Passing a bare `duration: null` through to GetX disables
        // auto-dismiss entirely, so every call site that didn't specify one
        // (e.g. "Sync Complete") stayed on screen indefinitely, stacking up
        // and blocking taps on whatever was underneath it.
        duration: duration ?? const Duration(seconds: 3),
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
      'status': 'pending',
    });
    await _saveOfflineQueue();
    _showSnackbar(
      'Offline Mode',
      'Action saved locally. It will sync when online.',
      backgroundColor: Colors.orange.withValues(alpha: 0.9),
      colorText: Colors.white,
    );
  }

  /// Actions the server rejected outright (4xx) and that need the driver's
  /// attention before they can go anywhere — never auto-retried, since
  /// retrying the exact same request would just fail the same way again.
  List<Map<String, dynamic>> get needsAttentionActions =>
      pendingActions.where((a) => a['status'] == 'needs_attention').toList();

  int get needsAttentionCount => needsAttentionActions.length;

  /// Runs one queued action and returns the raw result so both the
  /// automatic sync loop and a manual "Fix and retry" can share the same
  /// dispatch + classification logic instead of duplicating it.
  ///
  /// On success: returns null and (for dropoff) deletes the queued proof
  /// files, since the server now has its own copies.
  /// On failure: returns the updated action map — unchanged (still
  /// retryable) for a network/5xx failure, or stamped `needs_attention`
  /// with the server's message for a 4xx rejection.
  Future<Map<String, dynamic>?> _runQueuedAction(Map<String, dynamic> action) async {
    final type = action['type'];
    final data = action['data'] as Map<String, dynamic>;
    // Queued offline actions are round-tripped through JSON in shared
    // preferences, so route_id can come back as a string. A throw here
    // would abort the whole sync loop and strand every queued scan, not
    // just this one.
    final routeId = jsonInt(data['route_id']);

    try {
      if (type == 'pickup') {
        await _api.scanPickup(
          routeId,
          barcode: data['barcode'],
          lat: data['lat'],
          lng: data['lng'],
        );
      } else if (type == 'dropoff') {
        final photoPath = data['photo_path'] as String?;
        final signaturePath = data['signature_path'] as String?;
        await _api.scanDropoff(
          routeId,
          barcode: data['barcode'],
          lat: data['lat'],
          lng: data['lng'],
          photoFile: (photoPath != null && File(photoPath).existsSync()) ? File(photoPath) : null,
          signatureFile: (signaturePath != null && File(signaturePath).existsSync()) ? File(signaturePath) : null,
        );
        // Upload succeeded: the queued copies are no longer needed.
        await _deleteIfExists(photoPath);
        await _deleteIfExists(signaturePath);
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
      return null;
    } catch (e) {
      if (e is! ApiException || !e.isClientError) {
        // Connectivity failure (or anything we can't classify): keep the
        // action, and its files, queued for the next automatic retry.
        return action;
      }
      // The backend rejected this one outright — e.g. Release 8's required-
      // proof 422. Retrying automatically later would fail identically
      // forever and the package would silently stay undelivered, so this
      // is flagged for the driver to review instead of being dropped.
      return {
        ...action,
        'status': 'needs_attention',
        'last_error': e.message,
      };
    }
  }

  Future<void> syncOfflineActions() async {
    if (pendingActions.isEmpty || isSyncing.value) return;
    isSyncing.value = true;
    errorMessage.value = '';

    List<Map<String, dynamic>> stillQueued = [];

    for (var action in pendingActions) {
      // Items already flagged for driver review are not retried
      // automatically — only "Fix and retry" or "Discard" touches them.
      if (action['status'] == 'needs_attention') {
        stillQueued.add(action);
        continue;
      }
      final result = await _runQueuedAction(action);
      if (result != null) stillQueued.add(result);
    }

    pendingActions.value = stillQueued;
    await _saveOfflineQueue();
    isSyncing.value = false;

    final attentionCount = stillQueued.where((a) => a['status'] == 'needs_attention').length;
    final stillRetrying = stillQueued.length - attentionCount;

    if (stillQueued.isEmpty) {
      _showSnackbar(
        'Sync Complete',
        'All offline scans and updates synchronized successfully!',
        backgroundColor: Colors.green.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
      if (currentRoute.value != null) {
        fetchRouteDetail(currentRoute.value!.id);
      }
    } else if (attentionCount > 0) {
      _showSnackbar(
        'Action Needed',
        '$attentionCount action${attentionCount == 1 ? '' : 's'} could not be sent and need your review.',
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } else {
      _showSnackbar(
        'Sync Incomplete',
        'Failed to sync $stillRetrying items. Will retry later.',
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    }
  }

  /// Re-sends one flagged action as-is (pickup/exception/start/complete —
  /// nothing to re-capture). Returns true on success.
  Future<bool> retrySimpleAction(Map<String, dynamic> action) async {
    final result = await _runQueuedAction(action);
    if (result == null) {
      pendingActions.removeWhere((a) => identical(a, action) || a['timestamp'] == action['timestamp']);
      await _saveOfflineQueue();
      if (currentRoute.value != null) fetchRouteDetail(currentRoute.value!.id);
      return true;
    }
    final idx = pendingActions.indexWhere((a) => a['timestamp'] == action['timestamp']);
    if (idx != -1) pendingActions[idx] = result;
    await _saveOfflineQueue();
    return false;
  }

  /// Re-sends a flagged dropoff with freshly captured proof. Returns true on
  /// success.
  Future<bool> retryDropoffWithNewProof(
    Map<String, dynamic> action, {
    File? photoFile,
    File? signatureFile,
  }) async {
    final data = Map<String, dynamic>.from(action['data'] as Map<String, dynamic>);
    // The old queued files (if any) are superseded by whatever was just
    // captured; stop tracking them so a later cleanup pass doesn't trip
    // over a path that's about to be orphaned.
    final oldPhotoPath = data['photo_path'] as String?;
    final oldSignaturePath = data['signature_path'] as String?;
    data['photo_path'] = photoFile?.path ?? oldPhotoPath;
    data['signature_path'] = signatureFile?.path ?? oldSignaturePath;

    final retryAction = {...action, 'data': data, 'status': 'pending'};
    final result = await _runQueuedAction(retryAction);

    if (result == null) {
      if (photoFile != null) await _deleteIfExists(oldPhotoPath);
      if (signatureFile != null) await _deleteIfExists(oldSignaturePath);
      pendingActions.removeWhere((a) => a['timestamp'] == action['timestamp']);
      await _saveOfflineQueue();
      if (currentRoute.value != null) fetchRouteDetail(currentRoute.value!.id);
      return true;
    }
    final idx = pendingActions.indexWhere((a) => a['timestamp'] == action['timestamp']);
    if (idx != -1) pendingActions[idx] = result;
    await _saveOfflineQueue();
    return false;
  }

  /// Permanently removes a flagged action without sending it. Reverts the
  /// package's optimistic local status so the manifest screen shows it
  /// still needs action, rather than claiming it was delivered/picked up
  /// when the server never actually received that.
  Future<void> discardOfflineAction(Map<String, dynamic> action) async {
    final type = action['type'];
    final data = action['data'] as Map<String, dynamic>;
    final barcode = data['barcode'] as String?;

    if (barcode != null) {
      if (type == 'dropoff') {
        _updatePackageStatusLocally(barcode, 'arrived');
      } else if (type == 'pickup') {
        _updatePackageStatusLocally(barcode, 'pending');
      } else if (type == 'exception') {
        _updatePackageStatusLocally(barcode, 'arrived');
      }
    }

    await _deleteIfExists(data['photo_path'] as String?);
    await _deleteIfExists(data['signature_path'] as String?);
    pendingActions.removeWhere((a) => a['timestamp'] == action['timestamp']);
    await _saveOfflineQueue();
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

  /// Set where the run ends and re-sort the stops behind it.
  ///
  /// Returns the finish label the server actually resolved, so the caller can
  /// show the driver what their typing matched - "Downing Street, Houston"
  /// for "10 Downing Street, London" is a correct bounded match, but only if
  /// the driver gets to see it.
  Future<String?> setRouteFinish(
    int routeId, {
    required String mode,
    String? endAddress,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final res = await _api.setRouteFinish(
        routeId,
        mode: mode,
        endAddress: endAddress,
      );
      await fetchRouteDetail(routeId);

      final label = (res['route'] is Map) ? res['route']['finish_label'] as String? : null;

      _showSnackbar(
        'Finish Set',
        switch (mode) {
          'hub' => 'Stops re-sorted to end back at the pickup hub.',
          'open' => 'Stops re-sorted with no fixed finish.',
          _ => label == null
              ? 'Stops re-sorted to end at your chosen address.'
              : 'Ending at $label',
        },
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      return label;
    } catch (e) {
      errorMessage.value = e.toString();
      _showSnackbar(
        'Could Not Set Finish',
        e.toString(),
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
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

  Future<void> recordLoadingScan(int routeId, String barcode, {String inputMethod = 'manual'}) async {
    final lat = currentRoute.value?.pickupLat ?? 0.0;
    final lng = currentRoute.value?.pickupLng ?? 0.0;

    _updatePackageStatusLocally(barcode, 'picked_up');

    if (isOffline.value) {
      await queueOfflineAction('pickup', {
        'route_id': routeId,
        'barcode': barcode,
        'lat': lat,
        'lng': lng,
        'input_method': inputMethod,
      });
      return;
    }

    try {
      await _api.scanPickup(routeId, barcode: barcode, lat: lat, lng: lng, inputMethod: inputMethod);
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

  /// [photoFile]/[signatureFile] are the real captured camera photo and
  /// drawn signature — never placeholder strings. Throws [ApiException] when
  /// the backend rejects the request outright (e.g. the package still
  /// requires proof that wasn't provided): that case is surfaced to the
  /// caller rather than silently queued offline, since retrying later would
  /// fail identically every time.
  Future<void> recordDeliveryDropoff(
    int routeId,
    String barcode, {
    File? photoFile,
    File? signatureFile,
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

    if (isOffline.value) {
      _updatePackageStatusLocally(barcode, 'delivered');
      await queueOfflineAction('dropoff', {
        'route_id': routeId,
        'barcode': barcode,
        'lat': lat,
        'lng': lng,
        'photo_path': photoFile?.path,
        'signature_path': signatureFile?.path,
      });
      return;
    }

    try {
      await _api.scanDropoff(
        routeId,
        barcode: barcode,
        lat: lat,
        lng: lng,
        photoFile: photoFile,
        signatureFile: signatureFile,
      );
      _updatePackageStatusLocally(barcode, 'delivered');
      await _deleteIfExists(photoFile?.path);
      await _deleteIfExists(signatureFile?.path);
      await fetchRouteDetail(routeId);
    } on ApiException catch (e) {
      if (e.isClientError) rethrow;
      _updatePackageStatusLocally(barcode, 'delivered');
      await queueOfflineAction('dropoff', {
        'route_id': routeId,
        'barcode': barcode,
        'lat': lat,
        'lng': lng,
        'photo_path': photoFile?.path,
        'signature_path': signatureFile?.path,
      });
    } catch (e) {
      _updatePackageStatusLocally(barcode, 'delivered');
      await queueOfflineAction('dropoff', {
        'route_id': routeId,
        'barcode': barcode,
        'lat': lat,
        'lng': lng,
        'photo_path': photoFile?.path,
        'signature_path': signatureFile?.path,
      });
    }
  }

  Future<void> _deleteIfExists(String? path) async {
    if (path == null) return;
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
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
            requiresPhoto: pkg.requiresPhoto,
            requiresSignature: pkg.requiresSignature,
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
