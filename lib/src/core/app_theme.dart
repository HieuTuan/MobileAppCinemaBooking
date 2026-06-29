import 'package:flutter/material.dart';

class AppColors {
  static const ink = Color(0xFF141822);
  static const muted = Color(0xFF71788A);
  static const line = Color(0xFFE7EAF1);
  static const ivory = Color(0xFFFBFBF8);
  static const pearl = Color(0xFFF3F5F9);
  static const gold = Color(0xFFC9A44C);
  static const goldSoft = Color(0xFFFFF2C5);
  static const platinum = Color(0xFFEAF0FF);
  static const success = Color(0xFF1B9E66);
  static const danger = Color(0xFFD04747);
  static const warning = Color(0xFFE09622);
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
