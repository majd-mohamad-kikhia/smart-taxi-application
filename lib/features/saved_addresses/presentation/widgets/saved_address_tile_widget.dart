import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/saved_addresses/data/models/saved_address_model.dart';
import '../../../../core/saved_addresses/data/models/saved_place_preset.dart';
import '../../../../core/saved_addresses/presentation/saved_address_type_ui.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_icon_tile_widget.dart';

/// One row of the "Saved places" screen. With an [address] it shows the
/// place (tap to edit, menu to edit or delete); without one it is the
/// "Add home" / "Add work" (or, with a [preset], "Add gym"…) invitation.
class SavedAddressTileWidget extends StatelessWidget {
  final SavedAddressType type;
  final SavedPlacePreset? preset;
  final SavedAddressModel? address;
  final bool isDeleting;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const SavedAddressTileWidget({
    super.key,
    required this.type,
    required this.address,
    required this.onTap,
    this.preset,
    this.onDelete,
    this.isDeleting = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final address = this.address;
    final preset = this.preset;
    final accent = address?.accent ?? preset?.accent ?? type.accent;
    final title = address?.title(l10n) ??
        (preset != null
            ? l10n.savedAddressAddNamed(preset.name(l10n))
            : type == SavedAddressType.work
                ? l10n.savedAddressAddWork
                : l10n.savedAddressAddHome);
    final subtitle = address == null
        ? null
        : [address.address, address.addressDetails]
            .whereType<String>()
            .where((s) => s.trim().isNotEmpty)
            .join(' · ');

    return Material(
      color: context.colors.backgroundWhite,
      borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        onTap: isDeleting ? null : onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingL,
            vertical: AppConstants.paddingM,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
            border: Border.all(color: context.colors.borderLight),
          ),
          child: Row(
            children: [
              AppIconTileWidget(
                icon: address?.icon ?? Icons.add_rounded,
                background: accent.wash(context),
                foreground: accent.foreground(context),
              ),
              const SizedBox(width: AppConstants.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.titleSmall),
                    if (subtitle != null && subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isDeleting)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (address != null && onDelete != null)
                IconButton(
                  tooltip: l10n.delete,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: context.colors.textSecondary,
                  ),
                  onPressed: onDelete,
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  color: context.colors.textTertiary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
