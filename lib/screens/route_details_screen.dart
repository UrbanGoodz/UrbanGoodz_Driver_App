import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:urban_goodz_driver/controllers/route_details_controller.dart';
import 'package:urban_goodz_driver/theme/app_theme.dart';

class RouteDetailsScreen extends StatefulWidget {
  final String jobId;

  const RouteDetailsScreen({super.key, required this.jobId});

  @override
  State<RouteDetailsScreen> createState() => _RouteDetailsScreenState();
}

class _RouteDetailsScreenState extends State<RouteDetailsScreen> {
  final RouteDetailsController controller = Get.put(RouteDetailsController());

  @override
  void initState() {
    super.initState();
    controller.fetchRoute(widget.jobId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Details'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final job = controller.currentJob.value;
        if (job == null) {
          return const Center(child: Text('Job not found'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: AppTheme.dark.withAlpha(15), blurRadius: 8)
                  ],
                ),
                child: Column(
                  children: [
                    Icon(Icons.local_shipping,
                        size: 48, color: AppTheme.primary),
                    const SizedBox(height: 8),
                    Text(job.title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withAlpha(25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(children: [
                            const Icon(Icons.navigation, size: 14, color: AppTheme.primary),
                            const SizedBox(width: 4),
                            Text('${job.distance.toStringAsFixed(1)} miles',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                          ]),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.green.withAlpha(25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(children: [
                            const Icon(Icons.attach_money, size: 14, color: Colors.green),
                            const SizedBox(width: 2),
                            Text('\$${job.earnings.toStringAsFixed(2)} Payout',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                          ]),
                        ),
                        if (job.distance > 20) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.orange.withAlpha(25),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(children: [
                              Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange),
                              SizedBox(width: 4),
                              Text('Long Distance',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange)),
                            ]),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Icon(Icons.location_on,
                                  color: Colors.green, size: 20),
                              const SizedBox(height: 4),
                              Text('Pickup',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.green)),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.arrow_forward,
                              color: AppTheme.primary.withAlpha(120)),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Icon(Icons.flag,
                                  color: Colors.red, size: 20),
                              const SizedBox(height: 4),
                              Text('Dropoff',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: controller.progress.value,
                        minHeight: 8,
                        backgroundColor: AppTheme.beige,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          controller.progress.value >= 1.0
                              ? Colors.green
                              : AppTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                        '${(controller.progress.value * 100).toStringAsFixed(0)}% Complete',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('Progress Steps',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _ProgressStep(
                title: 'Accepted',
                subtitle: 'Job has been assigned to you',
                isComplete: controller.progress.value >= 0.1,
                isActive: controller.progress.value >= 0.1 &&
                    controller.progress.value < 0.3,
              ),
              _ProgressStep(
                title: 'Arrived at Pickup',
                subtitle: job.pickupAddress,
                isComplete: controller.progress.value >= 0.3,
                isActive: controller.progress.value >= 0.3 &&
                    controller.progress.value < 0.5,
              ),
              _ProgressStep(
                title: 'Picked Up',
                subtitle: 'Items collected from pickup location',
                isComplete: controller.progress.value >= 0.5,
                isActive: controller.progress.value >= 0.5 &&
                    controller.progress.value < 0.7,
              ),
              _ProgressStep(
                title: 'In Transit',
                subtitle: 'En route to ${job.dropoffAddress}',
                isComplete: controller.progress.value >= 0.7,
                isActive: controller.progress.value >= 0.7 &&
                    controller.progress.value < 0.9,
              ),
              _ProgressStep(
                title: 'Delivered',
                subtitle: job.dropoffAddress,
                isComplete: controller.progress.value >= 0.9,
                isActive: controller.progress.value >= 0.9,
              ),
              const SizedBox(height: 20),
              const Text('Route Waypoints',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...controller.routeWaypoints.asMap().entries.map((entry) {
                final isLast =
                    entry.key == controller.routeWaypoints.length - 1;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: controller.progress.value >
                              (entry.key / controller.routeWaypoints.length)
                          ? Colors.green
                          : AppTheme.dark.withAlpha(30),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: controller.progress.value >
                                  (entry.key /
                                      controller.routeWaypoints.length)
                              ? Colors.green
                              : AppTheme.primary.withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          controller.progress.value >
                                  (entry.key /
                                      controller.routeWaypoints.length)
                              ? Icons.check
                              : isLast
                                  ? Icons.flag
                                  : Icons.location_on,
                          size: 16,
                          color: controller.progress.value >
                                  (entry.key /
                                      controller.routeWaypoints.length)
                              ? AppTheme.white
                              : AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(entry.value.address,
                            style: const TextStyle(fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (controller.progress.value <=
                          (entry.key / controller.routeWaypoints.length))
                        TextButton(
                          onPressed: () => controller
                              .markWaypointReached(entry.key),
                          child: const Text('Mark',
                              style: TextStyle(
                                  color: AppTheme.primary, fontSize: 12)),
                        ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
              const Text('Customer',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.primary.withAlpha(30),
                      child: Text(
                          job.customerName
                              .split(' ')
                              .map((n) => n[0])
                              .join(''),
                          style: const TextStyle(color: AppTheme.primary)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(job.customerName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          Text(job.customerPhone,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.dark.withAlpha(150))),
                        ],
                      ),
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.phone, color: AppTheme.primary),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.message,
                          color: AppTheme.primary),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.progress.value < 1.0
                      ? () => controller.updateProgress()
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: controller.progress.value >= 1.0
                        ? Colors.green
                        : AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    controller.progress.value >= 1.0
                        ? 'Delivery Complete'
                        : 'Mark Next Step',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }
}

class _ProgressStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isComplete;
  final bool isActive;

  const _ProgressStep({
    required this.title,
    required this.subtitle,
    required this.isComplete,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isComplete
            ? Colors.green.withAlpha(15)
            : isActive
                ? AppTheme.primary.withAlpha(15)
                : AppTheme.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isComplete
              ? Colors.green
              : isActive
                  ? AppTheme.primary
                  : AppTheme.dark.withAlpha(25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isComplete
                  ? Colors.green
                  : isActive
                      ? AppTheme.primary
                      : AppTheme.dark.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isComplete ? Icons.check : Icons.circle_outlined,
              size: 16,
              color: isComplete || isActive
                  ? AppTheme.white
                  : AppTheme.dark.withAlpha(80),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isComplete || isActive
                          ? AppTheme.dark
                          : AppTheme.dark.withAlpha(100),
                    )),
                Text(subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isComplete || isActive
                          ? AppTheme.dark.withAlpha(150)
                          : AppTheme.dark.withAlpha(80),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
