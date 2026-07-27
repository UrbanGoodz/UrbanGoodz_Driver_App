import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:urban_goodz_vendor/controllers/vendor_password_reset_controller.dart';
import 'package:urban_goodz_vendor/repositories/vendor_repository.dart';
import 'package:urban_goodz_vendor/theme/app_theme.dart';

/// Vendor password recovery: identifier -> code -> new password -> success.
///
/// Backed by VendorPasswordResetController, which talks to the proven
/// auth/vendor/{forgot-password,verify-token,reset-password} endpoints.
class VendorPasswordResetScreen extends StatefulWidget {
  const VendorPasswordResetScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  State<VendorPasswordResetScreen> createState() =>
      _VendorPasswordResetScreenState();
}

class _VendorPasswordResetScreenState extends State<VendorPasswordResetScreen> {
  late final VendorPasswordResetController controller;

  final emailController = TextEditingController();
  final tokenController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      VendorPasswordResetController(Get.find<VendorRepository>()),
    );
    controller.reset();
    emailController.text = widget.initialEmail ?? '';
  }

  @override
  void dispose() {
    // Clear recovery state so no address or code survives the screen.
    controller.reset();
    emailController.dispose();
    tokenController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleBack() async {
    final shouldPop = controller.goBack();
    if (shouldPop && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Semantics(
        label: 'vendor_password_reset_screen',
        key: const Key('vendor_password_reset_screen'),
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            foregroundColor: AppTheme.dark,
            title: const Text('Reset Store Password'),
            leading: IconButton(
              key: const Key('vendor_password_reset_back'),
              icon: const Icon(Icons.arrow_back),
              onPressed: _handleBack,
            ),
          ),
          body: SafeArea(
            child: Obx(() {
              final stage = controller.stage.value;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StageIndicator(stage: stage),
                    const SizedBox(height: 24),
                    if (controller.infoMessage.value != null)
                      _Banner(
                        key: const Key('vendor_password_reset_info'),
                        message: controller.infoMessage.value!,
                        color: AppTheme.primary,
                        icon: Icons.mark_email_read_outlined,
                      ),
                    if (controller.errorMessage.value != null)
                      _Banner(
                        key: const Key('vendor_password_reset_error'),
                        message: controller.errorMessage.value!,
                        color: Colors.red.shade700,
                        icon: Icons.error_outline,
                      ),
                    const SizedBox(height: 8),
                    switch (stage) {
                      PasswordResetStage.identifier => _identifierStage(),
                      PasswordResetStage.token => _tokenStage(),
                      PasswordResetStage.newPassword => _passwordStage(),
                      PasswordResetStage.success => _successStage(),
                    },
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _identifierStage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Enter the email address registered to your store. If it matches an '
          'account, we will send a 6-digit verification code.',
          style: TextStyle(fontSize: 13, color: AppTheme.dark),
        ),
        const SizedBox(height: 16),
        Semantics(
          label: 'vendor_reset_email',
          child: TextField(
            key: const Key('vendor_reset_email'),
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: const InputDecoration(
              hintText: 'store@urbangoodz.com',
              prefixIcon: Icon(Icons.email_outlined, size: 20),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _PrimaryButton(
          buttonKey: const Key('vendor_reset_request_submit'),
          label: 'Send Code',
          busy: controller.isLoading.value,
          onPressed: () => controller.requestReset(emailController.text),
        ),
      ],
    );
  }

  Widget _tokenStage() {
    final cooldown = controller.resendSeconds.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Enter the 6-digit code sent to ${controller.email.value}.',
          style: const TextStyle(fontSize: 13, color: AppTheme.dark),
        ),
        const SizedBox(height: 16),
        Semantics(
          label: 'vendor_reset_token',
          child: TextField(
            key: const Key('vendor_reset_token'),
            controller: tokenController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              hintText: '123456',
              counterText: '',
              prefixIcon: Icon(Icons.lock_clock_outlined, size: 20),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: const Key('vendor_reset_resend'),
            onPressed: cooldown > 0 || controller.isLoading.value
                ? null
                : () => controller.resendCode(),
            child: Text(
              cooldown > 0 ? 'Resend code in ${cooldown}s' : 'Resend code',
              style: TextStyle(
                color: cooldown > 0 ? Colors.grey : AppTheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _PrimaryButton(
          buttonKey: const Key('vendor_reset_token_submit'),
          label: 'Verify Code',
          busy: controller.isLoading.value,
          onPressed: () => controller.verifyToken(tokenController.text),
        ),
      ],
    );
  }

  Widget _passwordStage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Choose a new password. It must be at least 8 characters and include '
          'uppercase and lowercase letters, a number, and a symbol.',
          style: TextStyle(fontSize: 13, color: AppTheme.dark),
        ),
        const SizedBox(height: 16),
        Semantics(
          label: 'vendor_reset_new_password',
          child: TextField(
            key: const Key('vendor_reset_new_password'),
            controller: passwordController,
            obscureText: obscurePassword,
            decoration: InputDecoration(
              hintText: 'New password',
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => obscurePassword = !obscurePassword),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Semantics(
          label: 'vendor_reset_confirm_password',
          child: TextField(
            key: const Key('vendor_reset_confirm_password'),
            controller: confirmController,
            obscureText: obscureConfirm,
            decoration: InputDecoration(
              hintText: 'Confirm new password',
              prefixIcon: const Icon(Icons.lock_reset_outlined, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => obscureConfirm = !obscureConfirm),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _PrimaryButton(
          buttonKey: const Key('vendor_reset_password_submit'),
          label: 'Set New Password',
          busy: controller.isLoading.value,
          onPressed: () => controller.submitNewPassword(
            passwordController.text,
            confirmController.text,
          ),
        ),
      ],
    );
  }

  Widget _successStage() {
    return Column(
      key: const Key('vendor_reset_success'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.check_circle_outline, color: Colors.green, size: 56),
        const SizedBox(height: 16),
        const Text(
          'Password changed successfully.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.dark,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Sign in with your new password to continue.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppTheme.dark),
        ),
        const SizedBox(height: 24),
        _PrimaryButton(
          buttonKey: const Key('vendor_reset_return_to_login'),
          label: 'Return to Sign In',
          busy: false,
          onPressed: () async {
            controller.reset();
            if (mounted) Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

class _StageIndicator extends StatelessWidget {
  const _StageIndicator({required this.stage});

  final PasswordResetStage stage;

  @override
  Widget build(BuildContext context) {
    final index = PasswordResetStage.values.indexOf(stage);
    return Row(
      children: List.generate(PasswordResetStage.values.length, (i) {
        final active = i <= index;
        return Expanded(
          child: Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: active ? AppTheme.primary : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    super.key,
    required this.message,
    required this.color,
    required this.icon,
  });

  final String message;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12.5, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.buttonKey,
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final Key buttonKey;
  final String label;
  final bool busy;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        key: buttonKey,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: busy ? null : () => onPressed(),
        child: busy
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
