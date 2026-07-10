import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:urban_goodz_driver/controllers/business_job_controller.dart';
import 'package:urban_goodz_driver/theme/app_theme.dart';
import 'package:urban_goodz_driver/screens/business_job_detail_screen.dart';
import 'package:urban_goodz_driver/models/business_job_model.dart';

class ActiveJobsScreen extends StatelessWidget {
  const ActiveJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final BusinessJobController controller = Get.find();
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
              child: Text(controller.errorMessage.value,
                  textAlign: TextAlign.center));
        }
        if (controller.jobs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: AppTheme.dark.withAlpha(60)),
                const SizedBox(height: 16),
                const Text('No assigned business jobs',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                    'Jobs assigned to you by dispatch will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14, color: AppTheme.dark.withAlpha(120))),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => controller.fetchJobs(),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: controller.jobs.length,
            itemBuilder: (context, index) {
              final job = controller.jobs[index];
              return _JobCard(job: job);
            },
          ),
        );
      }),
    );
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
        return Colors.blue;
      case 'picked_up':
      case 'in_transit':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
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
            BoxShadow(color: AppTheme.dark.withAlpha(15), blurRadius: 8)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(job.jobType.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary)),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(job.status).withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_statusLabel(job.status),
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _statusColor(job.status))),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(job.jobNumber,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            if (job.businessClientName != null) ...[
              const SizedBox(height: 4),
              Text(job.businessClientName!,
                  style: TextStyle(
                      fontSize: 13, color: AppTheme.dark.withAlpha(150))),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on,
                    size: 16, color: AppTheme.primary.withAlpha(180)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(job.pickup.address ?? '',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.dark.withAlpha(150)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.flag,
                    size: 16, color: AppTheme.accent.withAlpha(180)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(job.dropoff.address ?? '',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.dark.withAlpha(150)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.attach_money, size: 18, color: AppTheme.primary),
                Text(job.displayRate,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18)),
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
