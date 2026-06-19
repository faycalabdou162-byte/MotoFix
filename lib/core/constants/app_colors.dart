import 'package:flutter/material.dart';

/// Brand palette — Primary #FF6B00, Dark #0F172A, Background #F8FAFC
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFFF6B00);
  static const Color primaryLight = Color(0xFFFF8534);
  static const Color primaryDark = Color(0xFFE55D00);

  static const Color dark = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkCard = Color(0xFF334155);

  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textOnDark = Color(0xFFF8FAFC);
  static const Color textMuted = Color(0xFF94A3B8);

  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  static const Color border = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF334155);

  static const Color white = Colors.white;
  static const Color black = Colors.black;

  /// Legacy aliases — kept so existing screens compile during migration.
  static const Color card = darkCard;
  static const Color grey = textSecondary;

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryLight, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF1E293B), dark],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
