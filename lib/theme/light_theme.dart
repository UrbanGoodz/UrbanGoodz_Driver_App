import 'package:flutter/material.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';

ThemeData light({Color color = const Color(0xFFED9914)}) => ThemeData(
  fontFamily: AppConstants.fontFamily,
  primaryColor: color,
  secondaryHeaderColor: AppConstants.ugBlack,
  disabledColor: AppConstants.canvas,
  brightness: Brightness.light,
  hintColor: AppConstants.canvas.withValues(alpha: 0.6),
  scaffoldBackgroundColor: AppConstants.canvas,
  canvasColor: AppConstants.canvas,
  cardColor: AppConstants.ugWhite,
  shadowColor: AppConstants.ugBlack.withValues(alpha: 0.03),
  textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: AppConstants.seasoningOrange)),
  // Every raw ElevatedButton/OutlinedButton in the app (there are dozens
  // that don't go through CustomButton) inherits this automatically -- no
  // call site changes needed for the premium treatment to reach them.
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppConstants.seasoningOrange,
      // Dark text, not white: seasoningOrange (0xFFED9914) is bright enough
      // that white fails contrast on it in both themes -- the button fill
      // is the same amber regardless of overall theme brightness.
      foregroundColor: AppConstants.ugBlack,
      disabledBackgroundColor: AppConstants.canvas,
      disabledForegroundColor: AppConstants.ugBlack.withValues(alpha: 0.4),
      elevation: 2,
      shadowColor: AppConstants.seasoningOrange.withValues(alpha: 0.35),
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeSmall),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppConstants.seasoningOrange,
      side: BorderSide(color: AppConstants.seasoningOrange.withValues(alpha: 0.5), width: 1),
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeSmall),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
    ),
  ),
  popupMenuTheme: const PopupMenuThemeData(color: Colors.white, surfaceTintColor: Colors.white),
  dialogTheme: const DialogThemeData(surfaceTintColor: Colors.white),
  floatingActionButtonTheme: FloatingActionButtonThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(500))),
  bottomAppBarTheme: const BottomAppBarThemeData(
    surfaceTintColor: Colors.white, height: 60,
    padding: EdgeInsets.symmetric(vertical: 5),
  ),
  dividerTheme: DividerThemeData(thickness: 0.2, color: AppConstants.ugBlack.withValues(alpha: 0.15)),
  tabBarTheme: const TabBarThemeData(dividerColor: Colors.transparent), colorScheme: ColorScheme.light(primary: AppConstants.seasoningOrange, secondary: AppConstants.ugBlack).copyWith(
      surface: AppConstants.ugWhite).copyWith(error: AppConstants.seasoningOrange).copyWith(surface: AppConstants.canvas),
);

const Map<String, Color> buttonBackgroundColorMap ={
  'pending': Color(0x457bc2f6),
  'accepted': Color(0x499ad0fb),
  'ongoing': Color(0x629ac5f8),
  'completed': Color(0x5faff4c1),
  'settled': Color(0x6e93b347),
  'canceled': Color(0x51F6A9A9),
  'approved': Color(0x80356e4c),
  'expired' : Color(0x8C7C3B3B),
  'running' : Color(0x793c4fd8),
  'denied':  Color(0x666e3737),
  'paused': Color(0xff0461A5),
  'resumed' : Color(0x6f2f5e41),
  'resume' : Color(0x8e387c54),
  'subscription_purchase' : Color(0x3cecc98d),
  'subscription_renew' : Color(0x1d6bf5a2),
  'subscription_shift' : Color(0x452599ee),
  'subscription_refund' : Color(0x1dc97eee),
};

const Map<String, Color> buttonTextColorMap ={
  'pending': Color(0xff058df3),
  'accepted': Color(0xff2B95FF),
  'ongoing': Color(0xff2B95FF),
  'completed': Color(0xff03b158),
  'settled': Color(0xf57b9826),
  'canceled': Color(0xfff44747),
  'approved': Color(0xff16B559),
  'expired' : Color(0xff9ca8af),
  'running' : Color(0xff707ec6),
  'denied':  Color(0xffFF3737),
  'paused': Color(0xff0461A5),
  'resumed' : Color(0xff16B559),
  'resume' : Color(0xff16B559),
  'subscription_purchase' : Color(0xffe7680a),
  'subscription_renew' : Color(0xff16B559),
  'subscription_shift' : Color(0xff0461A5),
  'subscription_refund' : Color(0xffba4af8),
};