import 'package:flutter/material.dart';

class BrandTheme {
  static ThemeData dark() {
    const primary = Color(0xFF00C2FF);
    return ThemeData.dark().copyWith(
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: Color(0xFF7C4DFF),
        surface: Color(0xFF0F172A),
      ),
      scaffoldBackgroundColor: const Color(0xFF020617),
    );
  }
}
