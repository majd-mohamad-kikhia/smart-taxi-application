import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/saved_addresses/presentation/cubit/saved_addresses_cubit.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_brand_bar_widget.dart';
import '../../data/models/ride_booking_options_model.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../cubit/map_pick_cubit.dart';
import '../cubit/map_pick_state.dart';
import '../widgets/home_bottom_panel_widget.dart';
import '../widgets/home_gps_button_widget.dart';
import '../widgets/home_map_widget.dart';
import '../widgets/home_search_bar_widget.dart';
import '../widgets/map_pick_panel_widget.dart';
import '../widgets/map_pick_top_widget.dart';
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
            ..centerOnUser(),
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
                const Positioned.fill(child: HomeMapWidget()),
                Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                    child: isPicking
                        ? const _HideWhileDragging(child: _PickTop())
                        : const _SearchRow(),
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
                      child: isPicking
                          ? const _HideWhileDragging(child: _PickPanel())
                          : HomeBottomPanelWidget(
                              onPickFrom: () => _enterPick(context, PickTarget.from),
                              onPickTo: () => _enterPick(context, PickTarget.to),
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
    if (quote == null) return;
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
      builder: (_) => VehicleTypeSheetWidget(
        quote: quote,
        pickupLabel: state.fromLocation?.displayLabel ?? '',
        dropoffLabel: state.toLocation?.displayLabel ?? '',
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
/// was picked before. [autofocusSearch] opens the search with the keyboard.
void _enterPick(
  BuildContext context,
  PickTarget target, {
  bool autofocusSearch = false,
}) {
  final home = context.read<HomeCubit>().state;
  context.read<MapPickCubit>().enter(
    target,
    initial: target == PickTarget.from ? home.fromLocation : home.toLocation,
    autofocusSearch: autofocusSearch,
  );
}

/// The search pill and GPS button on top of the map in its normal state.
class _SearchRow extends StatelessWidget {
  const _SearchRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      child: Row(
        children: [
          Expanded(
            child: BlocSelector<HomeCubit, HomeState, bool>(
              selector: (state) => state.arePointsLocked,
              builder: (context, isLocked) => HomeSearchBarWidget(
                onTap: isLocked
                    ? null
                    : () => _enterPick(
                        context,
                        PickTarget.to,
                        autofocusSearch: true,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Back / title / search / GPS while a point is being placed.
class _PickTop extends StatelessWidget {
  const _PickTop();

  @override
  Widget build(BuildContext context) {
    return MapPickTopWidget(onBack: context.read<MapPickCubit>().cancel);
  }
}

/// Address under the pin and the confirm button.
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
        // "Use my location", above the confirm box at its right end. It only
        // moves the map: the pin decides the point, not the GPS.
        Align(
          alignment: Alignment.centerRight,
          child: BlocSelector<HomeCubit, HomeState, bool>(
            selector: (state) => state.isLocating,
            builder: (context, isLocating) => HomeGpsButtonWidget(
              isLoading: isLocating,
              size: 64,
              onTap: () => context.read<HomeCubit>().locateMe(setPickup: false),
            ),
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
