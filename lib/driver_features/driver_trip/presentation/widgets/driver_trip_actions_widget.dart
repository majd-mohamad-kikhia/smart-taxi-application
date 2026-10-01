import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/driver_trip_cubit.dart';
import '../cubit/driver_trip_state.dart';

/// Action buttons for the active ride, driven by [DriverTripStatus]:
/// an optional "I've arrived" (accepted only), then Cancel + the primary
/// step — Start ride (accepted / arrived). Once the ride is in progress
/// only Finish trip remains; cancel is no longer offered.
class DriverTripActionsWidget extends StatelessWidget {
  final DriverTripStatus status;
  final bool isUpdating;
  final bool isCancelling;

  /// The in-progress trip is currently paused — the button becomes Resume.
  final bool isPaused;
  final VoidCallback? onCancel;

  const DriverTripActionsWidget({
    super.key,
    required this.status,
    required this.isUpdating,
    required this.isCancelling,
    this.isPaused = false,
    this.onCancel,
  });

  bool get _isBusy => isUpdating || isCancelling;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DriverTripCubit>();
    final isInProgress = status == DriverTripStatus.inProgress;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (status == DriverTripStatus.accepted) ...[
          OutlinedButton.icon(
            onPressed: _isBusy ? null : cubit.markArrived,
            icon: const Icon(Icons.place_rounded, size: 18),
            label: Text(context.l10n.driverReportArrival),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (isInProgress) ...[
          OutlinedButton.icon(
            onPressed: _isBusy ? null : (isPaused ? cubit.resumeTrip : cubit.pauseTrip),
            icon: Icon(
              isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              size: 18,
            ),
            label: Text(
              isPaused ? context.l10n.driverResumeTrip : context.l10n.driverPauseTrip,
            ),
            // Sits on the live map, so it needs a solid fill — an outlined
            // button is transparent there and the map shows through.
            style: OutlinedButton.styleFrom(
              backgroundColor: isPaused
                  ? AppColors.primarySurface
                  : AppColors.backgroundWhite,
              disabledBackgroundColor: AppColors.backgroundWhite,
              foregroundColor: isPaused ? AppColors.primary : AppColors.textPrimary,
              side: BorderSide(
                color: isPaused ? AppColors.primary : AppColors.border,
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            if (!isInProgress) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: _isBusy || onCancel == null ? null : onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: isCancelling
                      ? const _ButtonSpinner(color: AppColors.error)
                      : Text(context.l10n.cancelTrip),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: ElevatedButton(
                onPressed: _isBusy
                    ? null
                    : (isInProgress ? cubit.finishRide : cubit.startRide),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isInProgress ? AppColors.success : AppColors.primary,
                  foregroundColor: isInProgress ? Colors.white : AppColors.textOnPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: isUpdating
                    ? const _ButtonSpinner(color: AppColors.textOnPrimary)
                    : Text(
                        isInProgress
                            ? context.l10n.driverFinishTrip
                            : context.l10n.driverStartedTheTrip,
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ButtonSpinner extends StatelessWidget {
  final Color color;

  const _ButtonSpinner({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2, color: color),
    );
  }
}
