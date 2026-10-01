import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/models/picked_location_model.dart';
import '../../../../core/models/ride_fare_breakdown_model.dart';
import '../../../../core/models/ride_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_destructive_button_widget.dart';
import '../../../../core/widgets/app_snack_bar_widget.dart';
import '../../../../core/widgets/cancel_reason_dialog_widget.dart';
import '../../../../core/widgets/live_trip_map_widget.dart';
import '../../../../core/widgets/ride_waiting_timer_widget.dart';
import '../../../../core/widgets/trip_fees_overlay_widget.dart';
import '../cubit/ride_tracking_cubit.dart';
import '../cubit/ride_tracking_state.dart';
import '../widgets/ride_driver_card_widget.dart';
import '../widgets/ride_payment_due_dialog_widget.dart';
import '../widgets/ride_status_banner_widget.dart';
import '../widgets/ride_tracking_map_widget.dart';
import '../widgets/ride_trip_summary_widget.dart';
import '../widgets/safety_banner_widget.dart';

/// Full-screen ride tracking — from "waiting for a driver" right after
/// `choose-vehicle` through pickup/in-progress/completion, fed entirely by
/// `RideTrackingCubit`'s socket connection (see docs/socket.md).
///
/// Once the driver starts the ride the screen shows only the live map
/// (moving car + road route to the destination) — no sheet, no cancel.
/// When the driver finishes, a "pay the driver" dialog covers the map until
/// the driver confirms the payment, which closes the screen.
///
/// Before that, the only way out is the cancel button at the bottom (which
/// requires a written reason) or the ride ending naturally
/// (completed/cancelled by the server) — the back gesture/button is
/// blocked (see [PopScope]).
class RideTrackingScreen extends StatelessWidget {
  final RideModel initialRide;
  final PickedLocationModel pickup;
  final PickedLocationModel dropoff;

  const RideTrackingScreen({
    super.key,
    required this.initialRide,
    required this.pickup,
    required this.dropoff,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RideTrackingCubit>(
      create: (_) => sl<RideTrackingCubit>(
        param1: (initialRide: initialRide, pickup: pickup, dropoff: dropoff),
      )..connect(),
      child: const _RideTrackingView(),
    );
  }
}

/// Blocking "pay the driver" dialog — no buttons and no back; the exit
/// listener closes it once the driver confirms the payment.
void _showPaymentDue(BuildContext context, double amount, RideFareBreakdownModel? fare) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: RidePaymentDueDialogWidget(amount: amount, fare: fare),
    ),
  );
}

class _RideTrackingView extends StatelessWidget {
  const _RideTrackingView();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.backgroundWhite,
        body: BlocConsumer<RideTrackingCubit, RideTrackingState>(
          listenWhen: (previous, current) =>
              (previous.exitReason != current.exitReason && current.exitReason != null) ||
              (!previous.isAwaitingPayment && current.isAwaitingPayment) ||
              (previous.cancelError != current.cancelError && current.cancelError != null),
          listener: (context, state) {
            if (state.cancelError != null && state.exitReason == null && !state.isAwaitingPayment) {
              showAppSnackBar(context, state.cancelError!, type: AppSnackBarType.error);
              return;
            }
            if (state.exitReason == null) {
              _showPaymentDue(context, state.finalPrice ?? state.ride.price ?? 0, state.fare);
              return;
            }
            final isSuccess = state.exitReason == RideTrackingExitReason.completed;
            final navigator = Navigator.of(context);
            // The payment dialog sits above this screen; close it first so
            // the pop below leaves the screen itself.
            if (ModalRoute.of(context)?.isCurrent == false) navigator.pop();
            navigator.pop();
            showAppSnackBar(
              context,
              isSuccess
                  ? context.l10n.tripCompletedSuccess
                  : context.l10n.tripCancelled,
              type: isSuccess ? AppSnackBarType.success : AppSnackBarType.error,
            );
          },
          builder: (context, state) {
            if (state.showsLiveMap) {
              return Stack(
                children: [
                  LiveTripMapWidget(
                    carLat: state.driverLocation?.lat,
                    carLng: state.driverLocation?.lng,
                    destinationLat: state.dropoff.latitude,
                    destinationLng: state.dropoff.longitude,
                    routePoints: state.routePoints,
                    drivenPath: state.drivenPath,
                  ),
                  Align(
                    alignment: AlignmentDirectional.topStart,
                    child: TripFeesOverlayWidget(
                      waitingFee: state.ride.waitingFee,
                      pause: state.ride.pause,
                    ),
                  ),
                ],
              );
            }
            return Column(
              children: [
                Expanded(
                  flex: 46,
                  child: Stack(
                    children: [
                      RideTrackingMapWidget(
                        pickup: state.pickup,
                        dropoff: state.dropoff,
                        driverLocation: state.driverLocation,
                      ),
                      const _ScreenHeader(),
                    ],
                  ),
                ),
                Expanded(flex: 54, child: _TrackingSheet(state: state)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ScreenHeader extends StatelessWidget {
  const _ScreenHeader();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: AppColors.shadowLight, blurRadius: 6, offset: Offset(0, 2))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.directions_car_rounded, color: AppColors.primary, size: 16),
                const SizedBox(width: 4),
                Text(
                  context.l10n.trackTrip,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrackingSheet extends StatelessWidget {
  final RideTrackingState state;

  const _TrackingSheet({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: AppColors.shadowMedium, blurRadius: 16, offset: Offset(0, -4))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Column(
                children: [
                  RideStatusBannerWidget(ride: state.ride, connectionStatus: state.connectionStatus),
                  const SizedBox(height: 14),
                  if (state.ride.isWaitingRunning) ...[
                    RideWaitingTimerWidget(waiting: state.ride.waiting!),
                    const SizedBox(height: 14),
                  ],
                  if (state.isAccepted) ...[
                    RideDriverCardWidget(driver: state.driver!, vehicle: state.vehicle!),
                    const SizedBox(height: 14),
                  ],
                  RideTripSummaryWidget(pickup: state.pickup, dropoff: state.dropoff, ride: state.ride),
                  const SizedBox(height: 12),
                  const SafetyBannerWidget(isTrackingEnabled: true, isSharingEnabled: true),
                  const SizedBox(height: 14),
                  AppDestructiveButtonWidget(
                    label: context.l10n.cancelTrip,
                    isLoading: state.isCancelling,
                    onPressed: () => _showCancelDialog(context),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCancelDialog(BuildContext context) async {
    final cubit = context.read<RideTrackingCubit>();
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const CancelReasonDialogWidget(),
    );
    if (reason != null) cubit.submitCancellation(reason);
  }
}
