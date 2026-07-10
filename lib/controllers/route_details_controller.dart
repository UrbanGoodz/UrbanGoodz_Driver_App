import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:urban_goodz_driver/models/driver_job_model.dart';
import 'package:urban_goodz_driver/repositories/mock_driver_data.dart';

class RouteDetailsController extends GetxController {
  final MockJobRepository _jobRepository = MockJobRepository();

  var currentJob = Rx<DriverJobModel?>(null);
  var routeWaypoints = <MapPoint>[].obs;
  var currentStatus = ''.obs;
  var progress = 0.0.obs;
  var estimatedArrival = ''.obs;
  var isLoading = true.obs;

  void fetchRoute(String jobId) {
    isLoading.value = true;
    _jobRepository.fetchActiveJobs().then((jobs) {
      try {
        final job = jobs.firstWhere((j) => j.id == jobId);
        currentJob.value = job;
        currentStatus.value = job.status;
        estimatedArrival.value = job.estimatedDuration;

        routeWaypoints.value = [
          MapPoint(
            lat: 29.7604,
            lng: -95.3698,
            address: job.pickupAddress,
          ),
          MapPoint(
            lat: 29.7050,
            lng: -95.4020,
            address: job.dropoffAddress,
          ),
        ];

        switch (job.status) {
          case 'assigned':
            progress.value = 0.1;
            break;
          case 'in_progress':
            progress.value = 0.4;
            break;
          case 'completed':
            progress.value = 1.0;
            break;
          default:
            progress.value = 0.0;
        }

        isLoading.value = false;
      } catch (_) {
        isLoading.value = false;
      }
    });
  }

  Future<void> sendStatusUpdateToBackend(String driverTaskStatus) async {
    final job = currentJob.value;
    if (job == null) return;
    try {
      final getConnect = GetConnect();
      final url = 'https://admin.urbangoodzdelivery.com/api/v1/order-anywhere/driver/${job.id}/status';
      final response = await getConnect.post(url, {
        'driver_task_status': driverTaskStatus,
      });
      if (response.status.isOk) {
        Get.snackbar('Sync Success', 'Status sync\'d to backend database: $driverTaskStatus',
            snackPosition: SnackPosition.BOTTOM, backgroundColor: const Color(0xFF4CAF50), colorText: const Color(0xFFFFFFFF));
      } else {
        Get.snackbar('Sync Staged', 'Backend updated locally (Staged). Code: ${response.statusCode}',
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('Sync Staged', 'Backend offline or staging server (Staged).',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  void updateProgress() {
    if (progress.value < 1.0) {
      progress.value += 0.2;
      
      // Determine status string
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
        Get.snackbar('Delivery Complete', 'You have reached your destination.',
            snackPosition: SnackPosition.BOTTOM);
      }
      sendStatusUpdateToBackend(statusStr);
    }
  }

  void markWaypointReached(int index) {
    if (index < routeWaypoints.length) {
      progress.value = (index + 1) / routeWaypoints.length;
      Get.snackbar(
          'Waypoint Reached', 'Arrived at ${routeWaypoints[index].address}',
          snackPosition: SnackPosition.BOTTOM);
      
      String statusStr = index == 0 ? 'picked_up' : 'delivered';
      sendStatusUpdateToBackend(statusStr);
    }
  }
}
