import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFFED9914);
  static const Color dark = Color(0xFF161616);
  static const Color beige = Color(0xFFE2D3BF);
  static const Color accent = Color(0xFFE5E276);
  static const Color white = Color(0xFFFFFFFF);

  static ThemeData get lightTheme => ThemeData(
        primaryColor: primary,
        scaffoldBackgroundColor: beige,
        colorScheme: ColorScheme.light(
          primary: primary,
          secondary: accent,
          surface: white,
          onSurface: dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: dark,
          foregroundColor: white,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          color: white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: dark, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: dark.withAlpha(50)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: dark,
          ),
          headlineMedium: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: dark,
          ),
          headlineSmall: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: dark,
          ),
          titleLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: dark,
          ),
          titleMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: dark,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: dark,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: dark,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            color: dark,
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: white,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: dark,
          selectedItemColor: primary,
          unselectedItemColor: white,
          type: BottomNavigationBarType.fixed,
        ),
        dividerTheme: DividerThemeData(
          color: dark.withAlpha(25),
          thickness: 1,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: beige,
          selectedColor: primary,
          labelStyle: const TextStyle(color: dark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      );
}
