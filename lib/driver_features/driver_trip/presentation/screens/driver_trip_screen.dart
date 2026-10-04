import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/models/order_offer_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snack_bar_widget.dart';
import '../../../../core/widgets/cancel_reason_dialog_widget.dart';
import '../../../../core/widgets/live_trip_map_widget.dart';
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
      create: (_) => sl<DriverTripCubit>(param1: order, param2: resume)..resumeIfNeeded(),
      child: const _DriverTripView(),
    );
  }
}

class _DriverTripView extends StatelessWidget {
  const _DriverTripView();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.backgroundGray,
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

class _InProgressView extends StatelessWidget {
  final DriverTripState state;

  const _InProgressView({required this.state});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        LiveTripMapWidget(
          carLat: state.carLat,
          carLng: state.carLng,
          destinationLat: state.order.dropoffLat,
          destinationLng: state.order.dropoffLng,
          routePoints: state.routePoints,
          drivenPath: state.drivenPath,
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
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
            color: AppColors.backgroundWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowMedium,
                blurRadius: 16,
                offset: Offset(0, -2),
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
