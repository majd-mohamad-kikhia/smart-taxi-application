import 'package:flutter/material.dart';
import '../routing/app_router.dart';
import '../theme/app_colors.dart';
import 'app_logo_widget.dart';

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
          // The brand mark sits at the start edge: right in Arabic (RTL),
          // left in English (LTR).
          const Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: _BrandLogoWidget(),
            ),
          ),
          if (showNotifications) const _NotificationBellWidget(),
        ],
      ),
    );
  }
}

class _BrandLogoWidget extends StatelessWidget {
  const _BrandLogoWidget();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppLogoWidget(size: 38),
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
        ],
      ),
    );
  }
}
