import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_icon_tile_widget.dart';
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
        color: context.colors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        border: Border.all(color: context.colors.borderLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // The person on the card's solid green top: photo, name, contacts.
          Container(
            width: double.infinity,
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(
              AppConstants.paddingL,
              AppConstants.paddingXL,
              AppConstants.paddingL,
              AppConstants.paddingL,
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.white.withValues(alpha: 0.3),
                  ),
                  child: NetworkPhotoWidget(
                    imagePath: profile.photoUrl,
                    width: 84,
                    height: 84,
                    borderRadius: 42,
                    placeholderIcon: Icons.person_rounded,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingM),
                Text(
                  profile.fullName,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.headlineMedium?.copyWith(
                    color: AppColors.textOnPrimary,
                  ),
                ),
                if (profile.phone.isNotEmpty) ...[
                  const SizedBox(height: AppConstants.paddingS),
                  _ContactRow(icon: Icons.phone_outlined, text: profile.phone),
                ],
                if (profile.email.isNotEmpty) ...[
                  const SizedBox(height: AppConstants.paddingXS),
                  _ContactRow(icon: Icons.email_outlined, text: profile.email),
                ],
              ],
            ),
          ),
          Divider(height: 1, color: context.colors.borderLight),
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
                        const AppIconTileWidget(
                          icon: Icons.edit_outlined,
                          size: 36,
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
                        Icon(
                          Icons.chevron_right_rounded,
                          color: context.colors.textTertiary,
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.textOnPrimary.withValues(alpha: 0.85),
        ),
        const SizedBox(width: AppConstants.paddingS),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            // Phone numbers and emails read left to right in any language.
            textDirection: TextDirection.ltr,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textOnPrimary.withValues(alpha: 0.9),
            ),
          ),
        ),
      ],
    );
  }
}
