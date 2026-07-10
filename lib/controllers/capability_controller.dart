import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:urban_goodz_driver/services/driver_api_service.dart';
import 'package:urban_goodz_driver/services/api_client.dart';
import 'package:urban_goodz_driver/models/capability_model.dart';

/// Loads the driver capability/vehicle profile and persists each editable
/// section. Capability is driver-owned; no claim/assignment behavior.
class CapabilityController extends GetxController {
  final DriverApiService _api = Get.find<DriverApiService>();

  var profile = Rxn<CapabilityProfile>();
  var allowed = Rxn<CapabilityAllowedValues>();
  var isLoading = false.obs;
  var isSaving = false.obs;
  var errorMessage = ''.obs;

  Future<void> loadProfile() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final result = await _api.getCapabilityProfile();
      profile.value = result.$1;
      allowed.value = result.$2;
    } catch (e) {
      errorMessage.value = _msg(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _save(Future<CapabilityProfile> Function() call) async {
    isSaving.value = true;
    try {
      profile.value = await call();
      Get.snackbar('Saved', 'Capability updated',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Save failed', _msg(e),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white);
    } finally {
      isSaving.value = false;
    }
  }

  void saveVehicle({String? vehicleType, int? vehicleId}) =>
      _save(() => _api.saveVehicle(vehicleType: vehicleType, vehicleId: vehicleId));

  void saveCargo({
    String? cargoCapacityNotes,
    int? maxPackageCount,
    double? maxWeightLbs,
    bool? hasCargoSpace,
    bool? hasCoolerBag,
    bool? hasMedicalCourierTraining,
    bool? hasLiftgate,
  }) =>
      _save(() => _api.saveCargo(
            cargoCapacityNotes: cargoCapacityNotes,
            maxPackageCount: maxPackageCount,
            maxWeightLbs: maxWeightLbs,
            hasCargoSpace: hasCargoSpace,
            hasCoolerBag: hasCoolerBag,
            hasMedicalCourierTraining: hasMedicalCourierTraining,
            hasLiftgate: hasLiftgate,
          ));

  void saveZones(List<String> zones) =>
      _save(() => _api.saveZones(zones));

  void saveWorkTypes(List<String> workTypes) =>
      _save(() => _api.saveWorkTypes(workTypes));

  void saveTags(List<String> tags) => _save(() => _api.saveTags(tags));

  void saveAvailability({
    String? availabilityPreference,
    bool? availableForBusinessCourier,
    bool? availableForPackageRoutes,
    bool? availableForOrderAnywhere,
    bool? availableForMedicalCourier,
  }) =>
      _save(() => _api.saveAvailability(
            availabilityPreference: availabilityPreference,
            availableForBusinessCourier: availableForBusinessCourier,
            availableForPackageRoutes: availableForPackageRoutes,
            availableForOrderAnywhere: availableForOrderAnywhere,
            availableForMedicalCourier: availableForMedicalCourier,
          ));

  String _msg(Object e) => e is ApiException ? e.message : e.toString();
}
