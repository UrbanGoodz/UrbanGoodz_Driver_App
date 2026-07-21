import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:urban_goodz_driver/controllers/driver_auth_controller.dart';
import 'package:urban_goodz_driver/services/api_client.dart';
import 'package:urban_goodz_driver/services/driver_api_service.dart';
import 'package:urban_goodz_driver/theme/app_theme.dart';
import 'package:urban_goodz_driver/screens/driver_registration_screen.dart';

class DriverOnboardingScreen extends StatefulWidget {
  const DriverOnboardingScreen({super.key});

  @override
  State<DriverOnboardingScreen> createState() => _DriverOnboardingScreenState();
}

class _DriverOnboardingScreenState extends State<DriverOnboardingScreen> {
  final DriverAuthController authController = Get.find<DriverAuthController>();

  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _rememberMe = true;
  bool _obscurePassword = true;
  String? _error;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = Get.find<DriverApiService>();
      final result = await service.login(
        _phoneController.text.trim(),
        _passwordController.text,
      );

      final token = result['token']?.toString() ?? '';
      if (token.isEmpty) {
        setState(() {
          _isLoading = false;
          _error = 'Login succeeded but no token was returned.';
        });
        return;
      }

      authController.setToken(token);

      try {
        final profile = await service.getProfile();
        authController.name.value =
            profile['first_name']?.toString() ??
            profile['f_name']?.toString() ??
            '';
        authController.phone.value =
            profile['phone']?.toString() ?? _phoneController.text;
        authController.email.value = profile['email']?.toString() ?? '';
        authController.driverId.value =
            int.tryParse(profile['id']?.toString() ?? '') ?? 0;
      } catch (_) {}

      try {
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null && fcmToken.isNotEmpty) {
          await service.updateFcmToken(fcmToken);
        }
      } catch (_) {}

      await authController.persistSession();
      authController.isLoggedIn.value = true;
    } catch (e) {
      String msg = 'Login failed. Please check your credentials.';
      if (e is ApiException) {
        msg = e.message;
      }
      setState(() {
        _isLoading = false;
        _error = msg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.beige,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  Card(
                    elevation: 4,
                    shadowColor: Colors.black.withOpacity(0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: const BoxDecoration(
                                  color: AppTheme.accent,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person_outline,
                                  color: AppTheme.dark,
                                  size: 30,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Center(
                              child: Text(
                                'Urban Goodz Driver',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.dark,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                            const Center(
                              child: Text(
                                'Driver Login',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Center(
                              child: Text(
                                'Welcome back! Sign in to accept loads, manage routes, and track your earnings.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (_error != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                                ),
                                child: Text(
                                  _error!,
                                  style: const TextStyle(color: Colors.red, fontSize: 13),
                                ),
                              ),
                            const Text(
                              'Phone Number / Email',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.dark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                hintText: 'Enter phone or email',
                                prefixIcon: Icon(Icons.phone_outlined, size: 20),
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (val) =>
                                  val == null || val.trim().isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Password',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.dark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                hintText: 'Enter password',
                                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              validator: (val) => val == null || val.length < 6
                                  ? 'Minimum 6 characters'
                                  : null,
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: Checkbox(
                                        value: _rememberMe,
                                        activeColor: AppTheme.primary,
                                        onChanged: (val) => setState(() => _rememberMe = val ?? true),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Remember me',
                                      style: TextStyle(fontSize: 13, color: AppTheme.dark, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                                TextButton(
                                  onPressed: () {},
                                  child: const Text(
                                    'Forgot Password?',
                                    style: TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: AppTheme.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: _isLoading ? null : _login,
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Sign In',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(Icons.arrow_forward_rounded, size: 20),
                                      ],
                                    ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Expanded(child: Divider()),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text('or', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                ),
                                const Expanded(child: Divider()),
                              ],
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              key: const Key('driver_signup_button'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.dark,
                                side: const BorderSide(color: AppTheme.primary, width: 1.5),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () => Get.to(() => const DriverRegistrationScreen()),
                              icon: const Icon(Icons.person_add_outlined, size: 20, color: AppTheme.dark),
                              label: const Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.dark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '© 2026 Urban Goodz. All rights reserved.\nPowered by Urban Goodz Marketplace',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
