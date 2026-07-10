import 'package:get/get.dart';
import 'package:urban_goodz_driver/services/driver_api_service.dart';
import 'package:urban_goodz_driver/services/api_client.dart';
import 'package:urban_goodz_driver/models/discovery_item_model.dart';

/// Read-only discovery of available work the driver is NOT assigned to.
/// All rows return can_claim=false; there is NO claim/accept action.
class JobDiscoveryController extends GetxController {
  final DriverApiService _api = Get.find<DriverApiService>();

  var items = <DiscoveryItem>[].obs;
  var summary = <String, dynamic>{}.obs;
  var detail = Rxn<DiscoveryItem>();
  var isLoading = false.obs;
  var isDetailLoading = false.obs;
  var errorMessage = ''.obs;

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final results = await Future.wait([
        _api.getDiscovery(),
        _api.getDiscoverySummary(),
      ]);
      items.value = results[0] as List<DiscoveryItem>;
      summary.value = results[1] as Map<String, dynamic>;
    } catch (e) {
      errorMessage.value = _msg(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadDetail(String type, int id) async {
    isDetailLoading.value = true;
    errorMessage.value = '';
    try {
      detail.value = await _api.getDiscoveryDetail(type, id);
    } catch (e) {
      errorMessage.value = _msg(e);
    } finally {
      isDetailLoading.value = false;
    }
  }

  // Discovery is informational only. can_claim is always false (contract).
  bool canViewDetail(DiscoveryItem item) => item.canView;

  String _msg(Object e) => e is ApiException ? e.message : e.toString();
}
