import 'dart:async';

import 'package:get/get.dart';
import 'package:urban_goodz_vendor/repositories/vendor_repository.dart';
import 'package:urban_goodz_vendor/services/vendor_api_client.dart';

/// Stages of the vendor password-recovery flow.
enum PasswordResetStage { identifier, token, newPassword, success }

/// Drives vendor password recovery against the proven backend contract in
/// VendorPasswordResetController.
///
/// Deliberate behaviours:
///  * The identifier step reports the SAME generic outcome whether the
///    backend answers 200 or 404, so this client does not amplify the
///    account-existence disclosure the backend already makes.
///  * No OTP is ever hardcoded. The backend has a `123456` demo bypass, but
///    it is gated on local+debug+demo mode server-side and is not replicated
///    here.
///  * Errors are surfaced, never swallowed. Nothing secret is logged.
class VendorPasswordResetController extends GetxController {
  VendorPasswordResetController(this.repository);

  final VendorRepository repository;

  /// Backend: `$max_otp_hit_time = 60` seconds between resend windows.
  static const resendCooldownSeconds = 60;

  final stage = PasswordResetStage.identifier.obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();
  final infoMessage = RxnString();
  final email = ''.obs;
  final resendSeconds = 0.obs;

  String _resetToken = '';
  Timer? _resendTimer;

  @override
  void onClose() {
    _resendTimer?.cancel();
    super.onClose();
  }

  /// Mirrors the backend rule set exactly:
  /// `Password::min(8)->mixedCase()->letters()->numbers()->symbols()`.
  ///
  /// `uncompromised()` (HaveIBeenPwned) cannot be evaluated on device, so a
  /// breached password passes here and is rejected by the server; that
  /// response is rendered verbatim rather than being masked.
  static String? validatePassword(String value) {
    if (value.isEmpty) return 'Enter a new password.';
    if (value.length < 8) return 'Use at least 8 characters.';
    if (!RegExp(r'[a-z]').hasMatch(value) || !RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Include both uppercase and lowercase letters.';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Include at least one number.';
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(value)) {
      return 'Include at least one symbol.';
    }
    return null;
  }

  static String? validateEmail(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Enter the email address on your account.';
    // Backend validates `required` only, but a malformed address can never
    // match a vendor row, so fail fast instead of spending an attempt.
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    resendSeconds.value = resendCooldownSeconds;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendSeconds.value <= 1) {
        resendSeconds.value = 0;
        timer.cancel();
      } else {
        resendSeconds.value -= 1;
      }
    });
  }

  /// Step 1 — request a reset code.
  ///
  /// Returns true when the flow may advance. A 404 (unknown email) advances
  /// exactly like a 200 so the two are indistinguishable to the user.
  Future<bool> requestReset(String emailInput) async {
    final validationError = validateEmail(emailInput);
    if (validationError != null) {
      errorMessage.value = validationError;
      return false;
    }

    isLoading.value = true;
    errorMessage.value = null;
    infoMessage.value = null;
    try {
      email.value = emailInput.trim();
      await repository.requestPasswordReset(email.value);
      return _advanceToTokenStage();
    } on VendorApiException catch (e) {
      // 404 = "Email not found!". Treated as success on purpose.
      if (e.statusCode == 404) {
        return _advanceToTokenStage();
      }
      errorMessage.value = e.message;
      return false;
    } catch (_) {
      errorMessage.value =
          'Could not reach Urban Goodz. Check your connection and try again.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  bool _advanceToTokenStage() {
    stage.value = PasswordResetStage.token;
    infoMessage.value =
        'If an account exists for that address, a 6-digit code has been sent to it.';
    _startResendCooldown();
    return true;
  }

  /// Re-issues a code by calling the same endpoint again; the backend
  /// replaces the stored token. There is no dedicated resend endpoint.
  Future<bool> resendCode() async {
    if (resendSeconds.value > 0 || email.value.isEmpty) return false;
    isLoading.value = true;
    errorMessage.value = null;
    try {
      await repository.requestPasswordReset(email.value);
      infoMessage.value = 'A new code has been sent.';
      _startResendCooldown();
      return true;
    } on VendorApiException catch (e) {
      if (e.statusCode == 404) {
        infoMessage.value = 'A new code has been sent.';
        _startResendCooldown();
        return true;
      }
      errorMessage.value = e.message;
      return false;
    } catch (_) {
      errorMessage.value =
          'Could not reach Urban Goodz. Check your connection and try again.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Step 2 — verify the emailed code.
  Future<bool> verifyToken(String token) async {
    final trimmed = token.trim();
    if (trimmed.isEmpty) {
      errorMessage.value = 'Enter the code from your email.';
      return false;
    }

    isLoading.value = true;
    errorMessage.value = null;
    infoMessage.value = null;
    try {
      await repository.verifyPasswordResetToken(
        email: email.value,
        resetToken: trimmed,
      );
      _resetToken = trimmed;
      stage.value = PasswordResetStage.newPassword;
      return true;
    } on VendorApiException catch (e) {
      // 405 carries otp_block_time / otp_temp_blocked; the server message
      // already states how long to wait, so it is shown as-is.
      errorMessage.value = e.statusCode == 403
          ? 'That code could not be verified. Request a new one.'
          : e.message;
      return false;
    } catch (_) {
      errorMessage.value =
          'Could not reach Urban Goodz. Check your connection and try again.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Step 3 — set the replacement password.
  Future<bool> submitNewPassword(String password, String confirmPassword) async {
    final passwordError = validatePassword(password);
    if (passwordError != null) {
      errorMessage.value = passwordError;
      return false;
    }
    if (password != confirmPassword) {
      errorMessage.value = 'Passwords do not match.';
      return false;
    }

    isLoading.value = true;
    errorMessage.value = null;
    try {
      await repository.submitPasswordReset(
        email: email.value,
        resetToken: _resetToken,
        password: password,
        confirmPassword: confirmPassword,
      );
      _resetToken = '';
      stage.value = PasswordResetStage.success;
      return true;
    } on VendorApiException catch (e) {
      // 400 = code invalid or already consumed -> send the user back a step.
      if (e.statusCode == 400) {
        _resetToken = '';
        stage.value = PasswordResetStage.token;
        errorMessage.value =
            'That code is no longer valid. Request a new one and try again.';
        return false;
      }
      errorMessage.value = e.message;
      return false;
    } catch (_) {
      errorMessage.value =
          'Could not reach Urban Goodz. Check your connection and try again.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Clears every field holding recovery state. Called on exit and after a
  /// completed reset so no code or address survives the flow.
  void reset() {
    _resendTimer?.cancel();
    _resetToken = '';
    email.value = '';
    resendSeconds.value = 0;
    stage.value = PasswordResetStage.identifier;
    isLoading.value = false;
    errorMessage.value = null;
    infoMessage.value = null;
  }

  /// Back navigation. Returns true when the caller should pop the screen.
  bool goBack() {
    errorMessage.value = null;
    infoMessage.value = null;
    switch (stage.value) {
      case PasswordResetStage.identifier:
      case PasswordResetStage.success:
        reset();
        return true;
      case PasswordResetStage.token:
        stage.value = PasswordResetStage.identifier;
        return false;
      case PasswordResetStage.newPassword:
        // Drop the verified code when stepping back so it cannot be reused
        // against a different address.
        _resetToken = '';
        stage.value = PasswordResetStage.token;
        return false;
    }
  }
}
