import 'package:flutter/material.dart';

class AppTextStyles {
  static const String fontFamily = 'Roboto';
  static const String headingFontFamily = 'RobotoCondensed';

  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    fontFamily: headingFontFamily,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    fontFamily: headingFontFamily,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    fontFamily: fontFamily,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    fontFamily: fontFamily,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    fontFamily: fontFamily,
  );
}
