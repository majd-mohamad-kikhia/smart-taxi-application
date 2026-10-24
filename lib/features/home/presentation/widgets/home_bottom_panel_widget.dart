import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/geo/geo_models.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/models/ride_model.dart';
import '../../../../core/widgets/app_destructive_button_widget.dart';
import '../../../../core/widgets/auth_error_banner_widget.dart';
import '../../../../core/widgets/auth_primary_button_widget.dart';
import '../../../../core/widgets/cancel_reason_dialog_widget.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../cubit/map_pick_cubit.dart';
import '../cubit/map_pick_state.dart';
import 'active_ride_card_widget.dart';
import 'home_gps_button_widget.dart';
import 'map_pick_actions_widget.dart';
import 'place_search_message_widget.dart';
import 'place_suggestions_list_widget.dart';
import 'route_points_card_widget.dart';

/// Everything pinned to the bottom of the home map. The From / To card is
/// always there — its two fields are also where a place is searched for —
/// and around it the panel is either in its normal state (the ride, the
/// Search or Cancel button) or placing a point (the places found above the
/// card, the saved places and Confirm below it).
///
/// The card stays mounted when the mode changes, so a field that was tapped
/// keeps its focus and its keyboard through the switch.
class HomeBottomPanelWidget extends StatelessWidget {
  const HomeBottomPanelWidget({super.key});

  static const _cardKey = ValueKey('route-points-card');

  /// Starts placing [target], from where it already is if it was picked
  /// before. [search] opens its field for typing.
  static void _activate(
    BuildContext context,
    PickTarget target, {
    required bool search,
  }) {
    final home = context.read<HomeCubit>().state;
    context.read<MapPickCubit>().enter(
      target,
      initial: target == PickTarget.from ? home.fromLocation : home.toLocation,
      autofocusSearch: search,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<MapPickCubit, MapPickState, bool>(
      selector: (state) => state.isPicking,
      builder: (context, isPicking) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _ErrorBanner(),
          if (isPicking) const _FoundPlaces() else const _ActiveRide(),
          const _GpsButton(),
          const SizedBox(height: AppConstants.paddingS),
          RoutePointsCardWidget(
            key: _cardKey,
            onActivate: (target, {required search}) =>
                _activate(context, target, search: search),
          ),
          const SizedBox(height: AppConstants.paddingM),
          if (isPicking) const _PickActions() else const _OrderActions(),
        ],
      ),
    );
  }
}

/// The message of a failed order step or of the GPS button.
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<HomeCubit, HomeState, String?>(
      selector: (state) => state.errorMessage,
      builder: (context, message) => message == null
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(bottom: AppConstants.paddingM),
              child: AuthErrorBannerWidget(message: message),
            ),
    );
  }
}

/// The ride that is live, above the card.
class _ActiveRide extends StatelessWidget {
  const _ActiveRide();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<HomeCubit, HomeState, RideModel?>(
      selector: (state) => state.activeRide,
      builder: (context, ride) => ride == null
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(bottom: AppConstants.paddingM),
              child: ActiveRideCardWidget(ride: ride),
            ),
    );
  }
}

/// What the search shows above the card: the places matching what is typed,
/// or its message (nothing found, type more…).
class _FoundPlaces extends StatelessWidget {
  const _FoundPlaces();

  @override
  Widget build(BuildContext context) {
    final pick = context.read<MapPickCubit>();
    return BlocSelector<
      MapPickCubit,
      MapPickState,
      ({String? message, List<GeoSuggestionModel> suggestions})
    >(
      selector: (state) =>
          (message: state.searchError, suggestions: state.suggestions),
      builder: (context, view) {
        final message = view.message;
        if (message == null && view.suggestions.isEmpty) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: AppConstants.paddingS),
          child: message != null
              ? PlaceSearchMessageWidget(message: message)
              : PlaceSuggestionsListWidget(
                  suggestions: view.suggestions,
                  onSelected: (suggestion) {
                    FocusManager.instance.primaryFocus?.unfocus();
                    pick.selectSuggestion(suggestion);
                  },
                ),
        );
      },
    );
  }
}

/// "Use my location", above the card at its right end. While a point is being
/// placed it only moves the map: the pin decides the point, not the GPS.
class _GpsButton extends StatelessWidget {
  const _GpsButton();

  @override
  Widget build(BuildContext context) {
    final isPicking = context.select<MapPickCubit, bool>(
      (cubit) => cubit.state.isPicking,
    );
    final isLocked = context.select<HomeCubit, bool>(
      (cubit) => cubit.state.arePointsLocked,
    );
    final isLocating = context.select<HomeCubit, bool>(
      (cubit) => cubit.state.isLocating,
    );
    final home = context.read<HomeCubit>();
    return Align(
      alignment: Alignment.centerRight,
      child: HomeGpsButtonWidget(
        isLoading: isLocating,
        onTap: isLocked && !isPicking
            ? null
            : () => home.locateMe(setPickup: !isPicking),
        size: 64,
      ),
    );
  }
}

/// The saved places and Confirm under the card while a point is placed.
class _PickActions extends StatelessWidget {
  const _PickActions();

  @override
  Widget build(BuildContext context) {
    final home = context.read<HomeCubit>().state;
    final target = context.read<MapPickCubit>().state.target;
    final current = target == PickTarget.from
        ? home.fromLocation
        : home.toLocation;
    return MapPickActionsWidget(
      initialDetails: current?.addressDetails,
      onConfirm: (details) => _confirm(context, details),
    );
  }

  Future<void> _confirm(BuildContext context, String details) async {
    FocusScope.of(context).unfocus();
    final pick = context.read<MapPickCubit>();
    final home = context.read<HomeCubit>();
    final target = pick.state.target;
    // A pin whose naming was put off is named here, so this may take a moment.
    final picked = await pick.confirm(details: details);
    if (picked == null || target == null) return;
    if (target == PickTarget.from) {
      home.setFromLocation(picked);
    } else {
      home.setToLocation(picked);
    }
  }
}

/// The Search button (or Cancel request, once a ride is live) under the card.
/// While ordering is blocked the home screen shows the blocked panel instead
/// of this whole panel.
class _OrderActions extends StatelessWidget {
  const _OrderActions();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<HomeCubit>();
    return BlocSelector<
      HomeCubit,
      HomeState,
      ({bool hasRide, bool isCancelling, bool isBusy, bool canSearch})
    >(
      selector: (state) => (
        hasRide: state.hasActiveRide,
        isCancelling: state.isCancelling,
        isBusy: state.isSearching || state.isBooking,
        canSearch: state.canSearch,
      ),
      builder: (context, state) => state.hasRide
          ? AppDestructiveButtonWidget(
              label: l10n.cancelRequest,
              isLoading: state.isCancelling,
              onPressed: () => _confirmCancel(context),
            )
          : AuthPrimaryButtonWidget(
              label: l10n.search,
              isLoading: state.isBusy,
              onPressed: state.canSearch ? cubit.searchRide : null,
            ),
    );
  }

  /// Asks for a reason first, like the tracking screen, so a request can't
  /// be cancelled by one stray tap.
  Future<void> _confirmCancel(BuildContext context) async {
    final cubit = context.read<HomeCubit>();
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => CancelReasonDialogWidget(
        title: context.l10n.cancelRequest,
        showCancelLimit: false,
      ),
    );
    if (reason != null) cubit.cancelRide(reason: reason);
  }
}
