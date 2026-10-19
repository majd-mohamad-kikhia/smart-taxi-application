import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/models/place_suggestion_model.dart';
import '../cubit/map_pick_cubit.dart';
import '../cubit/map_pick_state.dart';
import 'home_gps_button_widget.dart';
import 'place_search_field_widget.dart';
import 'place_suggestions_card_widget.dart';

/// The place search while a point is being placed: the search field beside the
/// GPS button, with the results opening upward above them.
class MapPickSearchWidget extends StatefulWidget {
  final bool isLocating;
  final VoidCallback onLocate;

  const MapPickSearchWidget({
    super.key,
    required this.isLocating,
    required this.onLocate,
  });

  @override
  State<MapPickSearchWidget> createState() => _MapPickSearchWidgetState();
}

class _MapPickSearchWidgetState extends State<MapPickSearchWidget> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clear() {
    _searchController.clear();
    context.read<MapPickCubit>().clearSearch();
  }

  /// Tapping the empty box lists the places picked before.
  void _onFieldTap() {
    if (_searchController.text.trim().isEmpty) {
      context.read<MapPickCubit>().search('');
    }
  }

  void _select(PlaceSuggestionModel suggestion) {
    FocusScope.of(context).unfocus();
    _searchController.text = suggestion.description;
    context.read<MapPickCubit>().selectSuggestion(suggestion);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MapPickCubit>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BlocBuilder<MapPickCubit, MapPickState>(
          buildWhen: (previous, current) =>
              previous.suggestions != current.suggestions ||
              previous.searchError != current.searchError,
          builder: (context, state) {
            if (state.suggestions.isEmpty && state.searchError == null) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: AppConstants.paddingS),
              child: PlaceSuggestionsCardWidget(
                suggestions: state.suggestions,
                errorMessage: state.searchError,
                onSuggestionTap: _select,
              ),
            );
          },
        ),
        // Always left-to-right, so the GPS button stays at the physical right
        // in Arabic too; the field's own text direction is unaffected.
        Row(
          textDirection: TextDirection.ltr,
          children: [
            Expanded(
              child: BlocSelector<MapPickCubit, MapPickState, bool>(
                selector: (state) => state.isSearching,
                builder: (context, isSearching) => PlaceSearchFieldWidget(
                  controller: _searchController,
                  isSearching: isSearching,
                  onChanged: cubit.search,
                  onTap: _onFieldTap,
                  onClear: _clear,
                ),
              ),
            ),
            const SizedBox(width: AppConstants.paddingM),
            HomeGpsButtonWidget(
              isLoading: widget.isLocating,
              onTap: widget.onLocate,
            ),
          ],
        ),
      ],
    );
  }
}
