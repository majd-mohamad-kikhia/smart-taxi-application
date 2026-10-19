import 'package:flutter/material.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/format_distance.dart';
import '../../data/models/place_suggestion_model.dart';

/// One row of the place search list: the place's name, its distance from the
/// customer when known, and a history icon when the customer picked it
/// before.
class PlaceSuggestionTileWidget extends StatelessWidget {
  final PlaceSuggestionModel suggestion;
  final VoidCallback onTap;

  const PlaceSuggestionTileWidget({
    super.key,
    required this.suggestion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(
        suggestion.isRecent ? Icons.history_rounded : Icons.place_outlined,
        color: context.colors.textSecondary,
        size: 20,
      ),
      title: Text(
        suggestion.description,
        style: TextStyle(color: context.colors.textPrimary, fontSize: 13.5),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: suggestion.distanceMeters == null
          ? null
          : Text(
              formatDistance(context.l10n, suggestion.distanceMeters!),
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 12,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
      onTap: onTap,
    );
  }
}
