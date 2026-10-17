import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/models/order_offer_model.dart';
import '../../../../core/services/screen_awake_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_snack_bar_widget.dart';
import '../../../../core/widgets/cancel_reason_dialog_widget.dart';
import '../../../../core/widgets/live_trip_map_controller.dart';
import '../../../../core/widgets/live_trip_map_widget.dart';
import '../../../../core/widgets/map_controls_widget.dart';
import '../../../../core/widgets/order_route_details_widget.dart';
import '../../../../core/widgets/ride_waiting_timer_widget.dart';
import '../../../../core/widgets/trip_fees_overlay_widget.dart';
import '../../data/models/driver_active_ride_model.dart';
import '../../data/models/ride_cancellation_model.dart';
import '../cubit/driver_trip_cubit.dart';
import '../cubit/driver_trip_state.dart';
import '../widgets/driver_fare_dialog_widget.dart';
import '../widgets/driver_pickup_map_widget.dart';
import '../widgets/driver_trip_actions_widget.dart';
/// The driver's active-ride screen right after accepting an order: a map
/// centered on the pickup point, plus the trip actions: optional arrived,
/// start ride, finish, and cancel (with a required reason). Back
/// gesture/button is blocked — the driver is committed to this ride until
/// they finish or cancel it (see [PopScope]).
class DriverTripScreen extends StatelessWidget {
  final OrderOfferModel order;

  /// Set when resuming a ride from before the app closed.
  final DriverActiveRideModel? resume;

  const DriverTripScreen({super.key, required this.order, this.resume});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DriverTripCubit>(
      create: (_) => sl<DriverTripCubit>(param1: order, param2: resume)..resumeIfNeeded()
        ..trackToPickup(),
      child: const _DriverTripView(),
    );
  }
}

/// The trip's view. Keeps the screen on for as long as it is open (driving to
/// the pickup, waiting, the ride itself, the fare dialog) and lets the phone
/// sleep again as soon as it closes, whether the trip was finished or
/// cancelled.
class _DriverTripView extends StatefulWidget {
  const _DriverTripView();

  @override
  State<_DriverTripView> createState() => _DriverTripViewState();
}

class _DriverTripViewState extends State<_DriverTripView> {
  late final ScreenAwakeService _screenAwake;

  @override
  void initState() {
    super.initState();
    _screenAwake = sl<ScreenAwakeService>()..keepOn();
  }

  @override
  void dispose() {
    _screenAwake.allowSleep();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: context.colors.backgroundGray,
        body: MultiBlocListener(
          // Each listener reacts to one thing happening once. (They used to
          // be one listener that re-opened the fare dialog whenever an error
          // arrived while the trip was completed, so a failed payment
          // confirmation stacked a second dialog.)
          listeners: [
            BlocListener<DriverTripCubit, DriverTripState>(
              listenWhen: (previous, current) =>
                  !previous.isCancelled && current.isCancelled,
              listener: (context, state) {
                // A cancel from the customer can land while the cancel-reason
                // or another dialog is open: close those, then this screen.
                final navigator = Navigator.of(context);
                final tripRoute = ModalRoute.of(context);
                navigator.popUntil((route) => route == tripRoute || route.isFirst);
                navigator.pop();
                showAppSnackBar(
                  context,
                  switch (state.cancelledBy) {
                    RideCancelledBy.customer => context.l10n.tripCancelledByCustomer,
                    RideCancelledBy.manager => context.l10n.tripCancelledByManager,
                    _ => context.l10n.tripCancelled,
                  },
                  type: AppSnackBarType.error,
                );
              },
            ),
            BlocListener<DriverTripCubit, DriverTripState>(
              listenWhen: (previous, current) =>
                  previous.status != DriverTripStatus.completed &&
                  current.status == DriverTripStatus.completed,
              listener: (context, state) => _showFareAndExit(context),
            ),
            BlocListener<DriverTripCubit, DriverTripState>(
              // Once the trip is completed, errors (a failed payment
              // confirmation) show inside the fare dialog instead.
              listenWhen: (previous, current) =>
                  !current.isCancelled &&
                  current.status != DriverTripStatus.completed &&
                  current.errorMessage != null &&
                  current.errorMessage != previous.errorMessage,
              listener: (context, state) => showAppSnackBar(
                context,
                state.errorMessage!,
                type: AppSnackBarType.error,
              ),
            ),
            BlocListener<DriverTripCubit, DriverTripState>(
              listenWhen: (previous, current) =>
                  current.detailsUpdateCount > previous.detailsUpdateCount,
              listener: (context, state) => showAppSnackBar(
                context,
                context.l10n.tripDetailsUpdated,
                type: AppSnackBarType.warning,
              ),
            ),
          ],
          child: BlocBuilder<DriverTripCubit, DriverTripState>(
            builder: (context, state) {
              if (state.status == DriverTripStatus.inProgress) {
                return _InProgressView(state: state);
              }
              return Stack(
                children: [
                  DriverPickupMapWidget(
                    pickupLat: state.order.pickupLat,
                    pickupLng: state.order.pickupLng,
                    driverLat: state.carLat,
                    driverLng: state.carLng,
                    route: state.pickupRoute,
                  ),
                  _BottomPanel(state: state),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Ride underway: just the live map (car + line to the destination) and
/// the one action left, Finish.
/// Shows the final fare and payment confirmation, then leaves the trip
/// screen once the driver dismisses the dialog. Back is blocked on the
/// dialog too, so the driver has to confirm payment (the only way to
/// reach Done) before leaving.
Future<void> _showFareAndExit(BuildContext context) async {
  final cubit = context.read<DriverTripCubit>();
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: AppColors.scrim,
    builder: (_) => PopScope(
      canPop: false,
      child: BlocProvider<DriverTripCubit>.value(
        value: cubit,
        child: const DriverFareDialogWidget(),
      ),
    ),
  );
  if (context.mounted) Navigator.of(context).pop();
}

class _InProgressView extends StatefulWidget {
  final DriverTripState state;

  const _InProgressView({required this.state});

  @override
  State<_InProgressView> createState() => _InProgressViewState();
}

class _InProgressViewState extends State<_InProgressView> {
  final _mapController = LiveTripMapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return Stack(
      children: [
        LiveTripMapWidget(
          carLat: state.carLat,
          carLng: state.carLng,
          destinationLat: state.order.dropoffLat,
          destinationLng: state.order.dropoffLng,
          routePoints: state.routePoints,
          drivenPath: state.drivenPath,
          controller: _mapController,
        ),
        Align(
          alignment: AlignmentDirectional.topStart,
          child: TripFeesOverlayWidget(
            waitingFee: state.waiting?.fee ?? 0,
            pause: state.pause,
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListenableBuilder(
                    listenable: _mapController,
                    builder: (context, _) => MapControlsWidget(
                      onZoomIn: _mapController.zoomIn,
                      onZoomOut: _mapController.zoomOut,
                      onNudge: _mapController.nudge,
                      onZoomInHold: _mapController.zoomInHeld,
                      onZoomOutHold: _mapController.zoomOutHeld,
                      onNudgeHold: _mapController.nudgeHeld,
                      showArrows: _mapController.view == TripMapView.topDown,
                      view: _mapController.view,
                      onViewChanged: _mapController.setView,
                      onRecenter: _mapController.isFollowing
                          ? null
                          : _mapController.recenter,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: context.colors.backgroundWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.colors.borderLight),
                    ),
                    child: OrderRouteDetailsWidget(
                      order: state.order,
                      showPickup: false,
                    ),
                  ),
                  DriverTripActionsWidget(
                    status: state.status,
                    isUpdating: state.isUpdating,
                    isCancelling: state.isCancelling,
                    isFinishQueued: state.isFinishQueued,
                    isPaused: state.isPaused,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BottomPanel extends StatelessWidget {
  final DriverTripState state;

  const _BottomPanel({required this.state});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.colors.backgroundWhite,
            borderRadius: BorderRadius.circular(AppConstants.radiusXL),
            border: Border.all(color: context.colors.borderLight),
            boxShadow: [
              BoxShadow(
                color: context.colors.shadowMedium,
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OrderRouteDetailsWidget(order: state.order),
              if (state.status == DriverTripStatus.arrived && state.waiting != null) ...[
                const SizedBox(height: 12),
                RideWaitingTimerWidget(waiting: state.waiting!),
              ],
              const SizedBox(height: 16),
              DriverTripActionsWidget(
                status: state.status,
                isUpdating: state.isUpdating,
                isCancelling: state.isCancelling,
                onCancel: () => _showCancelDialog(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCancelDialog(BuildContext context) async {
    final cubit = context.read<DriverTripCubit>();
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const CancelReasonDialogWidget(),
    );
    if (reason != null) cubit.cancelRide(reason);
  }
}
