import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:urban_goodz_driver/controllers/business_job_controller.dart';
import 'package:urban_goodz_driver/controllers/dedicated_route_controller.dart';
import 'package:urban_goodz_driver/theme/app_theme.dart';
import 'package:urban_goodz_driver/screens/business_job_detail_screen.dart';
import 'package:urban_goodz_driver/screens/dedicated_route_list_screen.dart';
import 'package:urban_goodz_driver/models/business_job_model.dart';

class ActiveJobsScreen extends StatelessWidget {
  const ActiveJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final BusinessJobController controller = Get.find();
    final DedicatedRouteController routesCtl = Get.find();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Jobs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.fetchJobs(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.jobs.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.errorMessage.value.isNotEmpty &&
            controller.jobs.isEmpty) {
          return Center(
            child: Text(
              controller.errorMessage.value,
              textAlign: TextAlign.center,
            ),
          );
        }
        if (controller.jobs.isEmpty) {
          return Column(
            children: [
              _YourRoutesCard(routesCtl: routesCtl),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64, color: AppTheme.dark.withAlpha(60)),
                      const SizedBox(height: 16),
                      const Text(
                        'No assigned business jobs',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Jobs assigned to you by dispatch will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.dark.withAlpha(120),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
        return RefreshIndicator(
          onRefresh: () => controller.fetchJobs(),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: controller.jobs.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _YourRoutesCard(routesCtl: routesCtl);
              }
              final job = controller.jobs[index - 1];
              return _JobCard(job: job);
            },
          ),
        );
      }),
    );
  }
}

/// "Your routes" summary card at the top of the Jobs tab, the tab drivers
/// actually watch. Dedicated routes otherwise only surface via a push
/// notification or a buried Dashboard tile, so without this a driver can go
/// an entire route without ever seeing it was assigned.
class _YourRoutesCard extends StatelessWidget {
  final DedicatedRouteController routesCtl;
  const _YourRoutesCard({required this.routesCtl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final routes = routesCtl.assignedRoutes;
      if (routes.isEmpty) return const SizedBox.shrink();

      final hasUnstarted = routes.any((r) => r.canStart);

      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        child: GestureDetector(
          onTap: () => Get.to(() => const DedicatedRouteListScreen()),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primary.withAlpha(60)),
            ),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(Icons.local_shipping, color: AppTheme.primary, size: 28),
                    if (hasUnstarted)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your routes',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        '${routes.length} assigned dedicated route${routes.length == 1 ? '' : 's'}',
                        style: TextStyle(fontSize: 12, color: AppTheme.dark.withAlpha(150)),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _JobCard extends StatelessWidget {
  final BusinessJobModel job;
  const _JobCard({required this.job});

  Color _statusColor(String status) {
    switch (status) {
      case 'assigned':
        return AppTheme.primary;
      case 'driver_accepted':
      case 'driver_en_route':
        return AppTheme.accent;
      case 'picked_up':
      case 'in_transit':
        return AppTheme.primary;
      case 'delivered':
        return AppTheme.primary;
      case 'delayed':
        return Colors.orange;
      default:
        return AppTheme.dark;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'assigned':
        return 'Assigned';
      case 'driver_accepted':
        return 'Accepted';
      case 'driver_en_route':
        return 'En Route';
      case 'picked_up':
        return 'Picked Up';
      case 'in_transit':
        return 'In Transit';
      case 'delivered':
        return 'Delivered';
      case 'delayed':
        return 'Delayed';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => BusinessJobDetailScreen(jobId: job.jobId)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: AppTheme.dark.withAlpha(15), blurRadius: 8),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    job.jobType.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(job.status).withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _statusLabel(job.status),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _statusColor(job.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              job.jobNumber,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (job.businessClientName != null) ...[
              const SizedBox(height: 4),
              Text(
                job.businessClientName!,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.dark.withAlpha(150),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: AppTheme.primary.withAlpha(180),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    job.pickup.address ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.dark.withAlpha(150),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.flag,
                  size: 16,
                  color: AppTheme.accent.withAlpha(180),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    job.dropoff.address ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.dark.withAlpha(150),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.attach_money, size: 18, color: AppTheme.primary),
                Text(
                  job.displayRate,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
