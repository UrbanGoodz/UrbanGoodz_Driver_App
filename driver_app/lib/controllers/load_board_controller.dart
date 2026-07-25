import 'package:get/get.dart';
import 'package:urban_goodz_driver/models/driver_job_model.dart';
import 'package:urban_goodz_driver/services/driver_api_service.dart';

class LoadBoardController extends GetxController {
  DriverApiService get _api => Get.find<DriverApiService>();

  var availableLoads = <DriverJobModel>[].obs;
  var filteredLoads = <DriverJobModel>[].obs;
  var sortBy = 'pay'.obs;
  var minPay = 0.0.obs;
  var maxPay = 500.0.obs;
  var vehicleFilter = 'all'.obs;
  var isLoading = true.obs;
  var errorMessage = ''.obs;
  var currentPage = 1.obs;
  var hasMore = true.obs;

  @override
  void onInit() {
    fetchLoads();
    super.onInit();
  }

  void fetchLoads({bool refresh = false}) async {
    if (refresh) {
      currentPage.value = 1;
      hasMore.value = true;
    }
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final body = await _api.getLoadBoard(page: currentPage.value);
      final loads = body['loads'];
      final List<DriverJobModel> items;
      if (loads is Map && loads['data'] is List) {
        items = (loads['data'] as List)
            .map((e) => DriverJobModel.fromJson(e))
            .toList();
        hasMore.value = loads['next_page_url'] != null;
      } else if (loads is List) {
        items = loads.map((e) => DriverJobModel.fromJson(e)).toList();
        hasMore.value = false;
      } else {
        items = [];
        hasMore.value = false;
      }
      if (refresh || currentPage.value == 1) {
        availableLoads.value = items;
      } else {
        availableLoads.addAll(items);
      }
      applyFilters();
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  void loadMore() {
    if (!isLoading.value && hasMore.value) {
      currentPage.value++;
      fetchLoads();
    }
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
      result = result
          .where((l) => l.vehicleType == vehicleFilter.value)
          .toList();
    }
    filteredLoads.value = result;
    sortLoads(sortBy.value);
  }

  /// Load ids currently on the board. A driver may only bid on or accept a
  /// load the board actually served them.
  Set<int> get boardLoadIds =>
      availableLoads.map((l) => int.tryParse(l.id)).whereType<int>().toSet();

  DriverJobModel? _boardLoad(String id) {
    final loadId = int.tryParse(id);
    if (loadId == null) return null;
    for (final l in availableLoads) {
      if (int.tryParse(l.id) == loadId) return l;
    }
    return null;
  }

  /// POST /api/v1/urban-goodz/driver/load-board/{id}/bid  (verified 2026-07-25)
  ///
  /// [bidAmount] is now required. The previous implementation hardcoded
  /// `0.0` and then told the driver "Your bid has been submitted for
  /// review" — every driver silently bid zero on every load.
  Future<void> bidOnLoad(String id, double bidAmount, {String? notes}) async {
    final load = _boardLoad(id);
    if (load == null) {
      _fail('That load is no longer on the board.');
      return;
    }
    if (bidAmount <= 0) {
      _fail('Enter a bid amount greater than zero.');
      return;
    }
    try {
      await _api.bidOnLoad(int.parse(load.id), bidAmount, notes: notes);
      Get.snackbar(
        'Bid Submitted',
        'Your bid of \$${bidAmount.toStringAsFixed(2)} was submitted.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      _fail('Failed to submit bid: $e');
    }
  }

  /// POST /api/v1/urban-goodz/driver/load-board/{id}/accept (verified
  /// 2026-07-25). This is the app's only accept path — it takes a *load*
  /// id, not an active-job id. Success is reported only when the server
  /// returns the resulting job.
  Future<void> acceptLoad(String id) async {
    final load = _boardLoad(id);
    if (load == null) {
      _fail('That load is no longer on the board.');
      return;
    }
    try {
      final job = await _api.acceptLoad(int.parse(load.id));
      if (job.isEmpty) {
        Get.snackbar(
          'Not confirmed',
          'The server accepted the request but did not return the job. '
              'Check Active Jobs before starting work.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      availableLoads.removeWhere((l) => l.id == load.id);
      applyFilters();
      // Deliberately does not name the list the job lands in. The driver app
      // has two job lists (`business-jobs`, which the Active Jobs screen
      // reads, and `active-jobs`) and the backend has not documented which
      // one an accepted load appears in — see CONTRACT-11. Claiming "it's in
      // your Active Jobs" would be an assertion the app cannot support.
      final jobId = job['id']?.toString() ?? job['job_id']?.toString();
      Get.snackbar(
        'Load Accepted',
        jobId == null
            ? 'The server confirmed the job is yours. Refresh your jobs list.'
            : 'Job #$jobId is yours. Refresh your jobs list to start it.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      _fail('Failed to accept load: $e');
    }
  }

  void _fail(String message) => Get.snackbar(
        'Action not allowed',
        message,
        snackPosition: SnackPosition.BOTTOM,
      );
}
