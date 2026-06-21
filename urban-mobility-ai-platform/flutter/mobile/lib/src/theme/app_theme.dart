import 'package:flutter/material.dart';

abstract class AppTheme {
  static ThemeData light() {
    const seed = Color(0xFF00D1FF);
    final colorScheme = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light);
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: colorScheme.surface,
    );
  }

  static ThemeData dark() {
    const seed = Color(0xFFFFC247);
    final colorScheme = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark);
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF0B0F14),
    );
  }
}

