import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:urban_goodz_vendor/controllers/vendor_auth_controller.dart';
import 'package:urban_goodz_vendor/screens/dashboard_screen.dart';
import 'package:urban_goodz_vendor/screens/vendor_onboarding_screen.dart';
import 'package:urban_goodz_vendor/theme/app_theme.dart';
import 'package:urban_goodz_vendor/repositories/vendor_repository.dart';
import 'package:urban_goodz_vendor/services/vendor_api_client.dart';
import 'package:urban_goodz_vendor/services/vendor_realtime_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final api = Get.put(VendorApiClient(), permanent: true);
    final realtime = Get.put(VendorRealtimeService(), permanent: true);
    Get.put(VendorRepository(api), permanent: true);
    final authController = Get.put(
      VendorAuthController(Get.find<VendorRepository>(), api, realtime),
      permanent: true,
    );
    return Obx(() {
      return GetMaterialApp(
        title: 'Urban Goodz Vendor',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: !authController.isInitialized.value
            ? const Scaffold(body: Center(child: CircularProgressIndicator()))
            : authController.isLoggedIn.value
            ? DashboardScreen()
            : const VendorOnboardingScreen(),
      );
    });
  }
}
