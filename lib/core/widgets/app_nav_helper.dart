import 'package:flutter/material.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';

/// Shared bottom-nav tap handler for main tab screens.
class AppNavHelper {
  AppNavHelper._();

  static void handleTap(
    BuildContext context,
    int index, {
    required int current,
  }) {
    if (index == current) return;

    if (index == 0) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.home,
        (route) => false,
      );
      return;
    }

    if (index == 1) {
      Navigator.of(context).pushNamed(AppRouter.trips);
      return;
    }

    if (index == 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('المحفظة قريباً'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    if (index == 3) {
      Navigator.of(context).pushNamed(AppRouter.settings);
    }
  }
}
