import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:urban_goodz_driver/controllers/dedicated_route_controller.dart';
import 'package:urban_goodz_driver/screens/dedicated_route_detail_screen.dart';
import 'package:urban_goodz_driver/theme/app_theme.dart';

class DedicatedRouteListScreen extends StatefulWidget {
  const DedicatedRouteListScreen({super.key});

  @override
  State<DedicatedRouteListScreen> createState() => _DedicatedRouteListScreenState();
}

class _DedicatedRouteListScreenState extends State<DedicatedRouteListScreen> {
  final DedicatedRouteController controller = Get.put(DedicatedRouteController());

  @override
  void initState() {
    super.initState();
    controller.fetchAssignedRoutes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assigned Dedicated Routes'),
        actions: [
          Obx(() => controller.pendingActions.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.sync, color: Colors.orange),
                  onPressed: () => controller.syncOfflineActions(),
                )
              : const SizedBox.shrink()),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.fetchAssignedRoutes(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                controller.errorMessage.value,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        return Column(
          children: [
            if (controller.isOffline.value)
              Container(
                color: Colors.orange.shade800,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: const Text(
                  'Working Offline — Manifest loaded from local storage cache',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            Expanded(
              child: controller.assignedRoutes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.directions_car, size: 64, color: AppTheme.dark.withAlpha(60)),
                          const SizedBox(height: 16),
                          const Text(
                            'No dedicated routes assigned',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => controller.fetchAssignedRoutes(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: controller.assignedRoutes.length,
                        itemBuilder: (context, index) {
                          final route = controller.assignedRoutes[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: () {
                                Get.to(() => DedicatedRouteDetailScreen(routeId: route.id));
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Route ${route.routeName}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(route.status).withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            route.status.toUpperCase(),
                                            style: TextStyle(
                                              color: _getStatusColor(route.status),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 20),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, size: 18, color: Colors.grey),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'Pickup: ${route.pickupLocation}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(color: Colors.grey),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${route.totalPackages} Packages',
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          'Est. Payout: \$${(route.totalPackages * route.driverPayPerPackage).toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color: AppTheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      }),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'planned':
        return Colors.blue;
      case 'started':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'admin_review':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
