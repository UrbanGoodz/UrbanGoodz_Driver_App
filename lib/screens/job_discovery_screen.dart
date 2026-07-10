import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:urban_goodz_driver/controllers/job_discovery_controller.dart';
import 'package:urban_goodz_driver/models/discovery_item_model.dart';
import 'package:urban_goodz_driver/theme/app_theme.dart';

class JobDiscoveryScreen extends StatefulWidget {
  const JobDiscoveryScreen({super.key});

  @override
  State<JobDiscoveryScreen> createState() => _JobDiscoveryScreenState();
}

class _JobDiscoveryScreenState extends State<JobDiscoveryScreen> {
  final JobDiscoveryController controller = Get.find<JobDiscoveryController>();

  @override
  void initState() {
    super.initState();
    controller.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Job Discovery')),
      body: Obx(() {
        if (controller.isLoading.value && controller.items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: () => controller.load(),
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _summaryCard(),
              const SizedBox(height: 12),
              if (controller.items.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Text('No available work to discover right now.'),
                  ),
                )
              else
                ...controller.items.map((item) => _card(item)),
            ],
          ),
        );
      }),
    );
  }

  Widget _summaryCard() {
    final s = controller.summary;
    return Card(
      color: AppTheme.dark,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _stat('Business', s['business_courier_available']?.toString() ?? '0'),
            _stat('Package', s['package_pool_available']?.toString() ?? '0'),
            _stat('Routes', s['dedicated_routes_available']?.toString() ?? '0'),
            _stat('Medical', s['medical_courier_review_only']?.toString() ?? '0'),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) => Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.white)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(fontSize: 11, color: AppTheme.white.withAlpha(180))),
        ],
      );

  Widget _card(DiscoveryItem item) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          leading: Icon(Icons.explore, color: AppTheme.primary),
          title: Text(item.title),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${item.jobType} • ${item.status}'),
              if (item.zoneName != null)
                Text(item.zoneName!,
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.dark.withAlpha(130))),
              if (item.isAgeOrMedicalFlagged)
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Age / medical review — view only',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange,
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          isThreeLine: true,
          trailing: const Icon(Icons.chevron_right),
          // Read-only: no claim action. Open detail ifcanView.
          onTap: controller.canViewDetail(item)
              ? () => Get.to(() =>
                  _DiscoveryDetailView(type: item.jobType, id: item.jobId))
              : null,
        ),
      );
}

class _DiscoveryDetailView extends StatelessWidget {
  final String type;
  final int id;
  const _DiscoveryDetailView({required this.type, required this.id});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<JobDiscoveryController>();
    controller.loadDetail(type, id);
    return Scaffold(
      appBar: AppBar(title: const Text('Discovery Detail')),
      body: Obx(() {
        if (controller.isDetailLoading.value && controller.detail.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final item = controller.detail.value;
        if (item == null) {
          return Center(
              child: Text(controller.errorMessage.value.isNotEmpty
                  ? controller.errorMessage.value
                  : 'Not available'));
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('${item.jobType} • ${item.status}'),
              const SizedBox(height: 12),
              if (item.pickupAddress != null)
                Text('Pickup: ${item.pickupAddress}'),
              if (item.dropoffAddress != null)
                Text('Dropoff: ${item.dropoffAddress}'),
              if (item.vehicleTypeRequired != null)
                Text('Vehicle required: ${item.vehicleTypeRequired}'),
              if (item.isAgeOrMedicalFlagged)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: const Text(
                      'Age / medical review required. Informational only — there is no claim action.',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              const SizedBox(height: 16),
              // Explicitly NO claim/accept button. can_claim is always false.
              const Text(
                'This is read-only discovery. No claim action is available.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        );
      }),
    );
  }
}
