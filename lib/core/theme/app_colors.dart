import 'package:flutter/material.dart';

/// Centralized color palette for the Mshoar app.
/// Strictly follows the brand identity from the design specs.
///
/// The app runs a single (dark) theme — see [AppTheme.darkTheme]. The
/// neutral scale below defines an elevation ladder (page < surface < muted
/// fill) so cards and inputs stay visually distinct from the page instead
/// of both collapsing to the same black.
///
/// Feature code never writes a raw color (`Colors.*`, `Color(0x…)`): every
/// color the UI paints is a named token here.
class AppColors {
  AppColors._();

  static const Color transparent = Color(0x00000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color gray = Color(0xFF9CA3AF);
  static const Color darkGray = Color(0xFF374151);
  static const Color primaryYellow = Color(0xFFFFD600);
  static const Color orangeGold = Color(0xFFF59E0B);

  // Kept as its own ladder instead of deriving from [white]
  // so page, card and chip fills can each get a distinct value.
  static const Color neutralPage = Color(0xFF0F1012);
  static const Color neutralSurface = Color(0xFF1E1F22);
  static const Color neutralMuted = Color(0xFF2A2C30);
  static const Color neutralDivider = Color(0xFF26282C);
  static const Color neutralBorder = Color(0xFF34363B);

  static const Color primary = primaryYellow;
  static const Color primarySurface = Color(0xFF3A3216);

  static const Color accent = orangeGold;
  static const Color accentSurface = Color(0xFF3D2A14);

  /// Card / app bar / input / nav fill — one step lighter than the page.
  static const Color backgroundWhite = neutralSurface;

  /// Scaffold / page background — the darkest layer.
  static const Color backgroundGray = neutralPage;

  /// Chip, pill and inset-fill background — sits on top of a surface,
  /// so it's a touch lighter than [backgroundWhite].
  static const Color backgroundMuted = neutralMuted;

  static const Color border = neutralBorder;
  static const Color borderLight = neutralDivider;

  /// The outline of an input or an outlined button, where the edge itself
  /// tells you it is a control: 3.5:1 on a surface and 4.1:1 on the page.
  /// [border] stays for cards, which are separated by their fill.
  static const Color borderStrong = Color(0xFF70747D);

  static const Color textPrimary = Color(0xFFF5F6F7);
  static const Color textSecondary = Color(0xFFB4B8C0);
  static const Color textTertiary = Color(0xFF999DA6);
  static const Color textLink = orangeGold;

  /// Foreground used on top of [primary]. Dark, because the brand
  /// primary is a light yellow — white would be unreadable on it.
  static const Color textOnPrimary = darkGray;

  /// A disabled primary button: the brand yellow dimmed to 40%, with a
  /// light label, so it still reads as "the yellow button, not available"
  /// instead of falling back to Material's neutral gray.
  static const Color primaryDisabled = Color(0x66FFD600);
  static const Color textOnPrimaryDisabled = Color(0xB3F5F6F7);

  static const Color success = Color(0xFF10B981);
  static const Color successSurface = Color(0xFF123420);
  static const Color error = Color(0xFFEF4444);
  static const Color errorSurface = Color(0xFF3B1619);

  /// Error as small text (a validation or failure line): [error] is only
  /// 4.4:1 on a surface, this is 6:1 there and 5.1:1 on the muted fill.
  static const Color errorText = Color(0xFFF87171);
  static const Color warning = orangeGold;

  /// Solid fill for a destructive action: white text on it is 4.8:1,
  /// where white on [error] is only 3.8:1.
  static const Color errorDark = Color(0xFFDC2626);

  /// Foreground on [success] (dark: white on this green is only 2.5:1).
  static const Color textOnSuccess = neutralPage;

  static const Color navBackground = neutralSurface;
  static const Color navActive = orangeGold;
  static const Color navInactive = gray;

  static const Color shadowLight = Color(0x0A000000);
  static const Color shadowMedium = Color(0x1A000000);
  static const Color shadowStrong = Color(0x33000000);

  /// Dimmer behind dialogs (45% black) and behind blocking overlays (54%).
  static const Color scrim = Color(0x73000000);
  static const Color scrimStrong = Color(0x8A000000);

  static const Color mapRoutePlanned = primaryYellow;
  static const Color mapRouteDriven = Color(0xFF3B82F6);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryYellow, orangeGold],
  );
}
