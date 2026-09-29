import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/models/order_offer_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/cancel_reason_dialog_widget.dart';
import '../../../../core/widgets/live_trip_map_widget.dart';
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

  const DriverTripScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DriverTripCubit>(
      create: (_) => sl<DriverTripCubit>(param1: order),
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
        body: BlocConsumer<DriverTripCubit, DriverTripState>(
          listenWhen: (previous, current) =>
              (!previous.isCancelled && current.isCancelled) ||
              (previous.status != DriverTripStatus.completed &&
                  current.status == DriverTripStatus.completed) ||
              (current.errorMessage != null &&
                  current.errorMessage != previous.errorMessage),
          listener: (context, state) {
            if (state.isCancelled) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.l10n.tripCancelled),
                  backgroundColor: AppColors.error,
                ),
              );
            } else if (state.status == DriverTripStatus.completed) {
              _showFareAndExit(context);
            } else if (state.errorMessage != null) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
            }
          },
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
                _ScreenHeader(status: state.status),
                _BottomPanel(state: state),
              ],
            );
          },
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
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: DriverTripActionsWidget(
                status: state.status,
                isUpdating: state.isUpdating,
                isCancelling: state.isCancelling,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScreenHeader extends StatelessWidget {
  final DriverTripStatus status;

  const _ScreenHeader({required this.status});

  String _label(BuildContext context) {
    return status == DriverTripStatus.accepted
        ? context.l10n.driverGoToPickup
        : context.l10n.driverArrivalReported;
  }

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
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.local_taxi_rounded,
                  color: AppColors.primary,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  _label(context),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
              Row(
                children: [
                  const Icon(
                    Icons.radio_button_checked_rounded,
                    color: AppColors.success,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.order.pickupAddress,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
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
