import 'package:flutter/material.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/user_profile_model.dart';

/// Grouped settings menu sections with icons, toggles, and badges.
class SettingsSectionsWidget extends StatelessWidget {
  final List<SettingsSectionModel> sections;
  final ValueChanged<String>? onItemTapped;

  const SettingsSectionsWidget({
    super.key,
    required this.sections,
    this.onItemTapped,
  });

  IconData _iconFor(String id) {
    return switch (id) {
      'favorites' => Icons.favorite_outline_rounded,
      'support' => Icons.headset_mic_outlined,
      'terms' => Icons.privacy_tip_outlined,
      _ => Icons.settings_outlined,
    };
  }

  String _sectionTitle(AppLocalizations l10n, String id) {
    return switch (id) {
      'account' => l10n.settingsSectionAccount,
      'safety' => l10n.settingsSectionSafety,
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: sections.map((section) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(bottom: 8, end: 4),
                child: Text(
                  _sectionTitle(l10n, section.id),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.backgroundWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < section.items.length; i++) ...[
                      _SettingsRow(
                        item: section.items[i],
                        icon: _iconFor(section.items[i].id),
                        onTap: () => onItemTapped?.call(section.items[i].id),
                      ),
                      if (i < section.items.length - 1)
                        const Divider(
                          height: 1,
                          indent: 56,
                          color: AppColors.borderLight,
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final SettingsItemModel item;
  final IconData icon;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.item,
    required this.icon,
    this.onTap,
  });

  String _title(AppLocalizations l10n) => switch (item.id) {
    'favorites' => l10n.settingsFavoritesTitle,
    'support' => l10n.settingsSupportTitle,
    'terms' => l10n.settingsTermsTitle,
    _ => '',
  };

  String _subtitle(AppLocalizations l10n) => switch (item.id) {
    'favorites' => l10n.settingsFavoritesSubtitle,
    'support' => l10n.settingsSupportSubtitle,
    'terms' => l10n.settingsTermsSubtitle,
    _ => '',
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFE8EEF8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          _title(l10n),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (item.badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.badge!,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subtitle(l10n),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (item.trailingAction != null)
              GestureDetector(
                onTap: onTap,
                child: Text(
                  item.trailingAction!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              )
            else if (item.hasChevron)
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}
