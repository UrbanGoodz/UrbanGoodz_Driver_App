import 'package:get/get.dart';
import 'package:urban_goodz_driver/services/driver_api_service.dart';

class DriverAiAssistantController extends GetxController {
  DriverApiService get _api => Get.find<DriverApiService>();

  var dailySummary = ''.obs;
  var loadRecommendations = <Map<String, dynamic>>[].obs;
  var aiMatch = <String, dynamic>{}.obs;
  var earningsComparison = <String, dynamic>{}.obs;
  var optimizedRoute = <String, dynamic>{}.obs;

  var isLoading = false.obs;
  var isOptimizing = false.obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    fetchAssistantData();
    super.onInit();
  }

  Future<void> fetchAssistantData() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      // 1. Get Daily Summary
      final summaryRes = await _api.getAiDailySummary();
      dailySummary.value = summaryRes['summary']?.toString() ?? 'No summary available today.';

      // 2. Get Load Recommendations
      final loadsRes = await _api.getAiLoadRecommendations();
      if (loadsRes['loads'] is List) {
        loadRecommendations.value = List<Map<String, dynamic>>.from(
          (loadsRes['loads'] as List).map((l) => Map<String, dynamic>.from(l))
        );
      } else {
        loadRecommendations.clear();
      }
      aiMatch.value = loadsRes['ai_match'] is Map ? Map<String, dynamic>.from(loadsRes['ai_match']) : {};

      // 3. Get Earnings Comparison
      final earningsRes = await _api.getAiEarningsComparison(period: 'week');
      earningsComparison.value = Map<String, dynamic>.from(earningsRes);
    } catch (e) {
      errorMessage.value = 'Failed to load assistant data. Please check your connection.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> optimizeRouteSequence(int routeId, {String? preference}) async {
    isOptimizing.value = true;
    errorMessage.value = '';
    try {
      final res = await _api.getAiRouteOptimization(routeId, preference: preference);
      optimizedRoute.value = Map<String, dynamic>.from(res['optimization'] ?? {});
    } catch (e) {
      errorMessage.value = 'Route optimization failed.';
    } finally {
      isOptimizing.value = false;
    }
  }
}
