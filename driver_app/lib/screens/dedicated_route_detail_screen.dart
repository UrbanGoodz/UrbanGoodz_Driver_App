import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:urban_goodz_driver/controllers/dedicated_route_controller.dart';
import 'package:urban_goodz_driver/screens/dedicated_route_manifest_screen.dart';
import 'package:urban_goodz_driver/theme/app_theme.dart';

class DedicatedRouteDetailScreen extends StatefulWidget {
  final int routeId;
  const DedicatedRouteDetailScreen({super.key, required this.routeId});

  @override
  State<DedicatedRouteDetailScreen> createState() => _DedicatedRouteDetailScreenState();
}

class _DedicatedRouteDetailScreenState extends State<DedicatedRouteDetailScreen> {
  final DedicatedRouteController controller = Get.find<DedicatedRouteController>();
  String _selectedPreference = 'no_preference';

  @override
  void initState() {
    super.initState();
    controller.fetchRouteDetail(widget.routeId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Overview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.fetchRouteDetail(widget.routeId),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final route = controller.currentRoute.value;
        if (route == null) {
          return const Center(child: Text('Route details not found.'));
        }

        return Column(
          children: [
            if (controller.isOffline.value)
              Container(
                color: Colors.orange.shade800,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: const Text(
                  'Working Offline — Cached details displayed',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            if (route.status == 'admin_review')
              Container(
                color: Colors.amber.shade900,
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.white),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'PENDING DISPATCHER REVIEW: Resequencing variance exceeded limits. Awaiting approval.',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Route Header Info Card
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Route ${route.routeName}',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Type: ${route.routeType.toUpperCase()}',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                            ),
                            const Divider(height: 24),
                            _buildStatRow(Icons.pin_drop, 'Pickup Location', route.pickupLocation),
                            const SizedBox(height: 10),
                            _buildStatRow(Icons.inventory, 'Total Packages', '${route.totalPackages} Items'),
                            const SizedBox(height: 10),
                            _buildStatRow(Icons.payments, 'Estimated Payout', '\$${(route.totalPackages * route.driverPayPerPackage).toStringAsFixed(2)}'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Resequencing preferences
                    if (route.status == 'planned' || route.status == 'started' || route.status == 'admin_review') ...[
                      const Text(
                        'Resequence Stop Order',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Select your preferred ending point:',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _selectedPreference,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'no_preference', child: Text('No Preference (Open Loop)')),
                                  DropdownMenuItem(value: 'company_endpoint', child: Text('Return to Company Endpoint')),
                                  DropdownMenuItem(value: 'return_to_pickup', child: Text('Return to Pickup Hub')),
                                  DropdownMenuItem(value: 'private_endpoint', child: Text('Ending at Approved Home Address')),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedPreference = val);
                                  }
                                },
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: const Icon(Icons.gesture, color: Colors.white),
                                  label: const Text('Optimize Stop Order', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  onPressed: () {
                                    controller.resequenceRoute(route.id, _selectedPreference);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Navigation Actions
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.list_alt, color: Colors.white),
                            label: const Text('Open Manifest', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              Get.to(() => DedicatedRouteManifestScreen(routeId: route.id));
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Start/Complete Route Action button
                    if (route.status == 'planned')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.play_arrow, color: Colors.white),
                          label: const Text('Start Route / Start Loading', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          onPressed: () => controller.startActiveRoute(route.id),
                        ),
                      )
                    else if (route.status == 'started')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade800,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.check, color: Colors.white),
                          label: const Text('Mark Route Completed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          onPressed: () => controller.completeActiveRoute(route.id),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStatRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}
