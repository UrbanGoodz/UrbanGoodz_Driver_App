import 'package:get/get.dart';

class DriverAuthController extends GetxController {
  var isLoggedIn = false.obs;

  // Driver bearer token (Sanctum-style delivery_man token). Empty until login.
  // Injected into every API request by ApiClient.
  var token = ''.obs;

  void setToken(String value) {
    token.value = value.trim();
  }

  void clearToken() {
    token.value = '';
  }

  var name = 'James Doe'.obs;
  var phone = '+1 (713) 555-0100'.obs;
  var email = 'james.doe@urbangoodz.com'.obs;
  var city = 'Houston, TX'.obs;
  var vehicleType = 'Sedan'.obs;
  var vehicleDetails = 'Toyota Camry 2022'.obs;
  var availabilityStatus = 'online'.obs;

  var serviceOrderAnywhere = true.obs;
  var serviceDelivery = true.obs;
  var serviceCourier = true.obs;
  var serviceMedicalCourier = false.obs;
  var serviceLogistics = false.obs;

  void logout() {
    isLoggedIn.value = false;
    clearToken();
  }
}
