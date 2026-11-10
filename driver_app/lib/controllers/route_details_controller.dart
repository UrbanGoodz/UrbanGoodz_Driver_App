import 'package:flutter/material.dart';
import 'package:urban_goodz_driver/theme/app_theme.dart';
import 'package:get/get.dart';
import 'package:urban_goodz_driver/models/driver_job_model.dart';
import 'package:urban_goodz_driver/services/driver_api_service.dart';

class RouteWaypoint {
  final double lat;
  final double lng;
  final String address;
  const RouteWaypoint({
    required this.lat,
    required this.lng,
    required this.address,
  });
}

class RouteDetailsController extends GetxController {
  DriverApiService get _api => Get.find<DriverApiService>();

  var currentJob = Rx<DriverJobModel?>(null);
  var routeWaypoints = <RouteWaypoint>[].obs;
  var currentStatus = ''.obs;
  var progress = 0.0.obs;
  var estimatedArrival = ''.obs;
  var isLoading = true.obs;
  var errorMessage = ''.obs;

  void fetchRoute(String jobId, {String? source}) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final jobIdInt = int.tryParse(jobId);
      if (jobIdInt == null) {
        isLoading.value = false;
        return;
      }
      final jobData = await _api.getActiveJobDetail(jobIdInt, source: source);
      final job = DriverJobModel.fromJson(jobData);
      currentJob.value = job;
      currentStatus.value = job.status;
      estimatedArrival.value = job.estimatedDuration;

      if (job.hasCoordinates) {
        routeWaypoints.value = [
          RouteWaypoint(
            lat: job.pickupLatitude!,
            lng: job.pickupLongitude!,
            address: job.pickupAddress,
          ),
          RouteWaypoint(
            lat: job.dropoffLatitude!,
            lng: job.dropoffLongitude!,
            address: job.dropoffAddress,
          ),
        ];
      } else {
        routeWaypoints.value = [
          RouteWaypoint(lat: 0, lng: 0, address: job.pickupAddress),
          RouteWaypoint(lat: 0, lng: 0, address: job.dropoffAddress),
        ];
      }

      switch (job.status) {
        case 'assigned':
        case 'accepted':
          progress.value = 0.1;
          break;
        case 'in_progress':
        case 'shopping':
          progress.value = 0.4;
          break;
        case 'picked_up':
          progress.value = 0.6;
          break;
        case 'out_for_delivery':
          progress.value = 0.8;
          break;
        case 'completed':
        case 'delivered':
          progress.value = 1.0;
          break;
        default:
          progress.value = 0.0;
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> sendStatusUpdateToBackend(String driverTaskStatus) async {
    final job = currentJob.value;
    if (job == null) return;
    try {
      final jobId = int.tryParse(job.id);
      if (jobId == null) return;
      await _api.updateActiveJobStatus(
        jobId,
        driverTaskStatus,
        source: job.source,
      );
      Get.snackbar(
        'Synced',
        'Status updated: $driverTaskStatus',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.primary,
        colorText: const Color(0xFFFFFFFF),
      );
    } catch (e) {
      Get.snackbar(
        'Sync Failed',
        'Backend update failed: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void updateProgress() {
    if (progress.value < 1.0) {
      progress.value += 0.2;

      String statusStr = 'shopping';
      if (progress.value >= 0.7) {
        statusStr = 'en_route';
      } else if (progress.value >= 0.5) {
        statusStr = 'picked_up';
      }

      if (progress.value >= 1.0) {
        progress.value = 1.0;
        currentStatus.value = 'delivered';
        statusStr = 'delivered';
        Get.snackbar(
          'Delivery Complete',
          'You have reached your destination.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      sendStatusUpdateToBackend(statusStr);
    }
  }

  void markWaypointReached(int index) {
    if (index < routeWaypoints.length) {
      progress.value = (index + 1) / routeWaypoints.length;
      Get.snackbar(
        'Waypoint Reached',
        'Arrived at ${routeWaypoints[index].address}',
        snackPosition: SnackPosition.BOTTOM,
      );

      String statusStr = index == 0 ? 'picked_up' : 'delivered';
      sendStatusUpdateToBackend(statusStr);
    }
  }
}
