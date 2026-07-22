import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:urban_goodz_driver/controllers/driver_auth_controller.dart';
import 'package:urban_goodz_driver/services/api_client.dart';
import 'package:urban_goodz_driver/services/driver_api_service.dart';
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
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      await _authController.restoreSession().timeout(const Duration(seconds: 10));
    } catch (_) {}
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
