import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../localization/l10n_context_extension.dart';
import '../theme/app_palette.dart';

/// The customer's note for the driver ("I have two suitcases") on a soft
/// green wash, labelled so it never reads as an address.
class RideNoteWidget extends StatelessWidget {
  final String note;

  /// Caps the note on cards; leave null to show it whole.
  final int? maxLines;

  const RideNoteWidget({super.key, required this.note, this.maxLines});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final label = context.l10n.rideNoteLabel;
    return Semantics(
      label: '$label: $note',
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppConstants.paddingM),
        decoration: BoxDecoration(
          color: context.colors.primarySurface,
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.sticky_note_2_outlined, size: 18, color: context.colors.primaryContent),
            const SizedBox(width: AppConstants.paddingS),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: textTheme.labelMedium?.copyWith(color: context.colors.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    note,
                    maxLines: maxLines,
                    overflow: maxLines == null ? null : TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
