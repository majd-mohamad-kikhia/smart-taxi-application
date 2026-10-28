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
import '../../../../core/utils/format_price.dart';
import '../../../../core/widgets/app_snack_bar_widget.dart';
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
        BlocProvider<HomeCubit>(
          create: (_) => sl<HomeCubit>()
            ..initialize()
            ..restoreActiveRide()
            ..setDefaultPickup(),
        ),
        BlocProvider<MapPickCubit>(create: (_) => sl<MapPickCubit>()),
        BlocProvider<SavedAddressesCubit>.value(
          value: sl<SavedAddressesCubit>(),
        ),
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
            builder: (context, block) => builder(
              context,
              block.isBlocked && !hasActiveRide ? block : null,
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
          // The final fare is more than 15 % away from the one shown: the
          // customer accepts it before the ride is created.
          BlocListener<HomeCubit, HomeState>(
            listenWhen: (previous, current) =>
                previous.pendingBooking == null &&
                current.pendingBooking != null,
            listener: (context, state) =>
                _confirmFare(
                  context,
                  state.pendingBooking!.fare,
                  state.pendingBooking!.walletUsed,
                ),
          ),
          // The server suggests another place for the search.
          BlocListener<MapPickCubit, MapPickState>(
            listenWhen: (previous, current) =>
                previous.didYouMean == null && current.didYouMean != null,
            listener: (context, state) =>
                _askDidYouMean(context, state.didYouMean!),
          ),
          BlocListener<MapPickCubit, MapPickState>(
            listenWhen: (previous, current) =>
                previous.correctedTo == null && current.correctedTo != null,
            listener: (context, state) => showAppSnackBar(
              context,
              context.l10n.placeCorrectedTo(state.correctedTo!),
            ),
          ),
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
                                color: context.colors.backgroundGray.withValues(
                                  alpha: 0.6,
                                ),
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
                    constraints: const BoxConstraints(
                      maxWidth: _maxContentWidth,
                    ),
                    child: SingleChildScrollView(
                      // Only the panel itself takes touches: the empty space
                      // around it (beside the GPS button) lets the map drag.
                      hitTestBehavior: HitTestBehavior.deferToChild,
                      // Clear of the floating nav bar drawn over the map.
                      padding: EdgeInsets.fromLTRB(
                        AppConstants.paddingL,
                        AppConstants.paddingL,
                        AppConstants.paddingL,
                        AppConstants.paddingL +
                            MediaQuery.paddingOf(context).bottom,
                      ),
                      // While ordering is blocked there are no From / To
                      // controls at all: the blocked panel stands in for them.
                      child: _OrderingBlockSelector(
                        builder: (context, block) => block != null
                            ? AccountBlockedWidget(
                                block: block,
                                message:
                                    context.l10n.accountBlockedCustomerMessage,
                                contactApp: ContactUsApp.customer,
                              )
                            // Fades away while the map is dragged (only a pin
                            // being placed drags it).
                            : const _HideWhileDragging(
                                child: HomeBottomPanelWidget(),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => BlocProvider<QuoteRouteCubit>(
        create: (_) => sl<QuoteRouteCubit>()
          ..load(
            fromLat: pickup.latitude,
            fromLng: pickup.longitude,
            toLat: dropoff.latitude,
            toLng: dropoff.longitude,
            route: quote.route,
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

  Future<void> _confirmFare(
    BuildContext context,
    double fare,
    double walletUsed,
  ) async {
    final l10n = context.l10n;
    final cubit = context.read<HomeCubit>();
    final yes = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.fareReconfirmTitle),
        content: Text(
          [
            l10n.fareReconfirmMessage(formatSyp(l10n, fare)),
            if (walletUsed > 0)
              l10n.walletFromYourWallet(formatSyp(l10n, walletUsed)),
          ].join('\n'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.answerYes),
          ),
        ],
      ),
    );
    if (yes ?? false) {
      await cubit.confirmPendingBooking();
    } else {
      cubit.declinePendingBooking();
    }
  }

  Future<void> _askDidYouMean(
    BuildContext context,
    DidYouMeanPrompt prompt,
  ) async {
    final l10n = context.l10n;
    final cubit = context.read<MapPickCubit>();
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.didYouMeanTitle),
        content: Text(l10n.didYouMeanMessage(prompt.text)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.answerNo),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.answerYes),
          ),
        ],
      ),
    );
    if (yes == null) {
      cubit.dismissDidYouMean();
      return;
    }
    await cubit.answerDidYouMean(yes: yes);
  }

  Future<void> _openTracking(BuildContext context, HomeState state) async {
    final ride = state.activeRide;
    final pickup = state.fromLocation;
    final dropoff = state.toLocation;
    if (ride == null || pickup == null || dropoff == null) return;

    final cubit = context.read<HomeCubit>();
    await Navigator.of(context).pushNamed(
      AppRouter.rideTracking,
      arguments: RideTrackingRouteArgs(
        initialRide: ride,
        pickup: pickup,
        dropoff: dropoff,
        plannedRoute: state.routeLine,
      ),
    );
    cubit.resetAfterRideEnded();
  }
}
