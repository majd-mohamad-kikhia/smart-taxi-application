import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/place_suggestion_model.dart';
import '../cubit/map_pick_cubit.dart';
import '../cubit/map_pick_state.dart';
import 'home_gps_button_widget.dart';
import 'place_search_field_widget.dart';
import 'place_suggestions_card_widget.dart';

/// Top of the home map while a point is being placed: back, what is being
/// picked, a place search, the GPS button and the search results.
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
    final l10n = context.l10n;
    final cubit = context.read<MapPickCubit>();
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _BackButtonWidget(onTap: widget.onBack),
              const SizedBox(width: AppConstants.paddingM),
              Expanded(
                child: BlocSelector<MapPickCubit, MapPickState, PickTarget?>(
                  selector: (state) => state.target,
                  builder: (context, target) => _TitlePillWidget(
                    title: target == PickTarget.from
                        ? l10n.pickPickupPoint
                        : l10n.pickDestination,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingM),
          BlocBuilder<MapPickCubit, MapPickState>(
            buildWhen: (previous, current) =>
                previous.isSearching != current.isSearching,
            builder: (context, state) => Row(
              children: [
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

class _TitlePillWidget extends StatelessWidget {
  final String title;

  const _TitlePillWidget({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingL,
        vertical: AppConstants.paddingM,
      ),
      decoration: BoxDecoration(
        color: AppColors.neutralSurface,
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
