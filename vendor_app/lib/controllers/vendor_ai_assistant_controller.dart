import 'package:get/get.dart';
import 'package:urban_goodz_vendor/services/vendor_api_client.dart';

class VendorAiAssistantController extends GetxController {
  VendorApiClient get _client => Get.find<VendorApiClient>();

  var dailyBrief = ''.obs;
  var catalogSuggestions = <Map<String, dynamic>>[].obs;
  var recommendedActions = <Map<String, dynamic>>[].obs;
  var settlementBrief = <String, dynamic>{}.obs;

  var isLoading = false.obs;
  var isUpdatingCatalog = false.obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    fetchAssistantBrief();
    super.onInit();
  }

  Future<void> fetchAssistantBrief() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      // 1. Fetch Daily Brief
      final briefRes = await _client.get('/urban-goodz/cross-app/ai/vendor/daily-brief');
      if (briefRes is Map) {
        dailyBrief.value = briefRes['brief']?.toString() ?? 'Daily brief temporarily unavailable.';
      }

      // 2. Fetch Catalog Suggestions & Alerts
      final catalogRes = await _client.get('/urban-goodz/cross-app/ai/vendor/catalog-suggestions');
      if (catalogRes is Map && catalogRes['suggestions'] is List) {
        catalogSuggestions.value = List<Map<String, dynamic>>.from(
          (catalogRes['suggestions'] as List).map((s) => Map<String, dynamic>.from(s))
        );
      }

      // 3. Fetch Recommended Actions
      final actionsRes = await _client.get('/urban-goodz/cross-app/ai/vendor/recommended-actions');
      if (actionsRes is Map && actionsRes['actions'] is List) {
        recommendedActions.value = List<Map<String, dynamic>>.from(
          (actionsRes['actions'] as List).map((a) => Map<String, dynamic>.from(a))
        );
      }

      // 4. Fetch Settlement Brief
      final settlementRes = await _client.get('/urban-goodz/cross-app/ai/vendor/settlement-metrics');
      if (settlementRes is Map) {
        settlementBrief.value = Map<String, dynamic>.from(settlementRes);
      }
    } catch (e) {
      errorMessage.value = 'Failed to load Vendor AI briefing.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> applyCatalogChange(int itemId, Map<String, dynamic> changes) async {
    isUpdatingCatalog.value = true;
    try {
      await _client.post('/urban-goodz/cross-app/ai/vendor/catalog-update', body: {
        'item_id': itemId,
        'changes': changes,
      });
      // Refresh suggestions
      fetchAssistantBrief();
    } catch (e) {
      Get.snackbar('Catalog Update', 'Failed to apply recommendation', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isUpdatingCatalog.value = false;
    }
  }
}
