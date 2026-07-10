import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:urban_goodz_driver/controllers/payout_history_controller.dart';
import 'package:urban_goodz_driver/theme/app_theme.dart';

class PayoutHistoryScreen extends StatefulWidget {
  const PayoutHistoryScreen({super.key});

  @override
  State<PayoutHistoryScreen> createState() => _PayoutHistoryScreenState();
}

class _PayoutHistoryScreenState extends State<PayoutHistoryScreen> {
  final PayoutHistoryController controller =
      Get.put(PayoutHistoryController());

  final List<String> _statuses = ['all', 'pending', 'completed', 'failed'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payout History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.fetchPayoutHistory(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: AppTheme.dark.withAlpha(15),
                              blurRadius: 8)
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Paid',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.dark)),
                          const SizedBox(height: 4),
                          Text(
                              '\$${controller.totalPaid.value.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green)),
                          Icon(Icons.trending_up,
                              color: Colors.green, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: AppTheme.dark.withAlpha(15),
                              blurRadius: 8)
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Pending',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.dark)),
                          const SizedBox(height: 4),
                          Text(
                              '\$${controller.pendingAmount.value.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary)),
                          Icon(Icons.hourglass_empty,
                              color: AppTheme.primary, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: _statuses.map((s) {
                  final isSelected = controller.selectedFilter.value == s;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: ChoiceChip(
                        label: Text(
                          s[0].toUpperCase() + s.substring(1),
                          style: TextStyle(
                            color: isSelected
                                ? AppTheme.white
                                : AppTheme.dark,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (_) =>
                            controller.filterByStatus(s),
                        selectedColor: AppTheme.primary,
                        backgroundColor: AppTheme.beige,
                        side: BorderSide.none,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              ...controller.filteredPayouts.map((payout) {
                Color statusColor;
                switch (payout.status) {
                  case 'completed':
                    statusColor = Colors.green;
                    break;
                  case 'pending':
                    statusColor = AppTheme.primary;
                    break;
                  case 'failed':
                    statusColor = Colors.red;
                    break;
                  default:
                    statusColor = AppTheme.dark;
                }

                IconData statusIcon;
                switch (payout.status) {
                  case 'completed':
                    statusIcon = Icons.check_circle;
                    break;
                  case 'pending':
                    statusIcon = Icons.hourglass_empty;
                    break;
                  case 'failed':
                    statusIcon = Icons.cancel;
                    break;
                  default:
                    statusIcon = Icons.help;
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: statusColor.withAlpha(40),
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: AppTheme.dark.withAlpha(10),
                          blurRadius: 4)
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(statusIcon,
                              color: statusColor, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                    '\$${payout.amount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18)),
                                Text(payout.requestedDate,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.dark
                                            .withAlpha(120))),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withAlpha(30),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              payout.status[0].toUpperCase() +
                                  payout.status.substring(1),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.account_balance,
                              size: 14,
                              color: AppTheme.dark.withAlpha(120)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(payout.paymentMethod,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.dark
                                        .withAlpha(120))),
                          ),
                        ],
                      ),
                      if (payout.transactionId.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.receipt,
                                size: 14,
                                color: AppTheme.dark.withAlpha(120)),
                            const SizedBox(width: 4),
                            Text('ID: ${payout.transactionId}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.dark
                                        .withAlpha(120))),
                          ],
                        ),
                      ],
                      if (payout.notes.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.note,
                                size: 14,
                                color: AppTheme.dark.withAlpha(120)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(payout.notes,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.dark
                                          .withAlpha(120))),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
              const Text('Withdrawal Method',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: AppTheme.dark.withAlpha(15),
                        blurRadius: 8)
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.account_balance,
                        color: AppTheme.primary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Bank of America',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                          Text('Checking Account ****4521',
                              style: TextStyle(
                                  fontSize: 13,
                                  color:
                                      AppTheme.dark.withAlpha(150))),
                        ],
                      ),
                    ),
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 22),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showRequestPayoutDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Request Payout',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }

  void _showRequestPayoutDialog(BuildContext context) {
    final amountController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text('Request Payout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Enter the amount you would like to withdraw to your bank account.'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '\$ ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0) {
                controller.requestPayout(amount);
                Get.back();
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
