import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_palette.dart';
import 'app_icon_tile_widget.dart';

/// One tappable row of a settings list: a leading icon, a label and a
/// trailing chevron that mirrors in Arabic. At least 56dp tall and read as a
/// button. Use inside a `SettingsSectionWidget`.
class SettingsRowWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const SettingsRowWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: label,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingL,
              vertical: AppConstants.paddingM,
            ),
            child: Row(
              children: [
                AppIconTileWidget(icon: icon, size: 36),
                const SizedBox(width: AppConstants.paddingM),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: context.colors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
