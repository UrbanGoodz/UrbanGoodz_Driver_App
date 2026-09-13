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
  final TextEditingController _finishAddressController = TextEditingController();
  String _finishMode = 'open';

  @override
  void initState() {
    super.initState();
    controller.fetchRouteDetail(widget.routeId);
  }

  @override
  void dispose() {
    _finishAddressController.dispose();
    super.dispose();
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

                    // Where the run ends. The optimiser adds a final leg to
                    // this point, so the last stop lands nearest to it.
                    if (route.canResequence) ...[
                      const Text(
                        'Where does this run end?',
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
                                'Stops are ordered from the pickup to whichever stop is closest to your finish.',
                                style: TextStyle(fontSize: 13, color: Colors.black54),
                              ),
                              const SizedBox(height: 8),
                              RadioGroup<String>(
                                groupValue: _finishMode,
                                onChanged: (val) {
                                  if (val != null) setState(() => _finishMode = val);
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (final option in const [
                                      ('open', 'No fixed finish', 'End wherever the last stop falls'),
                                      ('hub', 'Back at the pickup hub', 'Return to where the route started'),
                                      ('address', 'At an address', 'Type where you want to finish'),
                                    ])
                                      RadioListTile<String>(
                                        value: option.$1,
                                        contentPadding: EdgeInsets.zero,
                                        dense: true,
                                        title: Text(option.$2, style: const TextStyle(fontWeight: FontWeight.w600)),
                                        subtitle: Text(option.$3, style: const TextStyle(fontSize: 12)),
                                      ),
                                  ],
                                ),
                              ),
                              if (_finishMode == 'address') ...[
                                const SizedBox(height: 4),
                                TextField(
                                  controller: _finishAddressController,
                                  textInputAction: TextInputAction.done,
                                  decoration: InputDecoration(
                                    hintText: 'e.g. 2800 Post Oak Blvd, Houston, TX 77056',
                                    labelText: 'Finish address',
                                    helperText: 'Include the city and ZIP so it matches the right street.',
                                    helperMaxLines: 2,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: const Icon(Icons.alt_route, color: Colors.white),
                                  label: const Text('Sort Stops To Finish', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  onPressed: () {
                                    final address = _finishAddressController.text.trim();

                                    // The server refuses address mode without
                                    // one, but saying so here saves a round
                                    // trip and an error toast.
                                    if (_finishMode == 'address' && address.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Enter the address you want to finish at.'),
                                        ),
                                      );
                                      return;
                                    }

                                    controller.setRouteFinish(
                                      route.id,
                                      mode: _finishMode,
                                      endAddress: _finishMode == 'address' ? address : null,
                                    );
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
                    if (route.canStart)
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
                    else if (route.canComplete)
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
