import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/geo/geo_models.dart';
import '../../../../core/theme/app_palette.dart';

/// The places that match what is being typed (at most 5), as a card of rows
/// above the From / To card. Only the place's name is shown: the list is our
/// own places, there is no address line.
class PlaceSuggestionsListWidget extends StatelessWidget {
  final List<GeoSuggestionModel> suggestions;
  final ValueChanged<GeoSuggestionModel> onSelected;

  const PlaceSuggestionsListWidget({
    super.key,
    required this.suggestions,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.colors.neutralSurface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < suggestions.length; i++) ...[
            if (i > 0) Divider(height: 1, color: context.colors.borderLight),
            _SuggestionTileWidget(
              suggestion: suggestions[i],
              onTap: () => onSelected(suggestions[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _SuggestionTileWidget extends StatelessWidget {
  final GeoSuggestionModel suggestion;
  final VoidCallback onTap;

  const _SuggestionTileWidget({required this.suggestion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingL,
          vertical: AppConstants.paddingM,
        ),
        child: Row(
          children: [
            Icon(
              Icons.place_outlined,
              size: 20,
              color: context.colors.textSecondary,
            ),
            const SizedBox(width: AppConstants.paddingM),
            Expanded(
              child: Text(
                suggestion.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
