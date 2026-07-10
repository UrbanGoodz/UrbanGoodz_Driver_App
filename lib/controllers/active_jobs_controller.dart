import 'package:get/get.dart';
import 'package:urban_goodz_driver/models/driver_job_model.dart';
import 'package:urban_goodz_driver/repositories/mock_driver_data.dart';

class ActiveJobsController extends GetxController {
  final MockJobRepository _repository = MockJobRepository();

  var activeJobs = <DriverJobModel>[].obs;
  var filteredJobs = <DriverJobModel>[].obs;
  var selectedFilter = 'all'.obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    fetchActiveJobs();
    super.onInit();
  }

  void fetchActiveJobs() {
    isLoading.value = true;
    _repository.fetchActiveJobs().then((jobs) {
      activeJobs.value = jobs;
      filterByType(selectedFilter.value);
      isLoading.value = false;
    });
  }

  void filterByType(String type) {
    selectedFilter.value = type;
    if (type == 'all') {
      filteredJobs.value = List.from(activeJobs);
    } else {
      filteredJobs.value =
          activeJobs.where((job) => job.type == type).toList();
    }
  }

  void acceptJob(String id) {
    _repository.fetchActiveJobs().then((jobs) {
      final idx = activeJobs.indexWhere((j) => j.id == id);
      if (idx != -1) {
        final updated = DriverJobModel(
          id: activeJobs[idx].id,
          type: activeJobs[idx].type,
          title: activeJobs[idx].title,
          description: activeJobs[idx].description,
          pickupAddress: activeJobs[idx].pickupAddress,
          dropoffAddress: activeJobs[idx].dropoffAddress,
          status: 'in_progress',
          earnings: activeJobs[idx].earnings,
          distance: activeJobs[idx].distance,
          estimatedDuration: activeJobs[idx].estimatedDuration,
          customerName: activeJobs[idx].customerName,
          customerPhone: activeJobs[idx].customerPhone,
          scheduledDate: activeJobs[idx].scheduledDate,
          scheduledTime: activeJobs[idx].scheduledTime,
          vehicleType: activeJobs[idx].vehicleType,
          isUrgent: activeJobs[idx].isUrgent,
          tags: activeJobs[idx].tags,
          specialRequirements: activeJobs[idx].specialRequirements,
        );
        activeJobs[idx] = updated;
        filterByType(selectedFilter.value);
      }
      Get.snackbar('Job Accepted', 'You are now working on this job.',
          snackPosition: SnackPosition.BOTTOM);
    });
  }

  void startJob(String id) {
    final idx = activeJobs.indexWhere((j) => j.id == id);
    if (idx != -1) {
      final updated = DriverJobModel(
        id: activeJobs[idx].id,
        type: activeJobs[idx].type,
        title: activeJobs[idx].title,
        description: activeJobs[idx].description,
        pickupAddress: activeJobs[idx].pickupAddress,
        dropoffAddress: activeJobs[idx].dropoffAddress,
        status: 'in_progress',
        earnings: activeJobs[idx].earnings,
        distance: activeJobs[idx].distance,
        estimatedDuration: activeJobs[idx].estimatedDuration,
        customerName: activeJobs[idx].customerName,
        customerPhone: activeJobs[idx].customerPhone,
        scheduledDate: activeJobs[idx].scheduledDate,
        scheduledTime: activeJobs[idx].scheduledTime,
        vehicleType: activeJobs[idx].vehicleType,
        isUrgent: activeJobs[idx].isUrgent,
        tags: activeJobs[idx].tags,
        specialRequirements: activeJobs[idx].specialRequirements,
      );
      activeJobs[idx] = updated;
      filterByType(selectedFilter.value);
      Get.snackbar('Job Started', 'Head to the pickup location.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  void completeJob(String id) {
    final idx = activeJobs.indexWhere((j) => j.id == id);
    if (idx != -1) {
      activeJobs.removeAt(idx);
      filterByType(selectedFilter.value);
      Get.snackbar('Job Completed', 'Great work! Earnings have been added.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  void cancelJob(String id) {
    final idx = activeJobs.indexWhere((j) => j.id == id);
    if (idx != -1) {
      activeJobs.removeAt(idx);
      filterByType(selectedFilter.value);
      Get.snackbar('Job Cancelled', 'The job has been removed from your list.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }
}
