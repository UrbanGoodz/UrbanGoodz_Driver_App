import 'package:sixam_mart/util/dimensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void showCustomBottomSheet({required Widget child, double? height}) {
  Get.bottomSheet(
    ConstrainedBox(
      constraints: BoxConstraints(maxHeight: height ?? MediaQuery.of(Get.context!).size.height * 0.8),
      child: child,
    ),
    isScrollControlled: true, useRootNavigator: true,
    // Was hardcoded Colors.white -- rendered a light-mode-only sheet with
    // white chrome over dark-mode content behind it.
    backgroundColor: Theme.of(Get.context!).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(topLeft: Radius.circular(Dimensions.radiusExtraLarge), topRight: Radius.circular(Dimensions.radiusExtraLarge)),
    ),
  );
}