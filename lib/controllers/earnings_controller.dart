import 'package:get/get.dart';
import 'package:urban_goodz_driver/models/earnings_model.dart';
import 'package:urban_goodz_driver/repositories/mock_driver_data.dart';

class EarningsController extends GetxController {
  final MockEarningsRepository _repository = MockEarningsRepository();

  var dailyEarnings = <EarningsModel>[].obs;
  var totalEarnings = 0.0.obs;
  var totalTips = 0.0.obs;
  var totalBonuses = 0.0.obs;
  var totalMileage = 0.0.obs;
  var selectedPeriod = 'weekly'.obs;
  var projectedWeeklyEarnings = 0.0.obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    fetchEarnings();
    super.onInit();
  }

  void fetchEarnings() {
    isLoading.value = true;
    _repository.fetchDailyEarnings().then((earnings) {
      dailyEarnings.value = earnings;
      isLoading.value = false;
    });
    _repository.fetchTotalEarnings().then((v) => totalEarnings.value = v);
    _repository.fetchTotalTips().then((v) => totalTips.value = v);
    _repository.fetchTotalBonuses().then((v) => totalBonuses.value = v);
    _repository.fetchTotalMileage().then((v) => totalMileage.value = v);
    _repository.fetchProjectedWeeklyEarnings().then((v) => projectedWeeklyEarnings.value = v);
  }

  void changePeriod(String period) {
    selectedPeriod.value = period;
  }
}
