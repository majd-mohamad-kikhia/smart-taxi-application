import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_palette.dart';
import '../../data/models/place_suggestion_model.dart';
import 'place_suggestion_tile_widget.dart';

/// The list of places found by a search (the customer's recent picks first,
/// then the rest nearest first), with the search's error message under it —
/// or alone when nothing was found.
class PlaceSuggestionsCardWidget extends StatelessWidget {
  final List<PlaceSuggestionModel> suggestions;
  final String? errorMessage;
  final ValueChanged<PlaceSuggestionModel> onSuggestionTap;

  const PlaceSuggestionsCardWidget({
    super.key,
    required this.suggestions,
    required this.errorMessage,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    final error = errorMessage;
    return Container(
      constraints: const BoxConstraints(maxHeight: 260),
      decoration: BoxDecoration(
        color: context.colors.neutralSurface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (suggestions.isNotEmpty)
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(
                  vertical: AppConstants.paddingS,
                ),
                itemCount: suggestions.length,
                separatorBuilder: (_, _) =>
                    Divider(height: 1, color: context.colors.borderLight),
                itemBuilder: (context, index) => PlaceSuggestionTileWidget(
                  suggestion: suggestions[index],
                  onTap: () => onSuggestionTap(suggestions[index]),
                ),
              ),
            ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingL),
              child: Text(
                error,
                style: TextStyle(color: context.colors.errorText, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}
