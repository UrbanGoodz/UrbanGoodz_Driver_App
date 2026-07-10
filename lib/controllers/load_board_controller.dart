import 'package:get/get.dart';
import 'package:urban_goodz_driver/models/driver_job_model.dart';
import 'package:urban_goodz_driver/repositories/mock_driver_data.dart';

class LoadBoardController extends GetxController {
  final MockJobRepository _repository = MockJobRepository();

  var availableLoads = <DriverJobModel>[].obs;
  var filteredLoads = <DriverJobModel>[].obs;
  var sortBy = 'pay'.obs;
  var minPay = 0.0.obs;
  var maxPay = 500.0.obs;
  var vehicleFilter = 'all'.obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    fetchLoads();
    super.onInit();
  }

  void fetchLoads() {
    isLoading.value = true;
    _repository.fetchAvailableLoads().then((loads) {
      availableLoads.value = loads;
      applyFilters();
      isLoading.value = false;
    });
  }

  void sortLoads(String by) {
    sortBy.value = by;
    final sorted = List<DriverJobModel>.from(filteredLoads);
    switch (by) {
      case 'pay':
        sorted.sort((a, b) => b.earnings.compareTo(a.earnings));
        break;
      case 'distance':
        sorted.sort((a, b) => a.distance.compareTo(b.distance));
        break;
      case 'date':
        sorted.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
        break;
    }
    filteredLoads.value = sorted;
  }

  void applyFilters() {
    var result = List<DriverJobModel>.from(availableLoads);
    result = result.where((l) => l.earnings >= minPay.value).toList();
    result = result.where((l) => l.earnings <= maxPay.value).toList();
    if (vehicleFilter.value != 'all') {
      result = result.where((l) => l.vehicleType == vehicleFilter.value).toList();
    }
    filteredLoads.value = result;
    sortLoads(sortBy.value);
  }

  void bidOnLoad(String id) {
    final idx = availableLoads.indexWhere((l) => l.id == id);
    if (idx != -1) {
      Get.snackbar('Bid Submitted',
          'Your bid on load $id has been submitted. The shipper will review shortly.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }
}
