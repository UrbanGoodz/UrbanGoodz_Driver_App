import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:urban_goodz_driver/controllers/dedicated_route_controller.dart';
import 'package:urban_goodz_driver/models/dedicated_route_model.dart';
import 'package:urban_goodz_driver/theme/app_theme.dart';

class DedicatedRouteManifestScreen extends StatefulWidget {
  final int routeId;
  const DedicatedRouteManifestScreen({super.key, required this.routeId});

  @override
  State<DedicatedRouteManifestScreen> createState() => _DedicatedRouteManifestScreenState();
}

class _DedicatedRouteManifestScreenState extends State<DedicatedRouteManifestScreen> {
  final DedicatedRouteController controller = Get.find<DedicatedRouteController>();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _scanController = TextEditingController();
  String _searchQuery = '';
  bool _showScanInput = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Manifest'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              setState(() => _showScanInput = !_showScanInput);
            },
          ),
        ],
      ),
      body: Obx(() {
        final route = controller.currentRoute.value;
        if (route == null) {
          return const Center(child: Text('Loading route...'));
        }

        // Filter stops based on search query
        final filteredStops = controller.stops.where((stop) {
          if (_searchQuery.isEmpty) return true;
          return stop.address.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              stop.packages.any((p) =>
                  p.barcode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  p.trackingId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  p.dropoffName.toLowerCase().contains(_searchQuery.toLowerCase()));
        }).toList();

        return Column(
          children: [
            // Offline/Sync Banner
            if (controller.isOffline.value)
              Container(
                color: Colors.orange.shade800,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: const Text(
                  'Offline Mode — Operations will be queued locally',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            if (controller.pendingActions.isNotEmpty)
              Container(
                color: Colors.blue.shade900,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${controller.pendingActions.length} pending actions offline.',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: Colors.white),
                      icon: const Icon(Icons.sync, size: 18),
                      label: const Text('SYNC NOW'),
                      onPressed: () => controller.syncOfflineActions(),
                    ),
                  ],
                ),
              ),

            // Scan Input simulation bar
            if (_showScanInput)
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.grey.shade200,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _scanController,
                        decoration: const InputDecoration(
                          hintText: 'Enter barcode to simulate scan...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          fillColor: Colors.white,
                          filled: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                      onPressed: () {
                        final barcode = _scanController.text.trim();
                        if (barcode.isNotEmpty) {
                          _handlePackageScan(barcode);
                          _scanController.clear();
                          setState(() => _showScanInput = false);
                        }
                      },
                      child: const Text('Scan', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search stops, tracking ID, or barcode...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onChanged: (val) {
                  setState(() => _searchQuery = val.trim());
                },
              ),
            ),

            // Virtualized Stops List
            Expanded(
              child: filteredStops.isEmpty
                  ? const Center(child: Text('No matching stops found.'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: filteredStops.length,
                      itemBuilder: (context, index) {
                        final stop = filteredStops[index];
                        return _StopCard(stop: stop, routeId: route.id, onScanPickup: (barcode) {
                          controller.recordLoadingScan(route.id, barcode);
                        });
                      },
                    ),
            ),
          ],
        );
      }),
    );
  }

  void _handlePackageScan(String barcode) {
    // 1. Check if the scanned barcode belongs to any package in the manifest
    RoutePackageModel? matchingPkg;
    for (var stop in controller.stops) {
      for (var pkg in stop.packages) {
        if (pkg.barcode.toLowerCase() == barcode.toLowerCase() ||
            pkg.trackingId.toLowerCase() == barcode.toLowerCase()) {
          matchingPkg = pkg;
          break;
        }
      }
    }

    if (matchingPkg == null) {
      Get.snackbar(
        'Package Not Found',
        'Barcode "$barcode" does not match any package on this route.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // 2. Determine action based on current package status
    if (matchingPkg.status == 'pending') {
      // Perform loading scan (intake scan)
      controller.recordLoadingScan(controller.currentRoute.value!.id, matchingPkg.barcode);
      Get.snackbar(
        'Intake Loaded',
        'Package ${matchingPkg.trackingId} marked as Loaded.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      // Highlight/Scroll/Show info or filter by this query
      setState(() {
        _searchController.text = matchingPkg!.barcode;
        _searchQuery = matchingPkg.barcode;
      });
      Get.snackbar(
        'Package Found',
        'Stop #${matchingPkg.stopOrder}: ${matchingPkg.dropoffName} at ${matchingPkg.dropoffAddress}',
        backgroundColor: AppTheme.primary,
        colorText: Colors.white,
      );
    }
  }
}

class _StopCard extends StatelessWidget {
  final RouteStopModel stop;
  final int routeId;
  final Function(String) onScanPickup;

  const _StopCard({
    required this.stop,
    required this.routeId,
    required this.onScanPickup,
  });

  @override
  Widget build(BuildContext context) {
    final DedicatedRouteController controller = Get.find();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: CircleAvatar(
          backgroundColor: stop.isCompleted
              ? Colors.green.shade100
              : (stop.isArrived ? Colors.orange.shade100 : Colors.blue.shade100),
          child: Text(
            '#${stop.stopOrder}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: stop.isCompleted
                  ? Colors.green.shade800
                  : (stop.isArrived ? Colors.orange.shade800 : Colors.blue.shade800),
            ),
          ),
        ),
        title: Text(
          stop.address,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Row(
          children: [
            Text('${stop.packages.length} packages'),
            const SizedBox(width: 8),
            if (stop.isLocked)
              const Row(
                children: [
                  Icon(Icons.lock, size: 14, color: Colors.red),
                  SizedBox(width: 2),
                  Text('LOCKED', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // List of packages in the stop
                ...stop.packages.map((pkg) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${pkg.dropoffName} (${pkg.trackingId})',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              Text('Barcode: ${pkg.barcode}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              if (pkg.deliveryWindowStart != null)
                                Text('Window: ${pkg.deliveryWindowStart} - ${pkg.deliveryWindowEnd}',
                                    style: const TextStyle(fontSize: 11, color: Colors.blue)),
                              if (pkg.status == 'failed')
                                Text('Failed: ${pkg.exceptionReason ?? 'Reason unrecorded'}',
                                    style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getPackageStatusColor(pkg.status).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            pkg.status.toUpperCase(),
                            style: TextStyle(
                              color: _getPackageStatusColor(pkg.status),
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(),

                // Action Buttons for this Stop
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (stop.packages.any((p) => p.status == 'pending'))
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                        icon: const Icon(Icons.qr_code, size: 16, color: Colors.white),
                        label: const Text('Intake Scan', style: TextStyle(color: Colors.white, fontSize: 12)),
                        onPressed: () {
                          // Scans first pending package
                          final pending = stop.packages.firstWhere((p) => p.status == 'pending');
                          onScanPickup(pending.barcode);
                        },
                      ),
                    if (stop.packages.every((p) => p.status == 'picked_up'))
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                        icon: const Icon(Icons.directions_car, size: 16, color: Colors.white),
                        label: const Text('Arrived', style: TextStyle(color: Colors.white, fontSize: 12)),
                        onPressed: () {
                          for (var p in stop.packages) {
                            controller.updatePackageStatusLocally(p.barcode, 'arrived');
                          }
                        },
                      ),
                    if (stop.packages.any((p) => p.status == 'arrived')) ...[
                      TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        icon: const Icon(Icons.error, size: 16),
                        label: const Text('Fail', style: TextStyle(fontSize: 12)),
                        onPressed: () => _showExceptionDialog(context, controller, stop),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        icon: const Icon(Icons.check, size: 16, color: Colors.white),
                        label: const Text('Deliver', style: TextStyle(color: Colors.white, fontSize: 12)),
                        onPressed: () => _showDeliveryPODDialog(context, controller, stop),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPackageStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.blue;
      case 'picked_up':
        return Colors.orange;
      case 'arrived':
        return Colors.amber.shade800;
      case 'delivered':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'returned':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  void _showDeliveryPODDialog(BuildContext context, DedicatedRouteController controller, RouteStopModel stop) {
    final photoController = TextEditingController();
    final sigController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: Text('Proof of Delivery (Stop #${stop.stopOrder})'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: photoController,
              decoration: const InputDecoration(
                labelText: 'Photo URL / Path (Simulated)',
                hintText: 'e.g. /images/pod_photo.jpg',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: sigController,
              decoration: const InputDecoration(
                labelText: 'Recipient Signature (Simulated)',
                hintText: 'e.g. John Doe',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              final photo = photoController.text.trim();
              final signature = sigController.text.trim();
              for (var pkg in stop.packages) {
                if (pkg.status == 'arrived') {
                  controller.recordDeliveryDropoff(
                    routeId,
                    pkg.barcode,
                    proofPhoto: photo.isNotEmpty ? photo : '/images/mock_photo.png',
                    signature: signature.isNotEmpty ? signature : 'MOCK_SIGNATURE',
                  );
                }
              }
              Get.back();
              Get.snackbar('Delivery Recorded', 'Packages delivered successfully!', backgroundColor: Colors.green, colorText: Colors.white);
            },
            child: const Text('Submit Delivery', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showExceptionDialog(BuildContext context, DedicatedRouteController controller, RouteStopModel stop) {
    String selectedReason = 'recipient_unavailable';
    final reasons = {
      'recipient_unavailable': 'Recipient Unavailable',
      'address_inaccessible': 'Address Inaccessible / Gate Code Missing',
      'damaged_package': 'Damaged Package',
      'refused_delivery': 'Refused by Recipient',
    };

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Record Exception (Stop #${stop.stopOrder})'),
            content: DropdownButtonFormField<String>(
              value: selectedReason,
              items: reasons.entries.map((e) {
                return DropdownMenuItem(value: e.key, child: Text(e.value));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setDialogState(() => selectedReason = val);
                }
              },
            ),
            actions: [
              TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  for (var pkg in stop.packages) {
                    if (pkg.status == 'arrived') {
                      controller.recordDeliveryException(routeId, pkg.barcode, selectedReason);
                    }
                  }
                  Get.back();
                  Get.snackbar('Exception Logged', 'Packages updated to Failed / Returned status.', backgroundColor: Colors.orange, colorText: Colors.white);
                },
                child: const Text('Confirm Failure', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      ),
    );
  }
}
