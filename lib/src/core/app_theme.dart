import 'package:flutter/material.dart';

class AppColors {
  static const ink = Color(0xFF0F172A);      // Deep slate black
  static const muted = Color(0xFF64748B);    // Slate gray
  static const line = Color(0xFFE2E8F0);     // Light gray borders
  static const ivory = Color(0xFFF8FAFC);    // Clean off-white background
  static const pearl = Color(0xFFF1F5F9);    // Pearl gray
  static const gold = Color(0xFF000000);     // Luxury solid black for main items
  static const goldSoft = Color(0xFFE2E8F0); // Sleek gray for selections/indicators
  static const platinum = Color(0xFFF1F5F9);
  static const success = Color(0xFF0F172A);  // Deep slate black
  static const danger = Color(0xFF475569);   // Dark slate gray
  static const warning = Color(0xFF94A3B8);  // Light slate gray

  static const primary = gold;
  static const background = ivory;
}

ThemeData buildAppTheme() {
  const seed = AppColors.gold;
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.light,
    surface: AppColors.ivory,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.ivory,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.ink,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: Colors.white.withValues(alpha: .92),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.line),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.gold, width: 1.4),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white.withValues(alpha: .96),
      indicatorColor: AppColors.goldSoft,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: AppColors.line),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      // Đẩy snackbar lên cao hơn để không bị che bởi NavigationBar (~80px)
      insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      contentTextStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
  );
}

List<BoxShadow> softShadow([double opacity = .12]) {
  return [
    BoxShadow(
      color: AppColors.ink.withValues(alpha: opacity),
      blurRadius: 28,
      offset: const Offset(0, 18),
    ),
  ];
}
