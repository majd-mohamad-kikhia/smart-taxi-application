import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../routing/app_router.dart';
import '../theme/app_colors.dart';

/// Shared brand top bar — a centered Mshoar logo, used as the app bar for
/// both the rider and driver apps so the two look alike. `showNotifications`
/// is the only difference between them: the rider bar shows the bell, the
/// driver bar doesn't.
///
/// Lives in `core/widgets` (not `features/home`) because both
/// `features/home` and `driver_features` render it — per the project's
/// "shared across features → core" rule.
class AppBrandBarWidget extends StatelessWidget {
  final bool showNotifications;

  const AppBrandBarWidget({super.key, this.showNotifications = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundWhite,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      child: Row(
        children: [
          // Mirrors the trailing slot's width so the logo stays centered
          // whether or not the notification bell is shown.
          const SizedBox(width: 44),
          const Expanded(child: Center(child: _BrandLogoWidget())),
          if (showNotifications)
            const _NotificationBellWidget()
          else
            const SizedBox(width: 44),
        ],
      ),
    );
  }
}

/// The Mshoar brand mark: logo image + wordmark.
class _BrandLogoWidget extends StatelessWidget {
  const _BrandLogoWidget();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            AppConstants.logoPath,
            width: 30,
            height: 30,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'مشوار',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

/// Notification bell icon with an unread badge — rider only.
class _NotificationBellWidget extends StatelessWidget {
  const _NotificationBellWidget();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(AppRouter.notifications),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.backgroundGray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: AppColors.textPrimary,
              size: 22,
            ),
          ),
          // Unread badge
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.backgroundGray, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
