import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/account_block/account_block_cubit.dart';
import '../../../../core/account_block/account_block_state.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/contact_us/data/models/contact_number_model.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/models/account_block_model.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/saved_addresses/presentation/cubit/saved_addresses_cubit.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/account_blocked_widget.dart';
import '../../../../core/widgets/app_brand_bar_widget.dart';
import '../../data/models/ride_booking_options_model.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../cubit/map_pick_cubit.dart';
import '../cubit/map_pick_state.dart';
import '../cubit/quote_route_cubit.dart';
import '../widgets/home_bottom_panel_widget.dart';
import '../widgets/home_map_widget.dart';
import '../widgets/map_pick_panel_widget.dart';
import '../widgets/map_pick_search_widget.dart';
import '../widgets/trip_too_long_dialog_widget.dart';
import '../widgets/vehicle_type_sheet_widget.dart';

/// Widest the floating controls grow on tablets and desktop windows.
const double _maxContentWidth = 560;

/// Entry point for the "create request" feature.
/// Provides the [HomeCubit] and [MapPickCubit] and renders [_HomeView].
class HomeScreen extends StatelessWidget {
  /// Bumped by the tab shell each time the "create order" tab is tapped: the
  /// From and To points are cleared.
  final ValueListenable<int>? resetSignal;

  const HomeScreen({super.key, this.resetSignal});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<HomeCubit>(create: (_) => sl<HomeCubit>()
            ..initialize()
            ..restoreActiveRide()
            ..setDefaultPickup(),
        ),
        BlocProvider<MapPickCubit>(create: (_) => sl<MapPickCubit>()),
        BlocProvider<SavedAddressesCubit>.value(value: sl<SavedAddressesCubit>()),
      ],
      child: _ResetOnSignal(signal: resetSignal, child: const _HomeView()),
    );
  }
}

/// While the map is being dragged the controls fade away (and stop taking
/// touches), so the customer sees only the map and the pin; they fade back
/// when it settles. The widgets stay mounted, so a typed search is kept.
class _HideWhileDragging extends StatelessWidget {
  final Widget child;

  const _HideWhileDragging({required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<MapPickCubit, MapPickState, bool>(
      selector: (state) => state.isDragging,
      builder: (context, dragging) => IgnorePointer(
        ignoring: dragging,
        child: AnimatedOpacity(
          opacity: dragging ? 0 : 1,
          duration: const Duration(milliseconds: 150),
          child: child,
        ),
      ),
    );
  }
}

/// Hands [builder] the account's block while it stops the customer ordering,
/// and null otherwise. A ride already in progress is unaffected by a block,
/// so with one the block is not passed on. Rebuilds only when that changes.
class _OrderingBlockSelector extends StatelessWidget {
  final Widget Function(BuildContext context, AccountBlockModel? block) builder;

  const _OrderingBlockSelector({required this.builder});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<HomeCubit, HomeState, bool>(
      selector: (state) => state.hasActiveRide,
      builder: (context, hasActiveRide) =>
          BlocSelector<AccountBlockCubit, AccountBlockState, AccountBlockModel>(
            bloc: sl<AccountBlockCubit>(),
            selector: (state) => state.block,
            builder: (context, block) =>
                builder(context, block.isBlocked && !hasActiveRide ? block : null),
          ),
    );
  }
}

/// Clears the From and To points when [signal] changes, and leaves any pin
/// mode first.
class _ResetOnSignal extends StatefulWidget {
  final ValueListenable<int>? signal;
  final Widget child;

  const _ResetOnSignal({required this.signal, required this.child});

  @override
  State<_ResetOnSignal> createState() => _ResetOnSignalState();
}

class _ResetOnSignalState extends State<_ResetOnSignal> {
  @override
  void initState() {
    super.initState();
    widget.signal?.addListener(_reset);
  }

  @override
  void dispose() {
    widget.signal?.removeListener(_reset);
    super.dispose();
  }

  void _reset() {
    context.read<MapPickCubit>().cancel();
    context.read<HomeCubit>().resetPoints();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// The map fills the body. Over it, either the search row and the From / To
/// panel, or — while a point is being placed — the pin controls. Nothing here
/// opens another screen.
class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.backgroundGray,
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: AppBrandBarWidget(showNotifications: true),
      ),
      body: MultiBlocListener(
        listeners: [
          // A fresh quote is the signal to let the customer pick a vehicle.
          BlocListener<HomeCubit, HomeState>(
            listenWhen: (previous, current) =>
                previous.quote != current.quote && current.quote != null,
            listener: (context, state) => _openVehicleSheet(context, state),
          ),
          // The ride was just created — hand off to the live tracking
          // screen, which owns everything from here (accept, GPS, status,
          // cancel) until the ride ends.
          BlocListener<HomeCubit, HomeState>(
            listenWhen: (previous, current) =>
                previous.activeRide == null && current.activeRide != null,
            listener: (context, state) => _openTracking(context, state),
          ),
          // A ride restored while a point is being placed locks the points.
          BlocListener<HomeCubit, HomeState>(
            listenWhen: (previous, current) =>
                !previous.arePointsLocked && current.arePointsLocked,
            listener: (context, state) => context.read<MapPickCubit>().cancel(),
          ),
          // A block that lands while a point is being placed ends the pick.
          BlocListener<AccountBlockCubit, AccountBlockState>(
            bloc: sl<AccountBlockCubit>(),
            listenWhen: (previous, current) =>
                !previous.isBlocked && current.isBlocked,
            listener: (context, state) => context.read<MapPickCubit>().cancel(),
          ),
        ],
        child: BlocSelector<MapPickCubit, MapPickState, bool>(
          selector: (state) => state.isPicking,
          builder: (context, isPicking) => PopScope(
            // Back leaves the pin mode first instead of leaving the tab.
            canPop: !isPicking,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) context.read<MapPickCubit>().cancel();
            },
            child: Stack(
              children: [
                Positioned.fill(
                  child: _OrderingBlockSelector(
                    builder: (context, block) => IgnorePointer(
                      ignoring: block != null,
                      child: Stack(
                        children: [
                          const Positioned.fill(child: HomeMapWidget()),
                          if (block != null)
                            Positioned.fill(
                              child: ColoredBox(
                                color: context.colors.backgroundGray.withValues(alpha: 0.6),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                    child: SingleChildScrollView(
                      // Only the panel itself takes touches: the empty space
                      // around it (beside the GPS button) lets the map drag.
                      hitTestBehavior: HitTestBehavior.deferToChild,
                      // Clear of the floating nav bar drawn over the map.
                      padding: EdgeInsets.fromLTRB(
                        AppConstants.paddingL,
                        AppConstants.paddingL,
                        AppConstants.paddingL,
                        AppConstants.paddingL + MediaQuery.paddingOf(context).bottom,
                      ),
                      // While ordering is blocked there are no From / To
                      // controls at all: the blocked panel stands in for them.
                      child: _OrderingBlockSelector(
                        builder: (context, block) => block != null
                            ? AccountBlockedWidget(
                                block: block,
                                message: context.l10n.accountBlockedCustomerMessage,
                                contactApp: ContactUsApp.customer,
                              )
                            : isPicking
                            ? const _HideWhileDragging(child: _PickPanel())
                            : HomeBottomPanelWidget(
                                onPickFrom: () => _enterPick(context, PickTarget.from),
                                onPickTo: () => _enterPick(context, PickTarget.to),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openVehicleSheet(BuildContext context, HomeState state) async {
    final quote = state.quote;
    final pickup = state.fromLocation;
    final dropoff = state.toLocation;
    if (quote == null || pickup == null || dropoff == null) return;
    // Too far to order from the app: show who to contact instead of prices.
    if (quote.distanceKm > AppConstants.maxOrderDistanceKm) {
      await showTripTooLongDialog(context);
      return;
    }
    final cubit = context.read<HomeCubit>();
    final options = await showModalBottomSheet<RideBookingOptionsModel>(
      context: context,
      backgroundColor: context.colors.neutralSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (_) => BlocProvider<QuoteRouteCubit>(
        create: (_) => sl<QuoteRouteCubit>()
          ..load(
            fromLat: pickup.latitude,
            fromLng: pickup.longitude,
            toLat: dropoff.latitude,
            toLng: dropoff.longitude,
          ),
        child: VehicleTypeSheetWidget(
          quote: quote,
          pickup: pickup,
          dropoff: dropoff,
        ),
      ),
    );
    if (options != null) await cubit.chooseVehicle(options);
  }

  Future<void> _openTracking(BuildContext context, HomeState state) async {
    final ride = state.activeRide;
    final pickup = state.fromLocation;
    final dropoff = state.toLocation;
    if (ride == null || pickup == null || dropoff == null) return;

    final cubit = context.read<HomeCubit>();
    await Navigator.of(context).pushNamed(
      AppRouter.rideTracking,
      arguments: RideTrackingRouteArgs(initialRide: ride, pickup: pickup, dropoff: dropoff),
    );
    cubit.resetAfterRideEnded();
  }
}

/// Starts placing [target] on the home map, from where it already is if it
/// was picked before.
void _enterPick(BuildContext context, PickTarget target) {
  final home = context.read<HomeCubit>().state;
  context.read<MapPickCubit>().enter(
    target,
    initial: target == PickTarget.from ? home.fromLocation : home.toLocation,
  );
}

/// Place search with the GPS button, the address under the pin and the
/// confirm button.
class _PickPanel extends StatelessWidget {
  const _PickPanel();

  @override
  Widget build(BuildContext context) {
    final home = context.read<HomeCubit>().state;
    final target = context.read<MapPickCubit>().state.target;
    final current = target == PickTarget.from ? home.fromLocation : home.toLocation;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The GPS button only moves the map: the pin decides the point, not
        // the GPS.
        BlocSelector<HomeCubit, HomeState, bool>(
          selector: (state) => state.isLocating,
          builder: (context, isLocating) => MapPickSearchWidget(
            isLocating: isLocating,
            onLocate: () => context.read<HomeCubit>().locateMe(setPickup: false),
          ),
        ),
        const SizedBox(height: AppConstants.paddingS),
        BlocSelector<HomeCubit, HomeState, String?>(
          selector: (state) => state.errorMessage,
          builder: (context, error) => MapPickPanelWidget(
            initialDetails: current?.addressDetails,
            errorMessage: error,
            onConfirm: (details) => _confirm(context, details),
          ),
        ),
      ],
    );
  }

  void _confirm(BuildContext context, String details) {
    FocusScope.of(context).unfocus();
    final pick = context.read<MapPickCubit>();
    final home = context.read<HomeCubit>();
    final target = pick.state.target;
    final picked = pick.confirm(details: details);
    if (picked == null || target == null) return;
    if (target == PickTarget.from) {
      home.setFromLocation(picked);
    } else {
      home.setToLocation(picked);
    }
  }
}
