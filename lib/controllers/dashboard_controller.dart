import 'package:get/get.dart';
import 'package:urban_goodz_driver/models/driver_job_model.dart';
import 'package:urban_goodz_driver/repositories/mock_driver_data.dart';

class DashboardController extends GetxController {
  final MockDashboardRepository _repository = MockDashboardRepository();

  var todayEarnings = 0.0.obs;
  var weeklyEarnings = 0.0.obs;
  var monthlyEarnings = 0.0.obs;
  var completedJobs = 0.obs;
  var activeJobs = 0.obs;
  var acceptanceRate = 0.0.obs;
  var rating = 0.0.obs;
  var activeJobsList = <DriverJobModel>[].obs;
  var weeklyEarningsChart = <double>[].obs;
  var driverStatus = 'online'.obs;
  var isLoading = true.obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    fetchDashboard();
    super.onInit();
  }

  void fetchDashboard() {
    isLoading.value = true;
    errorMessage.value = '';

    _repository.fetchTodayEarnings().then((v) => todayEarnings.value = v);
    _repository.fetchWeeklyEarnings().then((v) => weeklyEarnings.value = v);
    _repository.fetchMonthlyEarnings().then((v) => monthlyEarnings.value = v);
    _repository.fetchCompletedJobs().then((v) => completedJobs.value = v);
    _repository.fetchActiveJobs().then((v) => activeJobs.value = v);
    _repository.fetchAcceptanceRate().then((v) => acceptanceRate.value = v);
    _repository.fetchRating().then((v) => rating.value = v);
    _repository.fetchWeeklyEarningsChart().then((v) => weeklyEarningsChart.value = v);
    _repository.fetchDriverStatus().then((v) => driverStatus.value = v);
    _repository.fetchActiveJobsList().then((v) {
      activeJobsList.value = v;
      isLoading.value = false;
    }).catchError((e) {
      errorMessage.value = 'Failed to load dashboard data.';
      isLoading.value = false;
    });
  }

  void toggleOnlineStatus() {
    _repository.toggleStatus(driverStatus.value).then((newStatus) {
      driverStatus.value = newStatus ? 'online' : 'offline';
    });
  }

  void acceptJob(String jobId) {
    _repository.acceptJob(jobId).then((success) {
      if (success) {
        fetchDashboard();
        Get.snackbar(
          'Job Accepted',
          'You have successfully accepted job $jobId',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    });
  }

  void completeJob(String jobId) {
    _repository.completeJob(jobId).then((success) {
      if (success) {
        fetchDashboard();
        Get.snackbar(
          'Job Completed',
          'Job $jobId marked as completed. Earnings updated.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    });
  }
}
