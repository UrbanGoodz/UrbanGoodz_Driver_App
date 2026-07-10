import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:urban_goodz_driver/controllers/driver_auth_controller.dart';
import 'package:urban_goodz_driver/services/api_client.dart';
import 'package:urban_goodz_driver/services/driver_api_service.dart';
import 'package:urban_goodz_driver/screens/dashboard_screen.dart';
import 'package:urban_goodz_driver/screens/driver_onboarding_screen.dart';
import 'package:urban_goodz_driver/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.put(DriverAuthController());
    Get.put(ApiClient());
    Get.put(DriverApiService());
    return Obx(() {
      return GetMaterialApp(
        title: 'Urban Goodz Driver',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: authController.isLoggedIn.value
            ? const DashboardScreen()
            : const DriverOnboardingScreen(),
      );
    });
  }
}
