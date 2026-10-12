import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';

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
/// The bar floats over the page, inset from its edges. Its shell must set
/// `extendBody: true`, so nothing is painted behind it. The current tab is shown
/// three ways, never by color alone: a solid green pill behind its icon, a
/// filled icon and a heavier label. Each tab is a real button (focus, "selected" for screen readers) with no ripple: when
/// pressed, its icon and label ease in slightly instead, which stays quiet
/// when you tap or hold. The bar is at least 64dp tall and grows with the
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
    // A floating rounded bar inset from the screen edges, with nothing
    // painted behind it: the shells extend their body under the bar, so the
    // page or the map shows around it.
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: AppConstants.paddingS),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppConstants.paddingL,
          AppConstants.paddingXS,
          AppConstants.paddingL,
          AppConstants.paddingS,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.colors.navBackground,
            borderRadius: BorderRadius.circular(AppConstants.radiusXL),
            border: Border.all(color: context.colors.borderLight),
            boxShadow: [
              BoxShadow(
                color: context.colors.shadowMedium,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          // The tabs are InkWells, which need a Material above them (the
          // ripple itself is switched off).
          child: Material(
            color: AppColors.transparent,
            borderRadius: BorderRadius.circular(AppConstants.radiusXL),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
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
    final color = isActive ? context.colors.navActive : context.colors.navInactive;
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
                ? context.colors.navActive.withValues(alpha: 0.12)
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
                    color: isActive ? AppColors.primary : AppColors.transparent,
                    borderRadius: BorderRadius.circular(
                      AppConstants.radiusFull,
                    ),
                  ),
                  child: Icon(
                    isActive ? item.activeIcon : item.icon,
                    color: isActive ? AppColors.textOnPrimary : color,
                    size: 22,
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
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
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
