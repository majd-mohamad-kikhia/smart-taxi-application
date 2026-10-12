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

  /// The brand green: buttons and solid fills. White text on it is 5.0:1.
  static const Color primary = Color(0xFF15803D);

  /// The same green, brighter: what has to stand out on the dark map and in
  /// glows (the pin, the route line, the taxi).
  static const Color primaryBright = Color(0xFF22C55E);

  /// The brand's cooler end: the teal the green fades into. White text on it
  /// is 5.5:1.
  static const Color accent = Color(0xFF0F766E);

  /// Foreground on [primary] and [accent]: white.
  static const Color textOnPrimary = white;

  /// A disabled primary button: the brand green dimmed to 40%.
  static const Color primaryDisabled = Color(0x6615803D);

  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);

  /// A warning, a pending state: it keeps its own amber so it still reads as
  /// one next to the green brand.
  static const Color warning = Color(0xFFF59E0B);

  /// The gold of a star rating.
  static const Color star = warning;

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
  static const Color mapRouteDriven = Color(0xFF3B82F6);

  /// The brand gradient, green to teal: the main buttons, the wallet card and
  /// the car-type sheet's request button. White text on either end is at
  /// least 5:1.
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, accent],
  );

  /// [primaryGradient] at 40%, for a disabled button.
  static const LinearGradient primaryGradientDisabled = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDisabled, Color(0x660F766E)],
  );
}
