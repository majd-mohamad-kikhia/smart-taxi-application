import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/place_suggestion_model.dart';
import '../cubit/map_pick_cubit.dart';
import '../cubit/map_pick_state.dart';
import 'home_gps_button_widget.dart';
import 'place_search_field_widget.dart';
import 'place_suggestions_card_widget.dart';

/// Top of the home map while a point is being placed: back, a place search,
/// the GPS button and the search results.
class MapPickTopWidget extends StatefulWidget {
  final bool isLocating;
  final VoidCallback onBack;
  final VoidCallback onLocate;

  const MapPickTopWidget({
    super.key,
    required this.isLocating,
    required this.onBack,
    required this.onLocate,
  });

  @override
  State<MapPickTopWidget> createState() => _MapPickTopWidgetState();
}

class _MapPickTopWidgetState extends State<MapPickTopWidget> {
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

  void _select(PlaceSuggestionModel suggestion) {
    FocusScope.of(context).unfocus();
    _searchController.text = suggestion.description;
    context.read<MapPickCubit>().selectSuggestion(suggestion);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MapPickCubit>();
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BlocBuilder<MapPickCubit, MapPickState>(
            buildWhen: (previous, current) =>
                previous.isSearching != current.isSearching,
            builder: (context, state) => Row(
              children: [
                _BackButtonWidget(onTap: widget.onBack),
                const SizedBox(width: AppConstants.paddingM),
                Expanded(
                  child: PlaceSearchFieldWidget(
                    controller: _searchController,
                    isSearching: state.isSearching,
                    autofocus: state.autofocusSearch,
                    onChanged: cubit.search,
                    onClear: _clear,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingM),
                HomeGpsButtonWidget(
                  isLoading: widget.isLocating,
                  onTap: widget.onLocate,
                ),
              ],
            ),
          ),
          BlocBuilder<MapPickCubit, MapPickState>(
            buildWhen: (previous, current) =>
                previous.suggestions != current.suggestions ||
                previous.searchError != current.searchError,
            builder: (context, state) {
              if (state.suggestions.isEmpty && state.searchError == null) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: AppConstants.paddingS),
                child: PlaceSuggestionsCardWidget(
                  suggestions: state.suggestions,
                  errorMessage: state.searchError,
                  onSuggestionTap: _select,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BackButtonWidget extends StatelessWidget {
  final VoidCallback onTap;

  const _BackButtonWidget({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: MaterialLocalizations.of(context).backButtonTooltip,
      child: Material(
        color: AppColors.neutralSurface,
        shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: const SizedBox(
            width: 48,
            height: 48,
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
