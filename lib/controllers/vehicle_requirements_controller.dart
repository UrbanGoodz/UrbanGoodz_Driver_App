import 'package:get/get.dart';
import 'package:urban_goodz_driver/models/vehicle_model.dart';
import 'package:urban_goodz_driver/repositories/mock_driver_data.dart';

class VehicleRequirementsController extends GetxController {
  final MockVehicleRepository _repository = MockVehicleRepository();

  var vehicles = <VehicleModel>[].obs;
  var selectedVehicle = Rx<VehicleModel?>(null);
  var requirementChecklist = <String, bool>{}.obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    fetchVehicles();
    super.onInit();
  }

  void fetchVehicles() {
    isLoading.value = true;
    _repository.fetchVehicles().then((v) {
      vehicles.value = v;
      if (v.isNotEmpty) {
        selectedVehicle.value = v.first;
        buildChecklist(v.first);
      }
      isLoading.value = false;
    });
  }

  void selectVehicle(String id) {
    final v = vehicles.firstWhere((veh) => veh.id == id);
    selectedVehicle.value = v;
    buildChecklist(v);
  }

  void buildChecklist(VehicleModel vehicle) {
    requirementChecklist.value = {
      'Insurance': vehicle.isInsured,
      'Registration': vehicle.isRegistered,
      'Vehicle Inspection': vehicle.certifications
          .any((c) => c.contains('Inspection')),
      'Emissions Test':
          vehicle.certifications.any((c) => c.contains('Emissions')),
      'Cargo Restraint': vehicle.certifications
          .any((c) => c.contains('Cargo Restraint')),
    };
  }

  void checkRequirement(String key) {
    if (requirementChecklist.containsKey(key)) {
      requirementChecklist[key] = !requirementChecklist[key]!;
      requirementChecklist.refresh();
    }
  }
}
