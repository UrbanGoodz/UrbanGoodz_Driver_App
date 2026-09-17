import 'package:get/get.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final Function? onPressed;
  final String buttonText;
  final bool transparent;
  final EdgeInsets? margin;
  final double? height;
  final double? width;
  final double? fontSize;
  final double radius;
  final IconData? icon;
  final Color? color;
  final Color? textColor;
  final bool isLoading;
  final bool isBold;
  final bool isBorder;
  final Color? iconColor;
  final TextStyle? textStyle;
  const CustomButton({super.key, this.onPressed, required this.buttonText, this.transparent = false, this.margin, this.width, this.height,
    this.fontSize, this.radius = 10, this.icon, this.color, this.textColor, this.isLoading = false, this.isBold = true, this.isBorder = false, this.iconColor, this.textStyle});

  @override
  Widget build(BuildContext context) {
    final bool isPrimary = onPressed != null && !transparent;
    // seasoningOrange (the default, un-overridden fill) is bright enough
    // that white fails contrast on it -- dark text instead, same call
    // ElevatedButtonThemeData now makes for raw ElevatedButtons. A caller
    // that passes its own `color` may have picked something dark on
    // purpose, so white stays the fallback there.
    final Color onFillColor = (color == null) ? AppConstants.ugBlack : AppConstants.ugWhite;
    final ButtonStyle flatButtonStyle = TextButton.styleFrom(
      // Was a hardcoded Color(0xff93A2AE) -- an off-palette blue-grey with
      // no relationship to the brand or the theme's own disabled token.
      backgroundColor: onPressed == null ? Theme.of(context).disabledColor.withValues(alpha: 0.5) : transparent
          ? Colors.transparent : color ?? Theme.of(context).primaryColor,
      minimumSize: Size(width != null ? width! : Dimensions.webMaxWidth, height != null ? height! : 50),
      padding: EdgeInsets.zero,
      elevation: isPrimary ? 2 : 0,
      shadowColor: Theme.of(context).primaryColor.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: isBorder ? BorderSide(color: Theme.of(context).disabledColor.withValues(alpha: 0.5)) : BorderSide.none,
      ),
    );

    return Center(child: SizedBox(width: width ?? Dimensions.webMaxWidth, child: Padding(
      padding: margin == null ? const EdgeInsets.all(0) : margin!,
      child: TextButton(
        onPressed: isLoading ? null : onPressed as void Function()?,
        style: flatButtonStyle,
        child: isLoading ?
        Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(
            height: 15, width: 15,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(onFillColor),
              strokeWidth: 2,
            ),
        ),
          const SizedBox(width: Dimensions.paddingSizeSmall),

          Text('loading'.tr, style: robotoMedium.copyWith(color: onFillColor)),
        ]),
        ) : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          icon != null ? Padding(
            padding: const EdgeInsets.only(right: Dimensions.paddingSizeExtraSmall),
            // Was Theme.of(context).cardColor -- in dark theme that's
            // ugBlack, an all-but-invisible icon on the same amber fill the
            // text sits on right next to it.
            child: Icon(icon, color: transparent ? Theme.of(context).primaryColor : onFillColor),
          ) : const SizedBox(),
          Text(buttonText, textAlign: TextAlign.center, style: (textStyle != null) ? textStyle : isBold ? robotoBold.copyWith(
            color: textColor ?? (transparent ? Theme.of(context).primaryColor : onFillColor),
            fontSize: fontSize ?? Dimensions.fontSizeLarge,
          ) : robotoRegular.copyWith(
            color: textColor ?? (transparent ? Theme.of(context).primaryColor : onFillColor),
            fontSize: fontSize ?? Dimensions.fontSizeLarge,
          )),
        ]),
      ),
    )));
  }
}
