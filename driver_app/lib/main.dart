import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:urban_goodz_driver/controllers/driver_auth_controller.dart';
import 'package:urban_goodz_driver/services/api_client.dart';
import 'package:urban_goodz_driver/services/driver_api_service.dart';
import 'package:urban_goodz_driver/services/location_service.dart';
import 'package:urban_goodz_driver/screens/dashboard_screen.dart';
import 'package:urban_goodz_driver/screens/driver_onboarding_screen.dart';
import 'package:urban_goodz_driver/screens/splash_screen.dart';
import 'package:urban_goodz_driver/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e, st) {
    debugPrint('[Firebase] initializeApp FAILED: $e');
    debugPrint('[Firebase] $st');
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final DriverAuthController _authController;
  bool _sessionRestored = false;

  @override
  void initState() {
    super.initState();
    _authController = Get.put(DriverAuthController());
    Get.put(ApiClient());
    Get.put(DriverApiService());
    Get.put(LocationService());

    // Any authenticated call rejected with 401 tears the session down once,
    // here, instead of each screen swallowing the failure.
    ApiClient.onUnauthorized = () => _authController.handleSessionExpired();

    // Logout and session expiry both stop GPS reporting, so a signed-out phone
    // never keeps publishing the driver's position.
    _authController.onSessionEnded = () => Get.find<LocationService>().reset();

    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      await _authController.restoreSession().timeout(
        const Duration(seconds: 10),
      );
    } catch (_) {}

    // Resume location reporting only for a session the backend accepted.
    if (_authController.isLoggedIn.value) {
      unawaited(Get.find<LocationService>().resumeIfAvailable());
    }

    if (mounted) {
      setState(() => _sessionRestored = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Urban Goodz Driver',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: _sessionRestored
          ? (_authController.isLoggedIn.value
                ? const DashboardScreen()
                : const DriverOnboardingScreen())
          : const SplashScreen(),
    );
  }
}
