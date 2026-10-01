import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';

/// The small heading above a group on a settings screen. Use it on its own
/// above a control that is already a card (the language picker, a slider);
/// [SettingsSectionWidget] adds it above a list of rows.
class SettingsHeadingWidget extends StatelessWidget {
  final String title;

  const SettingsHeadingWidget({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppConstants.paddingXS,
        bottom: AppConstants.paddingS,
      ),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// A titled group of rows on a settings screen: the heading, then its rows in
/// one bordered card with a hairline between them. Grouping the rows by what
/// they are for (preferences, help, account) lets a screen of eight things be
/// scanned as three.
class SettingsSectionWidget extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsSectionWidget({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsHeadingWidget(title: title),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.backgroundWhite,
            borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: AppColors.borderLight),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}
