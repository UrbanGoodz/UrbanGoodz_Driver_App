import 'package:get/get.dart';
import 'package:urban_goodz_driver/models/payout_model.dart';
import 'package:urban_goodz_driver/repositories/mock_driver_data.dart';

class PayoutHistoryController extends GetxController {
  final MockPayoutRepository _repository = MockPayoutRepository();

  var payouts = <PayoutModel>[].obs;
  var filteredPayouts = <PayoutModel>[].obs;
  var totalPaid = 0.0.obs;
  var pendingAmount = 0.0.obs;
  var selectedFilter = 'all'.obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    fetchPayoutHistory();
    super.onInit();
  }

  void fetchPayoutHistory() {
    isLoading.value = true;
    _repository.fetchPayouts().then((p) {
      payouts.value = p;
      totalPaid.value = p
          .where((po) => po.status == 'completed')
          .fold(0.0, (sum, po) => sum + po.amount);
      pendingAmount.value = p
          .where((po) => po.status == 'pending')
          .fold(0.0, (sum, po) => sum + po.amount);
      filterByStatus(selectedFilter.value);
      isLoading.value = false;
    });
  }

  void filterByStatus(String status) {
    selectedFilter.value = status;
    if (status == 'all') {
      filteredPayouts.value = List.from(payouts);
    } else {
      filteredPayouts.value =
          payouts.where((p) => p.status == status).toList();
    }
  }

  void requestPayout(double amount) {
    _repository.requestPayout(amount).then((success) {
      if (success) {
        final newPayout = PayoutModel(
          id: 'PO-${DateTime.now().millisecondsSinceEpoch}',
          amount: amount,
          status: 'pending',
          requestedDate:
              '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
          paymentMethod: 'Direct Deposit - Bank of America',
          notes: 'Manual payout request',
        );
        payouts.insert(0, newPayout);
        filterByStatus(selectedFilter.value);
        pendingAmount.value += amount;
        Get.snackbar('Request Submitted',
            'Your payout of \$${amount.toStringAsFixed(2)} is being processed.',
            snackPosition: SnackPosition.BOTTOM);
      }
    });
  }
}
