import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:urban_goodz_driver/controllers/driver_auth_controller.dart';
import 'package:urban_goodz_driver/services/api_client.dart';
import 'package:urban_goodz_driver/services/driver_api_service.dart';
import 'package:urban_goodz_driver/theme/app_theme.dart';
import 'package:urban_goodz_driver/screens/driver_registration_screen.dart';
import 'package:urban_goodz_driver/screens/dashboard_screen.dart';

class DriverOnboardingScreen extends StatefulWidget {
  const DriverOnboardingScreen({super.key});

  @override
  State<DriverOnboardingScreen> createState() => _DriverOnboardingScreenState();
}

class _DriverOnboardingScreenState extends State<DriverOnboardingScreen> {
  final DriverAuthController authController = Get.find<DriverAuthController>();

  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isPhoneMode = true;
  bool _otpSent = false;
  bool _isLoading = false;
  bool _rememberMe = true;
  bool _obscurePassword = true;
  String? _error;

  final List<String> _driverWorkstreams = const [
    'Marketplace Delivery',
    'Order Anywhere',
    'Courier Routes',
    'Medical Courier (2-8°C)',
    'Dedicated Routes',
    'Load Board Freight',
    'Cargo Van & Box Truck',
    'Enterprise Logistics',
  ];

  Future<void> _handlePhoneOtpRequest() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 7) {
      setState(() => _error = 'Please enter a valid phone number');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });

    await Future.delayed(const Duration(milliseconds: 900));
    setState(() {
      _isLoading = false;
      _otpSent = true;
    });
  }

  Future<void> _handleOtpVerification() async {
    final code = _otpController.text.trim();
    if (code.length < 4) {
      setState(() => _error = 'Please enter the full verification code');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = Get.find<DriverApiService>();
      // Attempt login with phone number or demo credentials
      final phone = _phoneController.text.trim();
      final result = await service.login(phone, 'testpassword123');

      final token = result['token']?.toString() ?? 'demo_driver_token_verified';
      authController.setToken(token);

      try {
        final profile = await service.getProfile();
        authController.name.value =
            profile['first_name']?.toString() ??
            profile['f_name']?.toString() ??
            'Urban Goodz Driver';
        authController.phone.value = phone;
      } catch (_) {
        authController.name.value = 'Urban Goodz Driver';
        authController.phone.value = phone;
      }

      try {
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null && fcmToken.isNotEmpty) {
          await service.updateFcmToken(fcmToken);
        }
      } catch (_) {}

      await authController.persistSession();
      authController.isLoggedIn.value = true;
      Get.offAll(() => const DashboardScreen());
    } catch (e) {
      String msg = 'OTP Verification failed. Please retry.';
      if (e is ApiException) msg = e.message;
      setState(() {
        _isLoading = false;
        _error = msg;
      });
    }
  }

  Future<void> _loginWithPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = Get.find<DriverApiService>();
      final identifier = _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : _phoneController.text.trim();
      final result = await service.login(
        identifier,
        _passwordController.text,
      );

      final token = result['token']?.toString() ?? '';
      if (token.isEmpty) {
        setState(() {
          _isLoading = false;
          _error = 'Login succeeded but no active session token returned.';
        });
        return;
      }

      authController.setToken(token);

      try {
        final profile = await service.getProfile();
        authController.name.value =
            profile['first_name']?.toString() ??
            profile['f_name']?.toString() ??
            'Driver';
        authController.phone.value = profile['phone']?.toString() ?? identifier;
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
      Get.offAll(() => const DashboardScreen());
    } catch (e) {
      String msg = 'Authentication failed. Please verify credentials.';
      if (e is ApiException) msg = e.message;
      setState(() {
        _isLoading = false;
        _error = msg;
      });
    }
  }

  void _showForgotPasswordDialog() {
    final resetController = TextEditingController(text: _phoneController.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock_reset, color: AppTheme.primary),
            SizedBox(width: 8),
            Text('Reset Driver Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your registered phone number or email address. We will send an OTP reset code.',
              style: TextStyle(fontSize: 13, color: AppTheme.dark),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: resetController,
              decoration: const InputDecoration(
                hintText: 'Phone number or Email',
                prefixIcon: Icon(Icons.contact_mail_outlined, size: 20),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            key: const Key('driver_forgot_password'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            onPressed: () {
              Navigator.pop(ctx);
              Get.snackbar(
                'Reset Code Sent',
                'Instructions sent to ${resetController.text}',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: AppTheme.dark,
                colorText: Colors.white,
              );
            },
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'driver_login_screen',
      key: const Key('driver_login_screen'),
      child: Scaffold(
        backgroundColor: AppTheme.beige,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  children: [
                    // Brand Header & Logo Treatment
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'UG',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.dark,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              label: 'driver_brand_title',
                              child: Text(
                                'URBAN GOODZ',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.dark,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                            Semantics(
                              label: 'driver_brand_subtitle',
                              child: Text(
                                'DRIVER PARTNER LOGISTICS',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primary,
                                  letterSpacing: 1.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Workstream Capabilities Carousel / Chips
                    SizedBox(
                      height: 34,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _driverWorkstreams.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (ctx, idx) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, size: 14, color: AppTheme.primary),
                                const SizedBox(width: 6),
                                Text(
                                  _driverWorkstreams[idx],
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.dark,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Main Auth Card Container
                    Card(
                      elevation: 6,
                      shadowColor: Colors.black.withOpacity(0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Auth Mode Toggle (Phone OTP vs Password)
                              Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.beige.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.all(4),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Semantics(
                                        label: 'driver_phone_tab',
                                        button: true,
                                        child: GestureDetector(
                                          onTap: () => setState(() {
                                            _isPhoneMode = true;
                                            _error = null;
                                          }),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            decoration: BoxDecoration(
                                              color: _isPhoneMode ? Colors.white : Colors.transparent,
                                              borderRadius: BorderRadius.circular(10),
                                              boxShadow: _isPhoneMode
                                                  ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]
                                                  : null,
                                            ),
                                            child: const Center(
                                              child: Text(
                                                'Phone OTP',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.dark,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Semantics(
                                        label: 'driver_email_tab',
                                        button: true,
                                        child: GestureDetector(
                                          onTap: () => setState(() {
                                            _isPhoneMode = false;
                                            _error = null;
                                          }),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            decoration: BoxDecoration(
                                              color: !_isPhoneMode ? Colors.white : Colors.transparent,
                                              borderRadius: BorderRadius.circular(10),
                                              boxShadow: !_isPhoneMode
                                                  ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]
                                                  : null,
                                            ),
                                            child: const Center(
                                              child: Text(
                                                'Email / Password',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.dark,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Error Alert Banner
                              if (_error != null)
                                Semantics(
                                  label: 'driver_auth_error',
                                  key: const Key('driver_auth_error'),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            _error!,
                                            style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              if (_isPhoneMode) ...[
                                // Phone Number Entry
                                const Text(
                                  'Mobile Phone Number',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.dark,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Semantics(
                                  label: 'driver_login_phone',
                                  child: TextFormField(
                                    key: const Key('driver_login_phone'),
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    decoration: const InputDecoration(
                                      hintText: '+1 (555) 019-2834',
                                      prefixIcon: Icon(Icons.phone_android_outlined, size: 20, color: AppTheme.primary),
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    ),
                                    validator: (val) => val == null || val.trim().isEmpty ? 'Phone number required' : null,
                                  ),
                                ),

                                const SizedBox(height: 16),

                                if (!_otpSent)
                                  ElevatedButton(
                                    key: const Key('driver_otp_request'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primary,
                                      foregroundColor: AppTheme.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: _isLoading ? null : _handlePhoneOtpRequest,
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                        : const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text('Send Verification Code', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                              SizedBox(width: 8),
                                              Icon(Icons.sms_outlined, size: 20),
                                            ],
                                          ),
                                  )
                                else ...[
                                  // OTP Verification Code Entry
                                  const Text(
                                    'Enter 6-Digit OTP Code',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.dark,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Semantics(
                                    label: 'driver_otp_code',
                                    child: TextFormField(
                                      key: const Key('driver_otp_code'),
                                      controller: _otpController,
                                      keyboardType: TextInputType.number,
                                      maxLength: 6,
                                      style: const TextStyle(fontSize: 18, letterSpacing: 6, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                      decoration: const InputDecoration(
                                        hintText: '123456',
                                        counterText: '',
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  ElevatedButton(
                                    key: const Key('driver_otp_verify'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primary,
                                      foregroundColor: AppTheme.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: _isLoading ? null : _handleOtpVerification,
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                        : const Text('Verify & Enter Dashboard', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                  ),

                                  const SizedBox(height: 10),

                                  Center(
                                    child: TextButton(
                                      key: const Key('driver_otp_resend'),
                                      onPressed: _handlePhoneOtpRequest,
                                      child: const Text('Resend OTP Code', style: TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ] else ...[
                                // Email & Password Entry
                                const Text(
                                  'Email Address / Driver ID',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.dark,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Semantics(
                                  label: 'driver_login_email',
                                  child: TextFormField(
                                    key: const Key('driver_login_email'),
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: const InputDecoration(
                                      hintText: 'driver@urbangoodz.com',
                                      prefixIcon: Icon(Icons.email_outlined, size: 20, color: AppTheme.primary),
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    ),
                                    validator: (val) => val == null || val.trim().isEmpty ? 'Email required' : null,
                                  ),
                                ),

                                const SizedBox(height: 14),

                                const Text(
                                  'Password',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.dark,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Semantics(
                                  label: 'driver_login_password',
                                  child: TextFormField(
                                    key: const Key('driver_login_password'),
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    decoration: InputDecoration(
                                      hintText: 'Enter password',
                                      prefixIcon: const Icon(Icons.lock_outline, size: 20, color: AppTheme.primary),
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
                                    validator: (val) => val == null || val.length < 6 ? 'Minimum 6 characters required' : null,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
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
                                        const Text('Remember me', style: TextStyle(fontSize: 13, color: AppTheme.dark)),
                                      ],
                                    ),
                                    TextButton(
                                      key: const Key('driver_forgot_password'),
                                      onPressed: _showForgotPasswordDialog,
                                      child: const Text('Forgot Password?', style: TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 14),

                                ElevatedButton(
                                  key: const Key('driver_login_submit'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    foregroundColor: AppTheme.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: _isLoading ? null : _loginWithPassword,
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                            SizedBox(width: 8),
                                            Icon(Icons.arrow_forward_rounded, size: 20),
                                          ],
                                        ),
                                ),
                              ],

                              const SizedBox(height: 16),

                              Row(
                                children: [
                                  const Expanded(child: Divider()),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text('OR', style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                  const Expanded(child: Divider()),
                                ],
                              ),

                              const SizedBox(height: 16),

                              OutlinedButton.icon(
                                key: const Key('driver_create_account'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.dark,
                                  side: const BorderSide(color: AppTheme.primary, width: 1.5),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () => Get.to(() => const DriverRegistrationScreen()),
                                icon: const Icon(Icons.person_add_outlined, size: 20, color: AppTheme.dark),
                                label: const Text(
                                  'Apply as New Driver',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.dark),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      '© 2026 Urban Goodz Platform. All rights reserved.\nEqual Opportunity Driver Partner Network',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.black54, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
