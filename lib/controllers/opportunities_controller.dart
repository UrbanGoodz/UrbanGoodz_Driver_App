import 'package:get/get.dart';
import 'package:urban_goodz_driver/models/opportunity_model.dart';
import 'package:urban_goodz_driver/repositories/mock_driver_data.dart';

class OpportunitiesController extends GetxController {
  final MockOpportunityRepository _repository = MockOpportunityRepository();

  var opportunities = <OpportunityModel>[].obs;
  var filteredOpportunities = <OpportunityModel>[].obs;
  var selectedCategory = 'all'.obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    fetchOpportunities();
    super.onInit();
  }

  void fetchOpportunities() {
    isLoading.value = true;
    _repository.fetchOpportunities().then((opps) {
      opportunities.value = opps;
      filterByCategory(selectedCategory.value);
      isLoading.value = false;
    });
  }

  void filterByCategory(String category) {
    selectedCategory.value = category;
    if (category == 'all') {
      filteredOpportunities.value = List.from(opportunities);
    } else {
      filteredOpportunities.value =
          opportunities.where((o) => o.type == category).toList();
    }
  }

  void claimOpportunity(String id) {
    _repository.claimOpportunity(id).then((success) {
      if (success) {
        final idx = opportunities.indexWhere((o) => o.id == id);
        if (idx != -1) {
          final updated = OpportunityModel(
            id: opportunities[idx].id,
            title: opportunities[idx].title,
            description: opportunities[idx].description,
            type: opportunities[idx].type,
            reward: opportunities[idx].reward,
            status: 'claimed',
            validFrom: opportunities[idx].validFrom,
            validUntil: opportunities[idx].validUntil,
            terms: opportunities[idx].terms,
            isActive: true,
          );
          opportunities[idx] = updated;
          filterByCategory(selectedCategory.value);
        }
        Get.snackbar('Claimed!', 'Opportunity has been added to your profile.',
            snackPosition: SnackPosition.BOTTOM);
      }
    });
  }
}
