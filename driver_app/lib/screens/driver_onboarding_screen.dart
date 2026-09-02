import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:urban_goodz_driver/controllers/driver_auth_controller.dart';
import 'package:urban_goodz_driver/services/api_client.dart';
import 'package:urban_goodz_driver/services/driver_api_service.dart';
import 'package:urban_goodz_driver/theme/app_theme.dart';
import 'package:urban_goodz_driver/screens/driver_registration_screen.dart';
import 'package:urban_goodz_driver/screens/dashboard_screen.dart';
import 'package:urban_goodz_driver/theme/ug_brand.dart';

class DriverOnboardingScreen extends StatefulWidget {
  const DriverOnboardingScreen({super.key});

  @override
  State<DriverOnboardingScreen> createState() => _DriverOnboardingScreenState();
}

class _DriverOnboardingScreenState extends State<DriverOnboardingScreen> {
  final DriverAuthController authController = Get.find<DriverAuthController>();

  final _formKey = GlobalKey<FormState>();

  /// The backend's login route takes a single `phone` field and matches it
  /// against the driver's registered phone or email, so one input serves both.
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _rememberMe = true;
  bool _obscurePassword = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Explain why a signed-in driver is looking at the login screen again.
    final notice = authController.sessionExpiredNotice.value;
    if (notice.isNotEmpty) {
      _error = notice;
      authController.sessionExpiredNotice.value = '';
    }
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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

  // Phone/OTP sign-in was removed rather than merely disabled. Live probes
  // against admin.urbangoodzdelivery.com/api/v1 on 2026-07-23 found no
  // auth/delivery-man/otp, auth/delivery-man/verify-otp or auth/send-otp route
  // — all return the unregistered-route signature (HTTP 405 "Supported
  // methods: GET, HEAD") while real routes return 401. The old implementation
  // faked "OTP sent" with a timer, then logged in with a hardcoded password
  // ('testpassword123') and, on an unexpected response, fell back to a bogus
  // 'demo_driver_token_verified' session token — a login bypass that produced
  // a "signed in" app holding a token the backend would reject on every call.
  // A tab that can never succeed is worse than no tab, so it is gone until a
  // real OTP contract exists (see BACKEND_CONTRACTS.md).

  /// Turns a backend rejection into something a driver can act on.
  ///
  /// Verified envelopes: 401 `auth-001` for bad credentials, 403 with
  /// per-field codes for validation, 429 + `retry-after` for the 5-attempt
  /// throttle. Any other code surfaces the server's own message verbatim —
  /// account states such as pending approval, rejection and suspension are
  /// reported by the backend through this same `errors` array, and inventing
  /// local text for them would risk telling a driver something untrue.
  String _describe(ApiException e) {
    if (e.isRateLimited) {
      final wait = e.retryAfterSeconds;
      return wait != null
          ? 'Too many sign-in attempts. Please wait $wait seconds and try again.'
          : 'Too many sign-in attempts. Please wait a minute and try again.';
    }
    if (e.code == 'auth-001') {
      return 'Incorrect phone/email or password. Please try again.';
    }
    if (e.message.isNotEmpty) return e.message;
    return 'Sign in failed (HTTP ${e.statusCode}). Please try again.';
  }

  Future<void> _loginWithPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final service = Get.find<DriverApiService>();
    final identifier = _identifierController.text.trim();

    try {
      final result = await service.login(identifier, _passwordController.text);

      final token = result['token']?.toString() ?? '';
      if (token.isEmpty) {
        setState(() {
          _isLoading = false;
          _error =
              'Sign in did not return a session token. Please contact support.';
        });
        return;
      }

      authController.setToken(token);

      // Validate the brand-new token immediately. If the profile call is
      // rejected the credentials were fine but the account cannot be used, and
      // the driver must not be dropped onto an empty dashboard.
      try {
        final profile = await service.getProfile();
        authController.applyProfile(profile);
      } on ApiException catch (e) {
        if (e.isUnauthorized) {
          authController.clearToken();
          setState(() {
            _isLoading = false;
            _error = e.message.isNotEmpty
                ? e.message
                : 'Your driver account is not active yet. Please contact support.';
          });
          return;
        }
        // Reachable but erroring: keep the session, dashboard will retry.
      } catch (_) {
        // Offline right after login: keep the session and continue.
      }

      if (authController.phone.value.isEmpty) {
        authController.phone.value = identifier;
      }

      try {
        // Android 13+ requires this to be requested at runtime - without it
        // the OS silently withholds POST_NOTIFICATIONS forever (no prompt,
        // no notifications), regardless of the token registered below.
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null && fcmToken.isNotEmpty) {
          await service.updateFcmToken(fcmToken);
        }
      } catch (_) {}

      if (_rememberMe) {
        await authController.persistSession();
      }
      authController.isLoggedIn.value = true;
      Get.offAll(() => const DashboardScreen());
    } on ApiException catch (e) {
      setState(() {
        _isLoading = false;
        _error = _describe(e);
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _error = 'Unable to reach Urban Goodz. Check your connection.';
      });
    }
  }

  /// Password reset has no backend route on this platform (the same 405 probe
  /// that ruled out the OTP endpoints). The previous dialog collected a phone
  /// number, called nothing, and showed "Reset Code Sent" — a driver locked out
  /// of their account would wait indefinitely for a message that was never
  /// sent. Until a reset contract exists, tell them how to actually get back in.
  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock_reset, color: AppTheme.primary),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Reset Driver Password',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          'Self-service password reset is not available yet.\n\n'
          'Contact Urban Goodz driver support and an operator will reset your '
          'password on the dispatch console.',
          style: TextStyle(fontSize: 13, color: AppTheme.dark, height: 1.4),
        ),
        actions: [
          TextButton(
            key: const Key('driver_forgot_password_close'),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Colors.grey)),
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
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 20.0,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  children: [
                    // Brand Header — the real Urban Goodz wordmark and app
                    // mark. This previously drew the letters 'UG' in an
                    // orange box, which is not the brand.
                    Semantics(
                      label: 'driver_brand_header',
                      container: true,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          UgBrand.appMarkImage(size: 72),
                          const SizedBox(height: 14),
                          UgBrand.wordmarkImage(width: 190),
                          const SizedBox(height: 10),
                          UgBrand.roleLabel('Driver Partner Logistics'),
                        ],
                      ),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTheme.primary.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  size: 14,
                                  color: AppTheme.primary,
                                ),
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
                                      border: Border.all(
                                        color: Colors.red.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.error_outline,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            _error!,
                                            style: const TextStyle(
                                              color: Colors.red,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              // Phone or email + password — the only sign-in
                              // path the backend actually implements.
                              const Text(
                                'Phone Number or Email',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.dark,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Semantics(
                                label: 'driver_login_identifier',
                                child: TextFormField(
                                  key: const Key('driver_login_identifier'),
                                  controller: _identifierController,
                                  keyboardType: TextInputType.text,
                                  autofillHints: const [AutofillHints.username],
                                  decoration: const InputDecoration(
                                    hintText:
                                        '+1 555 019 2834  or  driver@urbangoodz.com',
                                    prefixIcon: Icon(
                                      Icons.person_outline,
                                      size: 20,
                                      color: AppTheme.primary,
                                    ),
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                  ),
                                  validator: (val) =>
                                      val == null || val.trim().isEmpty
                                      ? 'Phone number or email required'
                                      : null,
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
                                    prefixIcon: const Icon(
                                      Icons.lock_outline,
                                      size: 20,
                                      color: AppTheme.primary,
                                    ),
                                    border: const OutlineInputBorder(),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        size: 20,
                                      ),
                                      onPressed: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                    ),
                                  ),
                                  validator: (val) =>
                                      val == null || val.length < 6
                                      ? 'Minimum 6 characters required'
                                      : null,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Flexible so the row degrades gracefully on
                                  // narrow phones and at large text scales
                                  // instead of overflowing.
                                  Flexible(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: Checkbox(
                                            value: _rememberMe,
                                            activeColor: AppTheme.primary,
                                            onChanged: (val) => setState(
                                              () => _rememberMe = val ?? true,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Flexible(
                                          child: Text(
                                            'Remember me',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: AppTheme.dark,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  TextButton(
                                    key: const Key('driver_forgot_password'),
                                    onPressed: _showForgotPasswordDialog,
                                    child: const Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 14),

                              ElevatedButton(
                                key: const Key('driver_login_submit'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: AppTheme.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: _isLoading
                                    ? null
                                    : _loginWithPassword,
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Sign In',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                              ),

                              const SizedBox(height: 16),

                              Row(
                                children: [
                                  const Expanded(child: Divider()),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Text(
                                      'OR',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const Expanded(child: Divider()),
                                ],
                              ),

                              const SizedBox(height: 16),

                              OutlinedButton.icon(
                                key: const Key('driver_create_account'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.dark,
                                  side: const BorderSide(
                                    color: AppTheme.primary,
                                    width: 1.5,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () => Get.to(
                                  () => const DriverRegistrationScreen(),
                                ),
                                icon: const Icon(
                                  Icons.person_add_outlined,
                                  size: 20,
                                  color: AppTheme.dark,
                                ),
                                label: const Text(
                                  'Apply as New Driver',
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

                    const SizedBox(height: 20),

                    const Text(
                      '© 2026 Urban Goodz Platform. All rights reserved.\nEqual Opportunity Driver Partner Network',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
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
      ),
    );
  }
}
