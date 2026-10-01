import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/network_photo_widget.dart';
import '../../data/models/user_profile_model.dart';

/// Profile card: avatar, name, contact lines, and a tappable "edit personal
/// info" row. Flat like every card at rest: a border, no shadow, no gradient.
/// A phone number and an email are left-to-right values, kept in order inside
/// Arabic text.
class ProfileCardWidget extends StatelessWidget {
  final UserProfileModel profile;
  final VoidCallback? onEdit;

  const ProfileCardWidget({super.key, required this.profile, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingL),
            child: Row(
              children: [
                NetworkPhotoWidget(
                  imagePath: profile.photoUrl,
                  width: 64,
                  height: 64,
                  borderRadius: 32,
                  placeholderIcon: Icons.person_rounded,
                ),
                const SizedBox(width: AppConstants.paddingL),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.fullName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (profile.phone.isNotEmpty) ...[
                        const SizedBox(height: AppConstants.paddingS),
                        _ContactRow(
                          icon: Icons.phone_outlined,
                          text: profile.phone,
                        ),
                      ],
                      if (profile.email.isNotEmpty) ...[
                        const SizedBox(height: AppConstants.paddingXS),
                        _ContactRow(
                          icon: Icons.email_outlined,
                          text: profile.email,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderLight),
          // The ink lives on a Material above the card's fill, so the press
          // shows.
          Material(
            color: AppColors.transparent,
            child: Semantics(
              button: true,
              excludeSemantics: true,
              label: l10n.editPersonalInfo,
              onTap: onEdit,
              child: InkWell(
                onTap: onEdit,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 56),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingL,
                      vertical: AppConstants.paddingM,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppConstants.paddingS),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(
                              AppConstants.radiusMedium,
                            ),
                          ),
                          child: const Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: AppConstants.paddingM),
                        Expanded(
                          child: Text(
                            l10n.editPersonalInfo,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textTertiary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ContactRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: AppConstants.paddingS),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            // Phone numbers and emails read left to right in any language.
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.start,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
