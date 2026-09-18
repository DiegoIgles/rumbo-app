import 'package:flutter/material.dart';

/// Mismo color primario que usa el panel web (src/index.css --color-primary).
const Color rumboPrimary = Color(0xFF0891B2);

ThemeData buildRumboTheme() {
  final colorScheme = ColorScheme.fromSeed(seedColor: rumboPrimary, brightness: Brightness.light);
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFFF8FAFC),
      foregroundColor: const Color(0xFF0F2B33),
      elevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: rumboPrimary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFDBE6EA)),
      ),
    ),
  );
}
