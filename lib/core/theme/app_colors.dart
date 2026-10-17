import 'package:flutter/material.dart';

/// The colors that are the same in the light and the dark theme: the brand
/// greens, the success / error / warning accents, white and black, the map
/// route colors. Everything that changes with the theme (page, surface,
/// text, borders, tinted washes) is in `AppPalette` — `context.colors`.
///
/// Feature code never writes a raw color (`Colors.*`, `Color(0x…)`): every
/// color the UI paints is a named token here or in the palette.
class AppColors {
  AppColors._();

  static const Color transparent = Color(0x00000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color gray = Color(0xFF9CA3AF);
  static const Color darkGray = Color(0xFF374151);

  /// The brand green, a deep forest: buttons and solid fills. White text on
  /// it is 6.6:1.
  static const Color primary = Color(0xFF0B6B3A);

  /// The same green, brighter: what has to stand out on the dark map (the
  /// pin, the route line, the taxi).
  static const Color primaryBright = Color(0xFF1F9D55);

  /// The brand's dark ink green: solid fills that mark an end point (the
  /// destination square). Too dark to read on the dark theme as an icon or
  /// text — use `context.colors.accentContent` there. White text on it is
  /// 14:1.
  static const Color accent = Color(0xFF123524);

  /// Foreground on [primary] and [accent]: white.
  static const Color textOnPrimary = white;

  /// A disabled primary button: the brand green dimmed to 40%.
  static const Color primaryDisabled = Color(0x660B6B3A);

  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);

  /// A warning, a pending state: it keeps its own amber so it still reads as
  /// one next to the green brand.
  static const Color warning = Color(0xFFF59E0B);

  /// The green of a star rating.
  static const Color star = primaryBright;

  /// Foreground on [warning]: dark (white on amber is only 2.1:1).
  static const Color textOnWarning = darkGray;

  /// Solid fill for a destructive action: white text on it is 4.8:1, where
  /// white on [error] is only 3.8:1.
  static const Color errorDark = Color(0xFFDC2626);

  /// Foreground on [success] (dark: white on this green is only 2.5:1).
  static const Color textOnSuccess = Color(0xFF0F1012);

  /// Dimmer behind dialogs (45% black) and behind blocking overlays (54%).
  static const Color scrim = Color(0x73000000);
  static const Color scrimStrong = Color(0x8A000000);

  static const Color mapRoutePlanned = primaryBright;
  static const Color mapRouteDriven = Color(0xFF8FB5A0);

  /// Fill of the round helper buttons over a map: a green that is almost
  /// white, with [primary] icons, the same in light and dark themes.
  static const Color mapControlFill = Color(0xFFEFF9F2);
}
