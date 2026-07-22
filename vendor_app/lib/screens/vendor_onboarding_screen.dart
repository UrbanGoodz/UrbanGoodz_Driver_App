import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:urban_goodz_vendor/controllers/vendor_auth_controller.dart';
import 'package:urban_goodz_vendor/theme/app_theme.dart';
import 'package:urban_goodz_vendor/screens/vendor_registration_screen.dart';
import 'package:urban_goodz_vendor/screens/dashboard_screen.dart';

class VendorOnboardingScreen extends StatefulWidget {
  const VendorOnboardingScreen({super.key});

  @override
  State<VendorOnboardingScreen> createState() => _VendorOnboardingScreenState();
}

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

  Future<void> _loginWithPassword() async {
    if (!formKey.currentState!.validate()) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    await Future.delayed(const Duration(milliseconds: 700));
    final email = emailController.text.trim();
    auth.email.value = email;
    auth.businessName.value = 'Urban Goodz Merchant Store';
    auth.isLoggedIn.value = true;

    setState(() => isLoading = false);
    Get.offAll(() => DashboardScreen());
  }

  Future<void> _handlePhoneOtpRequest() async {
    final phone = phoneController.text.trim();
    if (phone.isEmpty || phone.length < 7) {
      setState(() => errorMessage = 'Please enter a valid phone number');
      return;
    }
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    await Future.delayed(const Duration(milliseconds: 800));
    setState(() {
      isLoading = false;
      otpSent = true;
    });
  }

  Future<void> _handleOtpVerification() async {
    final code = otpController.text.trim();
    if (code.length < 4) {
      setState(() => errorMessage = 'Please enter verification code');
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    await Future.delayed(const Duration(milliseconds: 700));
    auth.email.value = 'vendor@urbangoodz.com';
    auth.businessName.value = 'Urban Goodz Merchant Store';
    auth.isLoggedIn.value = true;

    setState(() => isLoading = false);
    Get.offAll(() => DashboardScreen());
  }

  void _showForgotPasswordDialog() {
    final resetController = TextEditingController(text: emailController.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.storefront_outlined, color: AppTheme.primary),
            SizedBox(width: 8),
            Text('Reset Store Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your registered merchant email. We will send a password reset link.',
              style: TextStyle(fontSize: 13, color: AppTheme.dark),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: resetController,
              decoration: const InputDecoration(
                hintText: 'store@urbangoodz.com',
                prefixIcon: Icon(Icons.email_outlined, size: 20),
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
            key: const Key('vendor_forgot_password'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            onPressed: () {
              Navigator.pop(ctx);
              Get.snackbar(
                'Reset Link Sent',
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
                      container: true,
                      child: Row(
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
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'URBAN GOODZ',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.dark,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              Text(
                                'Urban Goodz Vendor',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primary,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
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
                                          onPressed: _showForgotPasswordDialog,
                                          child: const Text('Forgot Password?', style: TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                   ],
                                 ),

                                 const SizedBox(height: 14),

                                 ElevatedButton(
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
