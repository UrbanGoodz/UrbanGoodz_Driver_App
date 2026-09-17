import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/util/dimensions.dart';

class CustomCard extends StatelessWidget {
  final Widget? child;
  final double? width;
  final double? height;
  final double? borderRadius;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final bool isBorder;
  const CustomCard({super.key, this.child, this.width, this.height, this.borderRadius, this.margin, this.padding, this.isBorder = true});

  /// The one shadow/border recipe every "card" surface in the app should
  /// share. Exposed as a static so item_card/store_card/visit_again_card
  /// (which build their own Container instead of wrapping CustomCard) can
  /// draw from the same source instead of each carrying a slightly
  /// different hand-rolled version.
  static BoxDecoration decoration(BuildContext context, {double? radius, bool isBorder = true}) {
    return BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(radius ?? Dimensions.radiusDefault),
      border: isBorder ? Border.all(color: Get.isDarkMode ? const Color(0xff232323) : const Color(0xffEFEFEF), width: 1) : null,
      boxShadow: [
        // Dark mode needs a light glow, not a black shadow -- a black
        // shadow on the near-black background (ugBlack) would be invisible,
        // so elevation is cued with a soft white glow instead, as before.
        BoxShadow(
          color: Get.isDarkMode ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
          blurRadius: 18, spreadRadius: 0, offset: const Offset(0, 6),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity, height: height,
      margin: margin, padding: padding,
      decoration: CustomCard.decoration(context, radius: borderRadius, isBorder: isBorder),
      child: child,
    );
  }
}
