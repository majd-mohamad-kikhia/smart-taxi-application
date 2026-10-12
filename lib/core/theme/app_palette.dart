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

  /// The dark ink green where it is an icon, text or marker on a surface
  /// (the destination point): the ink itself on light, a pale green-gray on
  /// dark, where the ink would vanish.
  final Color accentContent;
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
    required this.accentContent,
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

  static const Color _gray = Color(0xFF8A9C92);
  static const Color _green = Color(0xFF5FCB8B);

  static const dark = AppPalette(
    textPrimary: Color(0xFFE7F0EA),
    textSecondary: Color(0xFFA9BAB0),
    textTertiary: Color(0xFF8A9C92),
    textLink: _green,
    primaryContent: _green,
    accentContent: Color(0xFFB7CEC0),
    textOnPrimaryDisabled: Color(0xB3E7F0EA),
    errorText: Color(0xFFF87171),
    neutralPage: Color(0xFF0B1410),
    neutralSurface: Color(0xFF13201A),
    neutralMuted: Color(0xFF1B2B23),
    neutralDivider: Color(0xFF1F3027),
    neutralBorder: Color(0xFF26382E),
    backgroundGray: Color(0xFF0B1410),
    backgroundWhite: Color(0xFF13201A),
    backgroundMuted: Color(0xFF1B2B23),
    border: Color(0xFF26382E),
    borderLight: Color(0xFF1F3027),
    borderStrong: Color(0xFF6B8074),
    primarySurface: Color(0xFF173A27),
    accentSurface: Color(0xFF1B2B23),
    warningSurface: Color(0xFF3D2A14),
    successSurface: Color(0xFF173A27),
    errorSurface: Color(0xFF3B1619),
    navBackground: Color(0xFF13201A),
    navActive: _green,
    navInactive: _gray,
    shadowLight: Color(0x0A000000),
    shadowMedium: Color(0x1A000000),
    shadowStrong: Color(0x33000000),
  );

  static const light = AppPalette(
    textPrimary: Color(0xFF0F1F17),
    textSecondary: Color(0xFF4A5B51),
    textTertiary: Color(0xFF5E6E64),
    textLink: Color(0xFF0B6B3A),
    primaryContent: Color(0xFF0B6B3A),
    accentContent: Color(0xFF123524),
    // On the dimmed green of a disabled button over the mint page.
    textOnPrimaryDisabled: Color(0xFF0B4A28),
    errorText: Color(0xFFB91C1C),
    neutralPage: Color(0xFFF0F6F1),
    neutralSurface: Color(0xFFFFFFFF),
    neutralMuted: Color(0xFFE6F1E9),
    neutralDivider: Color(0xFFE7F0EA),
    neutralBorder: Color(0xFFDCE8DF),
    backgroundGray: Color(0xFFF0F6F1),
    backgroundWhite: Color(0xFFFFFFFF),
    backgroundMuted: Color(0xFFE6F1E9),
    border: Color(0xFFDCE8DF),
    borderLight: Color(0xFFE7F0EA),
    borderStrong: Color(0xFF7F9188),
    primarySurface: Color(0xFFDDEFE3),
    accentSurface: Color(0xFFE6F1E9),
    warningSurface: Color(0xFFFEEBCB),
    successSurface: Color(0xFFD9F5E6),
    errorSurface: Color(0xFFFCE8E8),
    navBackground: Color(0xFFFFFFFF),
    navActive: Color(0xFF0B6B3A),
    navInactive: Color(0xFF66766C),
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
      accentContent: mix(accentContent, other.accentContent),
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
