import 'package:flutter/material.dart';

/// Centralized color palette for the Mshoar app.
/// Strictly follows the brand identity from the design specs.
class AppColors {
  AppColors._();

  // ─── Brand ─────────────────────────────────────────────────
  static const Color primary = Color(0xFF0F4C33);
  static const Color primaryDark = Color(0xFF093323);
  static const Color primaryLight = Color(0xFF1A6B4A);
  static const Color primarySurface = Color(0xFFE8F5EE);

  // ─── Accent / Orange ───────────────────────────────────────
  static const Color accent = Color(0xFFFF6535);
  static const Color accentDark = Color(0xFFE5521E);
  static const Color accentSurface = Color(0xFFFFF1EC);

  // ─── Neutral Backgrounds ───────────────────────────────────
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color backgroundGray = Color(0xFFF8F9FA);
  static const Color backgroundMuted = Color(0xFFF1F3F2);

  // ─── Borders & Dividers ────────────────────────────────────
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF0F0F0);

  // ─── Text ──────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textLink = Color(0xFF0F4C33);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ─── Semantic ──────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color successSurface = Color(0xFFECFDF5);
  static const Color error = Color(0xFFEF4444);
  static const Color errorSurface = Color(0xFFFEF2F2);
  static const Color warning = Color(0xFFF59E0B);

  // ─── Navigation ────────────────────────────────────────────
  static const Color navBackground = Color(0xFFFFFFFF);
  static const Color navActive = Color(0xFF0F4C33);
  static const Color navInactive = Color(0xFFADB5BD);

  // ─── Shadows ───────────────────────────────────────────────
  static const Color shadowLight = Color(0x0A000000);
  static const Color shadowMedium = Color(0x1A000000);
  static const Color shadowStrong = Color(0x33000000);

  // ─── Map ───────────────────────────────────────────────────
  static const Color mapMarkerCar = Color(0xFF0F4C33);
  static const Color mapMarkerUser = Color(0xFF0F4C33);

  // ─── Gradient helpers ──────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A6B4A), Color(0xFF0A3322)],
  );
}
