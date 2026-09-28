import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../routing/app_router.dart';
import '../theme/app_colors.dart';

/// Shared brand top bar — the Mshoar logo pinned to the physical right
/// edge — used as the app bar for both the rider and driver apps so the
/// two look alike. `showNotifications` is the only difference between
/// them: the rider bar shows the bell (physical left edge), the driver
/// bar doesn't.
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
          // Alignment.centerRight is a physical (non-directional)
          // alignment, so the brand mark sits at the screen's right
          // edge regardless of the app's RTL layout direction.
          const Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: _BrandLogoWidget(),
            ),
          ),
          if (showNotifications) const _NotificationBellWidget(),
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
          borderRadius: BorderRadius.circular(9),
          child: Image.asset(
            AppConstants.logoPath,
            width: 38,
            height: 38,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: const Text(
            'Smart Taxi',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
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
