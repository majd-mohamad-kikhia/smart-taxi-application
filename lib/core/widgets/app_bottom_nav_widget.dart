import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';

/// One tab definition for [AppBottomNavWidget].
class AppNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const AppNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Shared bottom navigation bar used by every tab-based app shell
/// (customer, driver, ...). Each shell supplies its own [items].
///
/// The current tab is shown three ways, never by color alone: an amber
/// wash pill behind its icon, a filled icon and a heavier label. Each tab is
/// a real button (focus, "selected" for screen readers) with no ripple: when
/// pressed, its icon and label ease in slightly instead, which stays quiet
/// when you tap or hold. The bar is at least 60dp tall and grows with the
/// system text size.
class AppBottomNavWidget extends StatelessWidget {
  final int currentIndex;
  final List<AppNavItem> items;
  final ValueChanged<int>? onTap;

  const AppBottomNavWidget({
    super.key,
    required this.currentIndex,
    required this.items,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.navBackground,
        border: Border(
          top: BorderSide(color: AppColors.borderLight, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      // The tabs are InkWells, which need a Material above them (the ripple
      // itself is switched off).
      child: Material(
        color: AppColors.transparent,
        child: SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 60),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < items.length; i++)
                    _NavItem(
                      index: i,
                      isActive: i == currentIndex,
                      item: items[i],
                      onTap: onTap,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  static const double _pillWidth = 56;
  static const double _pillHeight = 32;

  final int index;
  final bool isActive;
  final AppNavItem item;
  final ValueChanged<int>? onTap;

  const _NavItem({
    required this.index,
    required this.isActive,
    required this.item,
    this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isActive = widget.isActive;
    final color = isActive ? AppColors.navActive : AppColors.navInactive;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppConstants.animFast;

    return Expanded(
      child: Semantics(
        container: true,
        button: true,
        selected: isActive,
        label: item.label,
        excludeSemantics: true,
        child: InkWell(
          onTap: () => widget.onTap?.call(widget.index),
          onHighlightChanged: (pressed) => setState(() => _isPressed = pressed),
          // No ripple, no grey press patch. Only keyboard focus keeps a
          // visible wash, so the bar stays usable without a touchscreen.
          splashFactory: NoSplash.splashFactory,
          highlightColor: AppColors.transparent,
          hoverColor: AppColors.transparent,
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.focused)
                ? AppColors.accent.withValues(alpha: 0.12)
                : AppColors.transparent,
          ),
          child: AnimatedScale(
            scale: _isPressed ? 0.92 : 1,
            duration: duration,
            curve: Curves.easeOutCubic,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: duration,
                  width: _NavItem._pillWidth,
                  height: _NavItem._pillHeight,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.accentSurface
                        : AppColors.transparent,
                    borderRadius: BorderRadius.circular(
                      AppConstants.radiusFull,
                    ),
                  ),
                  child: Icon(
                    isActive ? item.activeIcon : item.icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingXS,
                  ),
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
