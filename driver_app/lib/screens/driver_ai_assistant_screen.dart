import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:urban_goodz_driver/controllers/driver_ai_assistant_controller.dart';
import 'package:urban_goodz_driver/controllers/driver_auth_controller.dart';
import 'package:urban_goodz_driver/screens/dedicated_route_list_screen.dart';
import 'package:urban_goodz_driver/screens/certifications_screen.dart';
import 'package:urban_goodz_driver/screens/payout_history_screen.dart';
import 'package:urban_goodz_driver/screens/vehicle_requirements_screen.dart';
import 'package:urban_goodz_driver/screens/capability_screen.dart';
import 'package:urban_goodz_driver/theme/app_theme.dart';

class DriverAiAssistantScreen extends StatefulWidget {
  const DriverAiAssistantScreen({super.key});

  @override
  State<DriverAiAssistantScreen> createState() => _DriverAiAssistantScreenState();
}

class _DriverAiAssistantScreenState extends State<DriverAiAssistantScreen> {
  final DriverAiAssistantController controller = Get.put(DriverAiAssistantController());
  final DriverAuthController auth = Get.find<DriverAuthController>();
  bool _quietHoursEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: AppTheme.white),
            SizedBox(width: 8),
            Text('Driver AI Assistant', style: TextStyle(color: AppTheme.white)),
          ],
        ),
      ),
      body: Obx(() {
        if (!auth.isLoggedIn.value) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Please log in as a Driver to access the AI Assistant.',
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
                  onPressed: controller.fetchAssistantData,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetchAssistantData,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPreferencesCard(),
                const SizedBox(height: 16),
                _buildSummarySection(),
                const SizedBox(height: 16),
                _buildRecommendedSection(),
                const SizedBox(height: 16),
                _buildMatchingVehicleSection(),
                const SizedBox(height: 16),
                _buildActionsNeededSection(),
                const SizedBox(height: 16),
                _buildAlertsSection(),
                const SizedBox(height: 16),
                _buildEarningsSection(),
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
                Text('Quiet Hours (Snooze Alerts)', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildSummarySection() {
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
              Text('Daily Assistant Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            controller.dailySummary.value,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recommended Now (Load Board)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (controller.loadRecommendations.isEmpty)
          const Text('No new load recommendations matching your parameters.', style: TextStyle(color: Colors.grey))
        else
          ...controller.loadRecommendations.map((load) {
            final loadNo = load['load_number'] ?? 'N/A';
            final origin = load['origin'] ?? 'N/A';
            final dest = load['destination'] ?? 'N/A';
            final payout = load['payout'] ?? 0.0;
            final weight = load['weight'] ?? 0;
            final distance = load['distance'] ?? 0.0;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.primary,
                  child: Icon(Icons.local_shipping, color: AppTheme.white),
                ),
                title: Text('Load #$loadNo (\$${payout.toStringAsFixed(2)})'),
                subtitle: Text('From: $origin\nTo: $dest\nWeight: $weight lbs | Distance: $distance mi'),
                trailing: ElevatedButton(
                  onPressed: () => _confirmLoadAssignment(load),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                  child: const Text('Claim'),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildMatchingVehicleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Routes Matching My Vehicle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.drive_eta, color: AppTheme.primary),
            title: const Text('Dedicated routes matching vehicle'),
            subtitle: const Text('Tap to view currently available dedicated routes matching payload capability.'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Get.to(() => const DedicatedRouteListScreen()),
          ),
        )
      ],
    );
  }

  Widget _buildActionsNeededSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Documents & Actions Needed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.verified_user, color: Colors.orange),
                title: const Text('Compliance Documents'),
                subtitle: const Text('Upload/renew medical certificate or driver permits.'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Get.to(() => const CertificationsScreen()),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.build, color: Colors.orange),
                title: const Text('Vehicle Requirements'),
                subtitle: const Text('Verify maximum cargo capacity and features.'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Get.to(() => const VehicleRequirementsScreen()),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.location_on, color: Colors.orange),
                title: const Text('Operational Zones'),
                subtitle: const Text('Update preferred driver routes and coverage regions.'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Get.to(() => const CapabilityScreen()),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildAlertsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Exceptions & Route Alerts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          color: Colors.red.shade50,
          child: const ListTile(
            leading: Icon(Icons.warning, color: Colors.red),
            title: Text('Exceptions Requiring Attention', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            subtitle: Text('No active exception packages found. Keep driving safely!'),
          ),
        )
      ],
    );
  }

  Widget _buildEarningsSection() {
    final comparison = controller.earningsComparison;
    final vsPlatform = comparison['vs_platform'] ?? 'stable';
    final percentile = comparison['percentile'] ?? 50;
    final totalEarnings = comparison['total_earnings'] ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Earnings & Payout Explanations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                    const Text('Total Weekly Earnings:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('\$${totalEarnings.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('You are performing $vsPlatform the average driver on the platform (Percentile: $percentile%).'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => Get.to(() => const PayoutHistoryScreen()),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                  child: const Text('View Payout History'),
                )
              ],
            ),
          ),
        )
      ],
    );
  }

  void _confirmLoadAssignment(Map<String, dynamic> load) {
    final loadNo = load['load_number'] ?? 'N/A';
    final payout = load['payout'] ?? 0.0;

    Get.dialog(
      AlertDialog(
        title: const Text('Confirm Load Assignment'),
        content: Text('Are you sure you want to assign Load #$loadNo to yourself? This load pays \$${payout.toStringAsFixed(2)}.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // Simulating successful assignment
              Get.snackbar(
                'Success', 
                'Load #$loadNo successfully claimed. Please navigate to Active Jobs to start.',
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
