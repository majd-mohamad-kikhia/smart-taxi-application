import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/format_distance.dart';
import '../../data/models/place_suggestion_model.dart';

/// The list of places found by a search (nearest first), or the search's
/// error message in its place.
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
    return Container(
      constraints: const BoxConstraints(maxHeight: 260),
      decoration: BoxDecoration(
        color: context.colors.neutralSurface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        border: Border.all(color: context.colors.border),
      ),
      child: errorMessage != null
          ? Padding(
              padding: const EdgeInsets.all(AppConstants.paddingL),
              child: Text(
                errorMessage!,
                style: TextStyle(color: context.colors.errorText, fontSize: 13),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(
                vertical: AppConstants.paddingS,
              ),
              itemCount: suggestions.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, color: context.colors.borderLight),
              itemBuilder: (context, index) {
                final suggestion = suggestions[index];
                return ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.place_outlined,
                    color: context.colors.textSecondary,
                    size: 20,
                  ),
                  title: Text(
                    suggestion.description,
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontSize: 13.5,
                    ),
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
                  onTap: () => onSuggestionTap(suggestion),
                );
              },
            ),
    );
  }
}
