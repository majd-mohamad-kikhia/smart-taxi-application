import 'package:flutter/material.dart';
import '../theme/app_palette.dart';
import 'app_section_label_widget.dart';
import 'app_surface_card_widget.dart';

/// The small heading above a group on a settings screen. Use it on its own
/// above a control that is already a card (the language picker, a slider);
/// [SettingsSectionWidget] adds it above a list of rows.
class SettingsHeadingWidget extends StatelessWidget {
  final String title;

  const SettingsHeadingWidget({super.key, required this.title});

  @override
  Widget build(BuildContext context) => AppSectionLabelWidget(label: title);
}

/// A titled group of rows on a settings screen: the heading, then its rows in
/// one card with a hairline between them. Grouping the rows by what they are
/// for (preferences, help, account) lets a screen of eight things be scanned
/// as three.
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
        SizedBox(
          width: double.infinity,
          child: AppSurfaceCardWidget(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0)
                    Divider(height: 1, color: context.colors.borderLight),
                  children[i],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
