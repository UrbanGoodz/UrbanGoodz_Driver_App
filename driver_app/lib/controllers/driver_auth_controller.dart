import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:urban_goodz_driver/screens/driver_onboarding_screen.dart';

class DriverAuthController extends GetxController {
  var isLoggedIn = false.obs;

  var token = ''.obs;
  var name = ''.obs;
  var phone = ''.obs;
  var email = ''.obs;
  var city = ''.obs;
  var vehicleType = ''.obs;
  var vehicleDetails = ''.obs;
  var availabilityStatus = 'online'.obs;
  var driverId = 0.obs;

  var serviceOrderAnywhere = true.obs;
  var serviceDelivery = true.obs;
  var serviceCourier = true.obs;
  var serviceMedicalCourier = false.obs;
  var serviceLogistics = false.obs;

  static const _tokenKey = 'driver_auth_token';
  static const _nameKey = 'driver_name';
  static const _phoneKey = 'driver_phone';
  static const _emailKey = 'driver_email';

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString(_tokenKey) ?? '';
    if (savedToken.isNotEmpty) {
      token.value = savedToken;
      name.value = prefs.getString(_nameKey) ?? '';
      phone.value = prefs.getString(_phoneKey) ?? '';
      email.value = prefs.getString(_emailKey) ?? '';
      isLoggedIn.value = true;
    }
  }

  Future<void> persistSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token.value);
    await prefs.setString(_nameKey, name.value);
    await prefs.setString(_phoneKey, phone.value);
    await prefs.setString(_emailKey, email.value);
  }

  void setToken(String value) {
    token.value = value.trim();
  }

  void clearToken() {
    token.value = '';
  }

  void logout() {
    isLoggedIn.value = false;
    clearToken();
    SharedPreferences.getInstance().then((p) => p.clear());
    Get.offAll(() => const DriverOnboardingScreen());
  }
}
