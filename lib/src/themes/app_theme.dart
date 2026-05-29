part of '../app.dart';

ThemeData _cineverseTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _obsidian,
    colorScheme: const ColorScheme.dark(
      primary: _gold,
      secondary: _emerald,
      surface: _surface,
    ),
    textTheme: ThemeData.dark().textTheme.apply(
      bodyColor: _stone,
      displayColor: _stone,
      fontFamily: 'Inter',
    ),
  );
}
