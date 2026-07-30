import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:urban_goodz_vendor/controllers/vendor_auth_controller.dart';
import 'package:urban_goodz_vendor/theme/app_theme.dart';
import 'package:urban_goodz_vendor/theme/ug_brand.dart';
import 'package:urban_goodz_vendor/screens/vendor_registration_screen.dart';
import 'package:urban_goodz_vendor/screens/dashboard_screen.dart';
import 'package:urban_goodz_vendor/screens/vendor_password_reset_screen.dart';

class VendorOnboardingScreen extends StatefulWidget {
  const VendorOnboardingScreen({super.key});

  @override
  State<VendorOnboardingScreen> createState() => _VendorOnboardingScreenState();
}

/// Phone-OTP sign-in is off until a real backend contract exists.
///
/// The previous implementation authenticated locally without any API call.
/// Flipping this to `true` re-exposes the tab, so it must not be flipped
/// until `_handlePhoneOtpRequest`/`_handleOtpVerification` call a verified
/// endpoint.
const bool phoneOtpLoginEnabled = false;

class _VendorOnboardingScreenState extends State<VendorOnboardingScreen> {
  final VendorAuthController auth = Get.find<VendorAuthController>();
  final formKey = GlobalKey<FormState>();
  late final TextEditingController emailController;
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final otpController = TextEditingController();

  bool isPhoneMode = false;
  bool otpSent = false;
  bool obscurePassword = true;
  bool rememberMe = true;
  bool isLoading = false;
  String? errorMessage;

  final List<String> vendorCategories = const [
    'Restaurant & Dining',
    'Grocery & Fresh Produce',
    'Boutique & Fashion Fit',
    'Pharmacy & Health',
    'Local Artisans & Crafts',
    'Wholesale & Supply',
    'Professional Services',
  ];

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController(text: auth.email.value);
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    otpController.dispose();
    super.dispose();
  }

  /// Signs in against auth/vendor/login via VendorAuthController.
  ///
  /// This previously awaited a 700ms delay and then set `isLoggedIn = true`
  /// and a hardcoded business name WITHOUT calling the API at all, so any
  /// email/password pair opened the dashboard. It now performs the real
  /// request and only navigates when the backend authenticates the vendor.
  Future<void> _loginWithPassword() async {
    if (!formKey.currentState!.validate()) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final succeeded = await auth.login(
      emailController.text.trim(),
      passwordController.text,
    );

    if (!mounted) return;
    setState(() {
      isLoading = false;
      errorMessage = succeeded ? null : auth.errorMessage.value;
    });

    if (succeeded) {
      Get.offAll(() => DashboardScreen());
    }
  }

  // Phone-OTP handlers are intentionally inert.
  //
  // They previously performed local-only authentication: a fixed delay, then
  // isLoggedIn = true with a hardcoded vendor@urbangoodz.com identity and no
  // API call whatsoever. The bodies are removed rather than left dormant so
  // the bypass cannot return by simply flipping `phoneOtpLoginEnabled`.
  //
  // Required before this can be implemented: a verified vendor phone-OTP
  // request/verify contract in routes/api/v1/api.php. None exists today.

  Future<void> _handlePhoneOtpRequest() async {
    setState(
      () => errorMessage =
          'Phone sign-in is not available yet. Use your email and password.',
    );
  }

  Future<void> _handleOtpVerification() async {
    setState(
      () => errorMessage =
          'Phone sign-in is not available yet. Use your email and password.',
    );
  }

  /// Opens the real password-recovery flow.
  ///
  /// This previously showed a dialog that made no API call and unconditionally
  /// reported "Reset Link Sent", telling vendors an email was on its way when
  /// nothing had been requested. It also promised a reset *link*; the backend
  /// issues a 6-digit code. Replaced with the live flow against
  /// auth/vendor/{forgot-password,verify-token,reset-password}.
  void _openPasswordRecovery() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            VendorPasswordResetScreen(initialEmail: emailController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'vendor_login_screen',
      key: const Key('vendor_login_screen'),
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
                    // Brand Header
                    Semantics(
                      identifier: 'vendor_login_branding',
                      label: 'vendor_login_branding',
                      container: true,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          UgBrand.appMarkImage(size: 72),
                          const SizedBox(height: 14),
                          UgBrand.wordmarkImage(width: 190),
                          const SizedBox(height: 10),
                          UgBrand.roleLabel('Vendor Portal'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Vendor Categories Pills
                    SizedBox(
                      height: 34,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: vendorCategories.length,
                        separatorBuilder: (ctx, idx) => const SizedBox(width: 8),
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
                                const Icon(Icons.store_mall_directory, size: 14, color: AppTheme.primary),
                                const SizedBox(width: 6),
                                Text(
                                  vendorCategories[idx],
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

                    // Card Form Container
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
                          key: formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Auth Mode Selector
                              Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.beige.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.all(4),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => setState(() {
                                          isPhoneMode = false;
                                          errorMessage = null;
                                        }),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          decoration: BoxDecoration(
                                            color: !isPhoneMode ? Colors.white : Colors.transparent,
                                            borderRadius: BorderRadius.circular(10),
                                            boxShadow: !isPhoneMode
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
                                    // Phone-OTP sign-in is DISABLED.
                                    //
                                    // The handlers behind it never called any
                                    // API: they awaited a fixed delay and then
                                    // set isLoggedIn = true with a hardcoded
                                    // vendor@urbangoodz.com identity, so any
                                    // 4+ character code signed a user in.
                                    //
                                    // There is no vendor phone-OTP contract in
                                    // routes/api/v1/api.php (auth/vendor
                                    // exposes email/password only), so the tab
                                    // is disabled rather than wired to an
                                    // invented endpoint. Re-enable only once a
                                    // real contract exists.
                                    if (phoneOtpLoginEnabled)
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => setState(() {
                                          isPhoneMode = true;
                                          errorMessage = null;
                                        }),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          decoration: BoxDecoration(
                                            color: isPhoneMode ? Colors.white : Colors.transparent,
                                            borderRadius: BorderRadius.circular(10),
                                            boxShadow: isPhoneMode
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
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              if (errorMessage != null)
                                Semantics(
                                  label: 'vendor_auth_error',
                                  key: const Key('vendor_auth_error'),
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
                                            errorMessage!,
                                            style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              if (!isPhoneMode) ...[
                                const Text(
                                  'Merchant Email Address',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.dark),
                                ),
                                const SizedBox(height: 6),
                                Semantics(
                                  label: 'vendor_login_email',
                                  child: TextFormField(
                                    key: const Key('vendor_login_email'),
                                    controller: emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: const InputDecoration(
                                      hintText: 'store@urbangoodz.com',
                                      prefixIcon: Icon(Icons.email_outlined, size: 20, color: AppTheme.primary),
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    ),
                                    validator: (val) => val == null || !val.contains('@') ? 'Enter a valid email' : null,
                                  ),
                                ),

                                const SizedBox(height: 14),

                                const Text(
                                  'Password',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.dark),
                                ),
                                const SizedBox(height: 6),
                                Semantics(
                                  label: 'vendor_login_password',
                                  child: TextFormField(
                                    key: const Key('vendor_login_password'),
                                    controller: passwordController,
                                    obscureText: obscurePassword,
                                    decoration: InputDecoration(
                                      hintText: 'Enter password',
                                      prefixIcon: const Icon(Icons.lock_outline, size: 20, color: AppTheme.primary),
                                      border: const OutlineInputBorder(),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                          size: 20,
                                        ),
                                        onPressed: () => setState(() => obscurePassword = !obscurePassword),
                                      ),
                                    ),
                                    validator: (val) => val == null || val.length < 6 ? 'Password must be 6+ chars' : null,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                 Wrap(
                                   alignment: WrapAlignment.spaceBetween,
                                   crossAxisAlignment: WrapCrossAlignment.center,
                                   children: [
                                     Semantics(
                                       identifier: 'vendor_remember_me',
                                       container: true,
                                       child: Row(
                                         mainAxisSize: MainAxisSize.min,
                                         children: [
                                           SizedBox(
                                             width: 24,
                                             height: 24,
                                             child: Checkbox(
                                               value: rememberMe,
                                               activeColor: AppTheme.primary,
                                               onChanged: (val) => setState(() => rememberMe = val ?? true),
                                             ),
                                           ),
                                           const SizedBox(width: 4),
                                           const Text('Remember me', style: TextStyle(fontSize: 12, color: AppTheme.dark)),
                                         ],
                                       ),
                                     ),
                                      Semantics(
                                        label: 'vendor_forgot_password',
                                        child: TextButton(
                                          key: const Key('vendor_forgot_password'),
                                          onPressed: _openPasswordRecovery,
                                          child: const Text('Forgot Password?', style: TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                   ],
                                 ),

                                 const SizedBox(height: 14),

                                 Semantics(
                                   identifier: 'vendor_login_submit',
                                   label: 'vendor_login_submit',
                                   container: true,
                                   button: true,
                                   child: ElevatedButton(
                                     key: const Key('vendor_login_submit'),
                                     style: ElevatedButton.styleFrom(
                                       backgroundColor: AppTheme.primary,
                                       foregroundColor: AppTheme.white,
                                       padding: const EdgeInsets.symmetric(vertical: 14),
                                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                     ),
                                     onPressed: isLoading ? null : _loginWithPassword,
                                     child: isLoading
                                         ? const SizedBox(
                                             height: 20,
                                             width: 20,
                                             child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                           )
                                         : const Row(
                                             mainAxisAlignment: MainAxisAlignment.center,
                                             children: [
                                               Text('Sign In', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                               SizedBox(width: 8),
                                               Icon(Icons.arrow_forward_rounded, size: 20),
                                             ],
                                           ),
                                   ),
                                 ),
                               ] else ...[
                                 const Text(
                                   'Merchant Mobile Phone',
                                   style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.dark),
                                 ),
                                 const SizedBox(height: 6),
                                 TextFormField(
                                   controller: phoneController,
                                   keyboardType: TextInputType.phone,
                                   decoration: const InputDecoration(
                                     hintText: '+1 (555) 019-2834',
                                     prefixIcon: Icon(Icons.phone_android_outlined, size: 20, color: AppTheme.primary),
                                     border: OutlineInputBorder(),
                                     contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                   ),
                                 ),

                                 const SizedBox(height: 14),

                                 if (!otpSent)
                                   ElevatedButton(
                                     key: const Key('vendor_otp_request'),
                                     style: ElevatedButton.styleFrom(
                                       backgroundColor: AppTheme.primary,
                                       foregroundColor: AppTheme.white,
                                       padding: const EdgeInsets.symmetric(vertical: 14),
                                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                     ),
                                     onPressed: isLoading ? null : _handlePhoneOtpRequest,
                                     child: isLoading
                                         ? const SizedBox(
                                             height: 20,
                                             width: 20,
                                             child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                           )
                                         : const Text('Send Verification OTP', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                   )
                                 else ...[
                                   const Text(
                                     'Enter Verification Code',
                                     style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.dark),
                                   ),
                                   const SizedBox(height: 6),
                                   Semantics(
                                     label: 'vendor_otp_code',
                                     child: TextFormField(
                                       key: const Key('vendor_otp_code'),
                                       controller: otpController,
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

                                   const SizedBox(height: 14),

                                   ElevatedButton(
                                     key: const Key('vendor_otp_verify'),
                                     style: ElevatedButton.styleFrom(
                                       backgroundColor: AppTheme.primary,
                                       foregroundColor: AppTheme.white,
                                       padding: const EdgeInsets.symmetric(vertical: 14),
                                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                     ),
                                     onPressed: isLoading ? null : _handleOtpVerification,
                                     child: const Text('Verify & Enter Store', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                   ),
                                 ],
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
                                 key: const Key('vendor_create_account'),
                                 style: OutlinedButton.styleFrom(
                                   foregroundColor: AppTheme.dark,
                                   side: const BorderSide(color: AppTheme.primary, width: 1.5),
                                   padding: const EdgeInsets.symmetric(vertical: 14),
                                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                 ),
                                 onPressed: () => Get.to(() => const VendorRegistrationScreen()),
                                 icon: const Icon(Icons.store_outlined, size: 20, color: AppTheme.dark),
                                 label: const Text(
                                   'Create Account',
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
                      '© 2026 Urban Goodz Merchant Platform. All rights reserved.\nUnified Business & Retail Ecosystem',
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
