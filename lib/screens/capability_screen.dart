import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:urban_goodz_driver/controllers/capability_controller.dart';
import 'package:urban_goodz_driver/theme/app_theme.dart';

class CapabilityScreen extends StatefulWidget {
  const CapabilityScreen({super.key});

  @override
  State<CapabilityScreen> createState() => _CapabilityScreenState();
}

class _CapabilityScreenState extends State<CapabilityScreen> {
  final CapabilityController controller = Get.find<CapabilityController>();

  final _vehicleCtrl = TextEditingController();
  final _cargoNotesCtrl = TextEditingController();
  final _maxPackagesCtrl = TextEditingController();
  final _maxWeightCtrl = TextEditingController();
  final _zonesCtrl = TextEditingController();
  final _availCtrl = TextEditingController();

  bool _hasCargoSpace = false;
  bool _hasCoolerBag = false;
  bool _hasLiftgate = false;
  bool _hasMedical = false;
  bool _availBusiness = false;
  bool _availPackage = false;
  bool _availOrderAnywhere = false;
  bool _availMedical = false;
  final Set<String> _workTypes = {};
  final Set<String> _tags = {};

  @override
  void initState() {
    super.initState();
    controller.loadProfile().then((_) => _syncFromProfile());
  }

  void _syncFromProfile() {
    final p = controller.profile.value;
    if (p == null) return;
    _vehicleCtrl.text = p.vehicleType ?? '';
    _cargoNotesCtrl.text = p.cargoCapacityNotes ?? '';
    _maxPackagesCtrl.text = p.maxPackageCount?.toString() ?? '';
    _maxWeightCtrl.text = p.maxWeightLbs?.toString() ?? '';
    _zonesCtrl.text = p.preferredZones.join(', ');
    _availCtrl.text = p.availabilityPreference;
    _hasCargoSpace = p.hasCargoSpace;
    _hasCoolerBag = p.hasCoolerBag;
    _hasLiftgate = p.hasLiftgate;
    _hasMedical = p.hasMedicalCourierTraining;
    _availBusiness = p.availableForBusinessCourier;
    _availPackage = p.availableForPackageRoutes;
    _availOrderAnywhere = p.availableForOrderAnywhere;
    _availMedical = p.availableForMedicalCourier;
    _workTypes.clear();
    _workTypes.addAll(p.preferredWorkTypes);
    _tags.clear();
    _tags.addAll(p.capabilityTags);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Capabilities')),
      body: Obx(() {
        if (controller.isLoading.value && controller.profile.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final allowed = controller.allowed.value;
        return RefreshIndicator(
          onRefresh: () async => controller.loadProfile().then((_) => _syncFromProfile()),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Vehicle',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _vehicleCtrl.text.isNotEmpty ? _vehicleCtrl.text : null,
                  decoration: const InputDecoration(labelText: 'Vehicle Type'),
                  items: (allowed?.vehicleTypes ?? [])
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() => _vehicleCtrl.text = v ?? ''),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: controller.isSaving.value
                      ? null
                      : () => controller.saveVehicle(vehicleType: _vehicleCtrl.text),
                  child: const Text('Save Vehicle'),
                ),
                const SizedBox(height: 16),
                const Text('Cargo Capacity',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _cargoNotesCtrl,
                  decoration: const InputDecoration(labelText: 'Cargo notes'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _maxPackagesCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Max packages'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _maxWeightCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Max weight (lbs)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _switch('Has cargo space', _hasCargoSpace,
                    (v) => setState(() => _hasCargoSpace = v)),
                _switch('Has cooler bag', _hasCoolerBag,
                    (v) => setState(() => _hasCoolerBag = v)),
                _switch('Has liftgate', _hasLiftgate,
                    (v) => setState(() => _hasLiftgate = v)),
                _switch('Medical courier training', _hasMedical,
                    (v) => setState(() => _hasMedical = v)),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: controller.isSaving.value
                      ? null
                      : () => controller.saveCargo(
                            cargoCapacityNotes: _cargoNotesCtrl.text,
                            maxPackageCount: int.tryParse(_maxPackagesCtrl.text),
                            maxWeightLbs: double.tryParse(_maxWeightCtrl.text),
                            hasCargoSpace: _hasCargoSpace,
                            hasCoolerBag: _hasCoolerBag,
                            hasLiftgate: _hasLiftgate,
                            hasMedicalCourierTraining: _hasMedical,
                          ),
                  child: const Text('Save Cargo'),
                ),
                const SizedBox(height: 16),
                const Text('Preferred Zones',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _zonesCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Comma-separated, e.g. Houston, TX, Austin, TX'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: controller.isSaving.value
                      ? null
                      : () => controller.saveZones(_zonesCtrl.text
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList()),
                  child: const Text('Save Zones'),
                ),
                const SizedBox(height: 16),
                const Text('Work Types',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _chipGroup(allowed?.preferredWorkTypes ?? [], _workTypes,
                    () => controller.saveWorkTypes(_workTypes.toList())),
                const SizedBox(height: 16),
                const Text('Capability Tags',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _chipGroup(allowed?.capabilityTags ?? [], _tags,
                    () => controller.saveTags(_tags.toList())),
                const SizedBox(height: 16),
                const Text('Availability',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _availCtrl.text.isNotEmpty ? _availCtrl.text : null,
                  decoration: const InputDecoration(labelText: 'Preference'),
                  items: (allowed?.availabilityPreferences ?? [])
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() => _availCtrl.text = v ?? ''),
                ),
                const SizedBox(height: 8),
                _switch('Available: Business Courier', _availBusiness,
                    (v) => setState(() => _availBusiness = v)),
                _switch('Available: Package Routes', _availPackage,
                    (v) => setState(() => _availPackage = v)),
                _switch('Available: Order Anywhere', _availOrderAnywhere,
                    (v) => setState(() => _availOrderAnywhere = v)),
                _switch('Available: Medical Courier', _availMedical,
                    (v) => setState(() => _availMedical = v)),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: controller.isSaving.value
                      ? null
                      : () => controller.saveAvailability(
                            availabilityPreference: _availCtrl.text,
                            availableForBusinessCourier: _availBusiness,
                            availableForPackageRoutes: _availPackage,
                            availableForOrderAnywhere: _availOrderAnywhere,
                            availableForMedicalCourier: _availMedical,
                          ),
                  child: const Text('Save Availability'),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _switch(String label, bool value, ValueChanged<bool> onChanged) =>
      SwitchListTile(
        title: Text(label),
        value: value,
        activeColor: AppTheme.primary,
        onChanged: onChanged,
        contentPadding: EdgeInsets.zero,
      );

  Widget _chipGroup(List<String> options, Set<String> selected, VoidCallback onSave) {
    final opts = options.isEmpty
        ? selected.toList()
        : options;
    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: opts.map((o) {
            final isSel = selected.contains(o);
            return FilterChip(
              label: Text(o),
              selected: isSel,
              onSelected: (v) => setState(() {
                if (v) selected.add(o); else selected.remove(o);
              }),
              backgroundColor: AppTheme.beige,
              selectedColor: AppTheme.primary,
              checkmarkColor: AppTheme.white,
              labelStyle: TextStyle(color: isSel ? AppTheme.white : AppTheme.dark),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        ElevatedButton(onPressed: controller.isSaving.value ? null : onSave,
            child: const Text('Save')),
      ],
    );
  }
}
