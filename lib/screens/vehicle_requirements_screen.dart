import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:urban_goodz_driver/controllers/vehicle_requirements_controller.dart';
import 'package:urban_goodz_driver/theme/app_theme.dart';

class VehicleRequirementsScreen extends StatefulWidget {
  const VehicleRequirementsScreen({super.key});

  @override
  State<VehicleRequirementsScreen> createState() =>
      _VehicleRequirementsScreenState();
}

class _VehicleRequirementsScreenState extends State<VehicleRequirementsScreen> {
  final VehicleRequirementsController controller =
      Get.put(VehicleRequirementsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Requirements'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Vehicle',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...controller.vehicles.map((v) {
                final isSelected =
                    controller.selectedVehicle.value?.id == v.id;
                return GestureDetector(
                  onTap: () => controller.selectVehicle(v.id),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.dark.withAlpha(25),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                            color: AppTheme.dark.withAlpha(15),
                            blurRadius: 6)
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            v.type == 'sedan'
                                ? Icons.directions_car
                                : v.type == 'van'
                                    ? Icons.airport_shuttle
                                    : Icons.local_shipping,
                            color: AppTheme.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${v.year} ${v.make} ${v.model}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                              Text(v.licensePlate,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color:
                                          AppTheme.dark.withAlpha(150))),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle,
                              color: AppTheme.primary, size: 24),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),
              if (controller.selectedVehicle.value != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: AppTheme.dark.withAlpha(15),
                          blurRadius: 8)
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Vehicle Details',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _DetailRow(
                          label: 'Make',
                          value:
                              controller.selectedVehicle.value!.make),
                      _DetailRow(
                          label: 'Model',
                          value:
                              controller.selectedVehicle.value!.model),
                      _DetailRow(
                          label: 'Year',
                          value: controller
                              .selectedVehicle.value!.year
                              .toString()),
                      _DetailRow(
                          label: 'Color',
                          value:
                              controller.selectedVehicle.value!.color),
                      _DetailRow(
                          label: 'License Plate',
                          value: controller
                              .selectedVehicle.value!.licensePlate),
                      _DetailRow(
                          label: 'Mileage',
                          value:
                              '${controller.selectedVehicle.value!.mileage.toStringAsFixed(0)} mi'),
                      _DetailRow(
                          label: 'Last Maintenance',
                          value: controller
                              .selectedVehicle.value!.lastMaintenance),
                      _DetailRow(
                          label: 'Next Maintenance',
                          value: controller
                              .selectedVehicle.value!.nextMaintenance),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Requirements Checklist',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...controller.requirementChecklist.entries.map((e) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: e.value
                            ? Colors.green.withAlpha(60)
                            : Colors.red.withAlpha(60),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          e.value
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: e.value ? Colors.green : Colors.red,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(e.key,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14)),
                        ),
                        Text(
                          e.value ? 'Passed' : 'Needs Review',
                          style: TextStyle(
                            color:
                                e.value ? Colors.green : Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 20),
                const Text('Insurance & Registration',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: AppTheme.dark.withAlpha(15),
                          blurRadius: 8)
                    ],
                  ),
                  child: Column(
                    children: [
                      _DetailRow(
                          label: 'Insurance Provider',
                          value: controller
                              .selectedVehicle.value!.insuranceProvider),
                      _DetailRow(
                          label: 'Insurance Expiry',
                          value: controller
                              .selectedVehicle.value!.insuranceExpiry),
                      const Divider(height: 20),
                      _DetailRow(
                          label: 'Registration Expiry',
                          value: controller
                              .selectedVehicle.value!.registrationExpiry),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Maintenance Schedule',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: AppTheme.dark.withAlpha(15),
                          blurRadius: 8)
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Text(
                              'Last: ${controller.selectedVehicle.value!.lastMaintenance}',
                              style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.schedule,
                              color: AppTheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                              'Next: ${controller.selectedVehicle.value!.nextMaintenance}',
                              style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13, color: AppTheme.dark.withAlpha(150))),
          Text(value,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
