import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/user_profile_model.dart';

/// Grouped settings menu sections with icons, toggles, and badges.
class SettingsSectionsWidget extends StatelessWidget {
  final List<SettingsSectionModel> sections;
  final bool notificationsEnabled;
  final ValueChanged<bool>? onNotificationsChanged;
  final ValueChanged<String>? onItemTapped;

  const SettingsSectionsWidget({
    super.key,
    required this.sections,
    required this.notificationsEnabled,
    this.onNotificationsChanged,
    this.onItemTapped,
  });

  IconData _iconFor(String id) {
    return switch (id) {
      'payments' => Icons.credit_card_rounded,
      'favorites' => Icons.favorite_outline_rounded,
      'notifications' => Icons.notifications_outlined,
      'language' => Icons.language_rounded,
      'theme' => Icons.wb_sunny_outlined,
      'safety' => Icons.health_and_safety_outlined,
      'support' => Icons.headset_mic_outlined,
      'terms' => Icons.privacy_tip_outlined,
      _ => Icons.settings_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: sections.map((section) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8, right: 4),
                child: Text(
                  section.title,
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
                        toggleValue: section.items[i].id == 'notifications'
                            ? notificationsEnabled
                            : null,
                        onToggle: section.items[i].id == 'notifications'
                            ? onNotificationsChanged
                            : null,
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
  final bool? toggleValue;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.item,
    required this.icon,
    this.toggleValue,
    this.onToggle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.hasToggle ? null : onTap,
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
                          item.title,
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
                    item.subtitle,
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
            if (item.hasToggle && toggleValue != null)
              Switch.adaptive(
                value: toggleValue!,
                activeTrackColor: AppColors.primary,
                onChanged: onToggle,
              )
            else if (item.trailingAction != null)
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
                Icons.chevron_left_rounded,
                color: AppColors.textTertiary,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}
