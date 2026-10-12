import 'package:flutter/material.dart';

/// The colors that differ between the light and the dark theme: the page and
/// surface ladder, text, borders, tinted washes and the bottom bar. Read it
/// from the context — `context.colors.textPrimary` — so a screen follows the
/// active theme and repaints when it changes.
///
/// Colors that are the same in both themes (the brand greens, success / error
/// accents, white, black…) stay in `AppColors`.
///
/// Both palettes keep the same elevation ladder: page < surface < muted fill,
/// so cards and inputs stay distinct from the page in either theme.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  // Text.
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textLink;

  /// The brand green where it is text, an icon or an outline on a surface:
  /// a light green on dark, the deeper brand green on light.
  final Color primaryContent;
  final Color textOnPrimaryDisabled;
  final Color errorText;

  // Page / surface ladder.
  final Color neutralPage;
  final Color neutralSurface;
  final Color neutralMuted;
  final Color neutralDivider;
  final Color neutralBorder;

  /// Scaffold / page background — the lowest layer.
  final Color backgroundGray;

  /// Card / app bar / input / nav fill — one step above the page.
  final Color backgroundWhite;

  /// Chip, pill and inset fill, on top of a surface.
  final Color backgroundMuted;

  // Borders.
  final Color border;
  final Color borderLight;

  /// The outline of an input or outlined button, where the edge itself says
  /// "control".
  final Color borderStrong;

  // Washes behind a tinted icon or notice (the warning wash is the amber
  // of a caution, apart from the brand's own).
  final Color primarySurface;
  final Color accentSurface;
  final Color warningSurface;
  final Color successSurface;
  final Color errorSurface;

  // Bottom bar.
  final Color navBackground;
  final Color navActive;
  final Color navInactive;

  // Shadows.
  final Color shadowLight;
  final Color shadowMedium;
  final Color shadowStrong;

  const AppPalette({
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textLink,
    required this.primaryContent,
    required this.textOnPrimaryDisabled,
    required this.errorText,
    required this.neutralPage,
    required this.neutralSurface,
    required this.neutralMuted,
    required this.neutralDivider,
    required this.neutralBorder,
    required this.backgroundGray,
    required this.backgroundWhite,
    required this.backgroundMuted,
    required this.border,
    required this.borderLight,
    required this.borderStrong,
    required this.primarySurface,
    required this.accentSurface,
    required this.warningSurface,
    required this.successSurface,
    required this.errorSurface,
    required this.navBackground,
    required this.navActive,
    required this.navInactive,
    required this.shadowLight,
    required this.shadowMedium,
    required this.shadowStrong,
  });

  static const Color _gray = Color(0xFF9CA3AF);
  static const Color _green = Color(0xFF4ADE80);

  static const dark = AppPalette(
    textPrimary: Color(0xFFF5F6F7),
    textSecondary: Color(0xFFB4B8C0),
    textTertiary: Color(0xFF999DA6),
    textLink: _green,
    primaryContent: _green,
    textOnPrimaryDisabled: Color(0xB3F5F6F7),
    errorText: Color(0xFFF87171),
    neutralPage: Color(0xFF0F1012),
    neutralSurface: Color(0xFF1E1F22),
    neutralMuted: Color(0xFF2A2C30),
    neutralDivider: Color(0xFF26282C),
    neutralBorder: Color(0xFF34363B),
    backgroundGray: Color(0xFF0F1012),
    backgroundWhite: Color(0xFF1E1F22),
    backgroundMuted: Color(0xFF2A2C30),
    border: Color(0xFF34363B),
    borderLight: Color(0xFF26282C),
    borderStrong: Color(0xFF70747D),
    primarySurface: Color(0xFF12301F),
    accentSurface: Color(0xFF0F2E2C),
    warningSurface: Color(0xFF3D2A14),
    successSurface: Color(0xFF123420),
    errorSurface: Color(0xFF3B1619),
    navBackground: Color(0xFF1E1F22),
    navActive: _green,
    navInactive: _gray,
    shadowLight: Color(0x0A000000),
    shadowMedium: Color(0x1A000000),
    shadowStrong: Color(0x33000000),
  );

  static const light = AppPalette(
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF4B5563),
    textTertiary: Color(0xFF5B6270),
    textLink: Color(0xFF15803D),
    primaryContent: Color(0xFF15803D),
    // On the dimmed green of a disabled button over a white page.
    textOnPrimaryDisabled: Color(0xFF14532D),
    errorText: Color(0xFFB91C1C),
    neutralPage: Color(0xFFF4F5F7),
    neutralSurface: Color(0xFFFFFFFF),
    neutralMuted: Color(0xFFEDEFF2),
    neutralDivider: Color(0xFFE5E7EB),
    neutralBorder: Color(0xFFD9DCE1),
    backgroundGray: Color(0xFFF4F5F7),
    backgroundWhite: Color(0xFFFFFFFF),
    backgroundMuted: Color(0xFFEDEFF2),
    border: Color(0xFFD9DCE1),
    borderLight: Color(0xFFE5E7EB),
    borderStrong: Color(0xFF8A8F99),
    primarySurface: Color(0xFFDCFCE7),
    accentSurface: Color(0xFFCCFBF1),
    warningSurface: Color(0xFFFEEBCB),
    successSurface: Color(0xFFD9F5E6),
    errorSurface: Color(0xFFFDE2E2),
    navBackground: Color(0xFFFFFFFF),
    navActive: Color(0xFF15803D),
    navInactive: Color(0xFF6B7280),
    shadowLight: Color(0x0F000000),
    shadowMedium: Color(0x1F000000),
    shadowStrong: Color(0x33000000),
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      textPrimary: mix(textPrimary, other.textPrimary),
      textSecondary: mix(textSecondary, other.textSecondary),
      textTertiary: mix(textTertiary, other.textTertiary),
      textLink: mix(textLink, other.textLink),
      primaryContent: mix(primaryContent, other.primaryContent),
      textOnPrimaryDisabled: mix(
        textOnPrimaryDisabled,
        other.textOnPrimaryDisabled,
      ),
      errorText: mix(errorText, other.errorText),
      neutralPage: mix(neutralPage, other.neutralPage),
      neutralSurface: mix(neutralSurface, other.neutralSurface),
      neutralMuted: mix(neutralMuted, other.neutralMuted),
      neutralDivider: mix(neutralDivider, other.neutralDivider),
      neutralBorder: mix(neutralBorder, other.neutralBorder),
      backgroundGray: mix(backgroundGray, other.backgroundGray),
      backgroundWhite: mix(backgroundWhite, other.backgroundWhite),
      backgroundMuted: mix(backgroundMuted, other.backgroundMuted),
      border: mix(border, other.border),
      borderLight: mix(borderLight, other.borderLight),
      borderStrong: mix(borderStrong, other.borderStrong),
      primarySurface: mix(primarySurface, other.primarySurface),
      accentSurface: mix(accentSurface, other.accentSurface),
      warningSurface: mix(warningSurface, other.warningSurface),
      successSurface: mix(successSurface, other.successSurface),
      errorSurface: mix(errorSurface, other.errorSurface),
      navBackground: mix(navBackground, other.navBackground),
      navActive: mix(navActive, other.navActive),
      navInactive: mix(navInactive, other.navInactive),
      shadowLight: mix(shadowLight, other.shadowLight),
      shadowMedium: mix(shadowMedium, other.shadowMedium),
      shadowStrong: mix(shadowStrong, other.shadowStrong),
    );
  }
}

/// `context.colors` — the active theme's [AppPalette]. Under a plain
/// `ThemeData` (a widget test, a third-party route) it falls back to the
/// palette that matches the theme's brightness, so it never fails.
extension AppPaletteContext on BuildContext {
  AppPalette get colors {
    final theme = Theme.of(this);
    return theme.extension<AppPalette>() ??
        (theme.brightness == Brightness.dark
            ? AppPalette.dark
            : AppPalette.light);
  }
}
