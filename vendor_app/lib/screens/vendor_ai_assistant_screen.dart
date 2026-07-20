import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:urban_goodz_vendor/controllers/vendor_ai_assistant_controller.dart';
import 'package:urban_goodz_vendor/controllers/vendor_auth_controller.dart';
import 'package:urban_goodz_vendor/screens/inventory_screen.dart';
import 'package:urban_goodz_vendor/screens/orders_screen.dart';
import 'package:urban_goodz_vendor/screens/revenue_tracking_screen.dart';
import 'package:urban_goodz_vendor/screens/analytics_screen.dart';
import 'package:urban_goodz_vendor/theme/app_theme.dart';

class VendorAiAssistantScreen extends StatefulWidget {
  const VendorAiAssistantScreen({super.key});

  @override
  State<VendorAiAssistantScreen> createState() => _VendorAiAssistantScreenState();
}

class _VendorAiAssistantScreenState extends State<VendorAiAssistantScreen> {
  final VendorAiAssistantController controller = Get.put(VendorAiAssistantController());
  final VendorAuthController auth = Get.find<VendorAuthController>();
  bool _quietHoursEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: AppTheme.white),
            SizedBox(width: 8),
            Text('Vendor Success Assistant', style: TextStyle(color: AppTheme.white)),
          ],
        ),
      ),
      body: Obx(() {
        if (!auth.isLoggedIn.value) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Please log in as a Vendor to access the AI Success Assistant.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  controller.errorMessage.value,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: controller.fetchAssistantBrief,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetchAssistantBrief,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPreferencesCard(),
                const SizedBox(height: 16),
                _buildDailyBriefSection(),
                const SizedBox(height: 16),
                _buildRecommendedActionsSection(),
                const SizedBox(height: 16),
                _buildCatalogSuggestionsSection(),
                const SizedBox(height: 16),
                _buildSettlementsSection(),
                const SizedBox(height: 16),
                _buildDeepLinksSection(),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPreferencesCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.nights_stay, color: AppTheme.primary),
                SizedBox(width: 8),
                Text('Snooze AI Alert Sounds', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            Switch(
              value: _quietHoursEnabled,
              onChanged: (val) {
                setState(() {
                  _quietHoursEnabled = val;
                });
              },
              activeColor: AppTheme.primary,
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDailyBriefSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.chat_bubble_outline, color: AppTheme.primary),
              SizedBox(width: 8),
              Text('Daily AI Operations Brief', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            controller.dailyBrief.value,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recommended Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (controller.recommendedActions.isEmpty)
          const Text('No recommended operational changes at this time.', style: TextStyle(color: Colors.grey))
        else
          ...controller.recommendedActions.map((action) {
            final title = action['title'] ?? 'N/A';
            final desc = action['description'] ?? 'N/A';

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.accent,
                  child: Icon(Icons.flash_on, color: AppTheme.white),
                ),
                title: Text(title),
                subtitle: Text(desc),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildCatalogSuggestionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Catalog & Price Recommendations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (controller.catalogSuggestions.isEmpty)
          const Text('All catalog item listings are fully optimized.', style: TextStyle(color: Colors.grey))
        else
          ...controller.catalogSuggestions.map((suggestion) {
            final itemId = suggestion['item_id'] ?? 0;
            final itemName = suggestion['item_name'] ?? 'N/A';
            final currentPrice = suggestion['current_price'] ?? 0.0;
            final proposedPrice = suggestion['proposed_price'] ?? 0.0;
            final reason = suggestion['reason'] ?? '';

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.monetization_on, color: Colors.green),
                title: Text(itemName),
                subtitle: Text('Current: \$${currentPrice.toStringAsFixed(2)} | Recommended: \$${proposedPrice.toStringAsFixed(2)}\nReason: $reason'),
                trailing: ElevatedButton(
                  onPressed: () => _confirmPriceChange(itemId, itemName, proposedPrice),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                  child: const Text('Apply'),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildSettlementsSection() {
    final brief = controller.settlementBrief;
    final lastSettlement = brief['last_settlement'] ?? 0.0;
    final nextSettlementDate = brief['next_settlement_date'] ?? 'N/A';
    final status = brief['status'] ?? 'N/A';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Settlements & Financial Brief', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Last Disbursed Settlement:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('\$${lastSettlement.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Next Settlement: $nextSettlementDate (Status: $status).'),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildDeepLinksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Success Shortcuts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.inventory, color: AppTheme.primary),
                title: const Text('Manage Stock & Inventory'),
                subtitle: const Text('Quickly edit active listings, items catalog, and availability.'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Get.to(() => const InventoryScreen()),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.shopping_basket, color: AppTheme.primary),
                title: const Text('Active Store Orders'),
                subtitle: const Text('Process pending customer food or product delivery orders.'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Get.to(() => const OrdersScreen()),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet, color: AppTheme.primary),
                title: const Text('Revenue & Settlement History'),
                subtitle: const Text('Disbursement records, daily metrics, and balance adjustments.'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Get.to(() => const RevenueTrackingScreen()),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.analytics, color: AppTheme.primary),
                title: const Text('Business Performance Metrics'),
                subtitle: const Text('Store reports, customer feedback, and preparation times.'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Get.to(() => const AnalyticsScreen()),
              ),
            ],
          ),
        )
      ],
    );
  }

  void _confirmPriceChange(int itemId, String itemName, double price) {
    Get.dialog(
      AlertDialog(
        title: const Text('Confirm Menu Price Update'),
        content: Text('Are you sure you want to adjust the menu price of "$itemName" to \$${price.toStringAsFixed(2)}?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.applyCatalogChange(itemId, {'price': price});
              Get.snackbar(
                'Menu Updated', 
                'Successfully adjusted price for "$itemName" to \$${price.toStringAsFixed(2)}.',
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Confirm'),
          )
        ],
      )
    );
  }
}
