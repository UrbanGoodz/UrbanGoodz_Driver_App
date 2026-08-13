import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Shows a snackbar, but only when there is a live navigator to show it in.
///
/// Every lifecycle outcome — success, unconfirmed, refused, failed — is
/// reported to the driver through here. `Get.snackbar` throws if no
/// navigator is mounted, which is the case in headless tests and can also
/// happen when a controller outlives the screen that created it. A refusal
/// turning into a crash would be strictly worse than the refusal, so the
/// notice is skipped in that case.
///
/// The outcome is always recorded on the controller's `lastOutcome`
/// regardless, so dropping the visual notice never drops the fact.
void showNotice(
  String title,
  String message, {
  Color? background,
  Color? text,
}) {
  if (Get.key.currentState == null) return;
  Get.snackbar(
    title,
    message,
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: background,
    colorText: text,
  );
}
