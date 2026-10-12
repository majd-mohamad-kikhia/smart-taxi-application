import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';
import 'app_colors.dart';
import 'app_palette.dart';

/// The app's two themes, built once (the font text themes are not cheap) and
/// shared: [dark] and [light]. Both carry their [AppPalette], read in widgets
/// as `context.colors`.
class AppTheme {
  AppTheme._();

  static final ThemeData dark = _build(AppPalette.dark, Brightness.dark);
  static final ThemeData light = _build(AppPalette.light, Brightness.light);

  static ThemeData _build(AppPalette p, Brightness brightness) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        onPrimary: AppColors.textOnPrimary,
        secondary: AppColors.accent,
        onSecondary: AppColors.textOnPrimary,
        surface: p.backgroundWhite,
        onSurface: p.textPrimary,
        error: AppColors.error,
        onError: AppColors.textOnPrimary,
        brightness: brightness,
      ),
      scaffoldBackgroundColor: p.backgroundGray,
    );

    return base.copyWith(
      extensions: [p],
      textTheme: GoogleFonts.tajawalTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.tajawal(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: p.textPrimary,
        ),
        displayMedium: GoogleFonts.tajawal(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: p.textPrimary,
        ),
        displaySmall: GoogleFonts.tajawal(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: p.textPrimary,
        ),
        headlineLarge: GoogleFonts.tajawal(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: p.textPrimary,
        ),
        headlineMedium: GoogleFonts.tajawal(
          fontSize: 21,
          fontWeight: FontWeight.w800,
          color: p.textPrimary,
        ),
        headlineSmall: GoogleFonts.tajawal(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: p.textPrimary,
        ),
        titleLarge: GoogleFonts.tajawal(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: p.textPrimary,
        ),
        titleMedium: GoogleFonts.tajawal(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: p.textPrimary,
        ),
        titleSmall: GoogleFonts.tajawal(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: p.textPrimary,
        ),
        bodyLarge: GoogleFonts.tajawal(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: p.textPrimary,
        ),
        bodyMedium: GoogleFonts.tajawal(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: p.textSecondary,
        ),
        bodySmall: GoogleFonts.tajawal(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: p.textTertiary,
        ),
        labelLarge: GoogleFonts.tajawal(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: p.textPrimary,
        ),
        labelMedium: GoogleFonts.tajawal(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: p.textSecondary,
        ),
        labelSmall: GoogleFonts.tajawal(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: p.textTertiary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.backgroundWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: AppColors.transparent,
        systemOverlayStyle: overlayStyleFor(brightness),
        titleTextStyle: GoogleFonts.tajawal(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: p.textPrimary,
        ),
        iconTheme: IconThemeData(color: p.textPrimary),
        actionsIconTheme: IconThemeData(color: p.textPrimary),
      ),
      // The back button as an outlined circle, the way every screen header
      // draws its round icon buttons.
      actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (context) => Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: p.backgroundWhite,
            shape: BoxShape.circle,
            border: Border.all(color: p.border),
          ),
          child: Icon(Icons.arrow_back_rounded, size: 20, color: p.textPrimary),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: p.navBackground,
        selectedItemColor: p.navActive,
        unselectedItemColor: p.navInactive,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.tajawal(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.tajawal(
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
          shape: const StadiumBorder(),
          minimumSize: const Size(0, 56),
          textStyle: GoogleFonts.tajawal(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: p.primarySurface,
          foregroundColor: p.primaryContent,
          side: BorderSide.none,
          shape: const StadiumBorder(),
          minimumSize: const Size(0, 52),
          textStyle: GoogleFonts.tajawal(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.backgroundMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: _inputBorder(BorderSide.none),
        enabledBorder: _inputBorder(BorderSide.none),
        errorBorder: _inputBorder(BorderSide(color: p.errorText)),
        focusedErrorBorder: _inputBorder(BorderSide(color: p.errorText, width: 1.5)),
        errorStyle: GoogleFonts.tajawal(fontSize: 12, color: p.errorText),
        focusedBorder: _inputBorder(
          const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        hintStyle: GoogleFonts.tajawal(fontSize: 14, color: p.textTertiary),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? p.primarySurface
                : p.backgroundMuted,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? p.primaryContent
                : p.textSecondary,
          ),
          side: WidgetStatePropertyAll(BorderSide(color: p.border)),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          visualDensity: VisualDensity.compact,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: p.borderLight,
        thickness: 1,
        space: 0,
      ),
      cardTheme: CardThemeData(
        color: p.backgroundWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          side: BorderSide(color: p.borderLight, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.backgroundWhite,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: p.border,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppConstants.radiusXL),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.textPrimary,
        contentTextStyle: GoogleFonts.tajawal(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: p.backgroundWhite,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.backgroundMuted,
        selectedColor: p.primarySurface,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        labelStyle: GoogleFonts.tajawal(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: p.textPrimary,
        ),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(BorderSide side) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
    borderSide: side,
  );

  /// Status bar icons that read on the theme's page: light icons on dark,
  /// dark icons on light. The bar itself is transparent.
  static SystemUiOverlayStyle overlayStyleFor(Brightness theme) {
    final isDark = theme == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: AppColors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
    );
  }
}
