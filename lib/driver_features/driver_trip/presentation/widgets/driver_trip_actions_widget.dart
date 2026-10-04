import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_animated_dialog.dart';
import '../../../../core/widgets/app_neutral_button_widget.dart';
import '../../../../core/widgets/auth_primary_button_widget.dart';
import '../cubit/driver_trip_cubit.dart';
import '../cubit/driver_trip_state.dart';
import 'passengers_count_dialog_widget.dart';

/// Action buttons for the active ride, driven by [DriverTripStatus]. Each
/// phase has exactly one yellow primary: "I've arrived" (accepted), Start
/// the trip (arrived), Finish (in progress) or Resume (paused). Cancel is
/// a separate red-outlined button with its own row, so it is never a
/// thumb-width away from the primary. Finish asks for a confirmation first,
/// because it ends the trip and cannot be undone.
///
/// While any action is in flight every button is dimmed and a thin progress
/// bar runs above them; labels stay put, so it is always clear what the
/// buttons are.
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
    final l10n = context.l10n;

    final children = switch (status) {
      DriverTripStatus.accepted => [
          AuthPrimaryButtonWidget(
            label: l10n.driverReportArrival,
            isLoading: false,
            onPressed: _isBusy ? null : cubit.markArrived,
          ),
          const SizedBox(height: AppConstants.paddingM),
          Row(
            children: [
              Expanded(child: _cancelButton(context)),
              const SizedBox(width: AppConstants.paddingL),
              Expanded(
                child: AppNeutralButtonWidget(
                  label: l10n.driverStartedTheTrip,
                  onPressed: _isBusy ? null : () => _start(context, cubit),
                ),
              ),
            ],
          ),
        ],
      DriverTripStatus.arrived => [
          AuthPrimaryButtonWidget(
            label: l10n.driverStartedTheTrip,
            isLoading: false,
            onPressed: _isBusy ? null : () => _start(context, cubit),
          ),
          const SizedBox(height: AppConstants.paddingM),
          _cancelButton(context),
        ],
      DriverTripStatus.inProgress => [_inProgressRow(context, cubit)],
      // The fare dialog is on screen; nothing left to do here.
      DriverTripStatus.completed => const <Widget>[],
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isBusy) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.radiusFull),
            child: const LinearProgressIndicator(
              minHeight: 3,
              color: AppColors.primary,
              backgroundColor: AppColors.backgroundMuted,
            ),
          ),
          const SizedBox(height: AppConstants.paddingM),
        ],
        ...children,
      ],
    );
  }

  /// Cancel: red outline and icon, but the label stays in the main text
  /// color (red text on this surface is only 4.4:1).
  Widget _cancelButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _isBusy || onCancel == null ? null : onCancel,
      icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.error),
      label: Text(context.l10n.cancelTrip, textAlign: TextAlign.center),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.error, width: 1.5),
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingM,
          vertical: 14,
        ),
      ),
    );
  }

  /// Pause/Resume beside Finish, on the live map (so both have solid
  /// fills). Exactly one of them is the yellow primary: Finish while the
  /// trip runs, Resume while it is paused.
  Widget _inProgressRow(BuildContext context, DriverTripCubit cubit) {
    final l10n = context.l10n;
    final finish = isPaused
        ? AppNeutralButtonWidget(
            label: l10n.driverFinishTrip,
            backgroundColor: AppColors.backgroundWhite,
            onPressed: _isBusy ? null : () => _confirmFinish(context, cubit),
          )
        : AuthPrimaryButtonWidget(
            label: l10n.driverFinishTrip,
            isLoading: false,
            onPressed: _isBusy ? null : () => _confirmFinish(context, cubit),
          );
    final pauseOrResume = isPaused
        ? AuthPrimaryButtonWidget(
            label: l10n.driverResumeTrip,
            isLoading: false,
            onPressed: _isBusy ? null : cubit.resumeTrip,
          )
        : AppNeutralButtonWidget(
            label: l10n.driverPauseTrip,
            icon: Icons.pause_rounded,
            backgroundColor: AppColors.backgroundWhite,
            onPressed: _isBusy ? null : cubit.pauseTrip,
          );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 2, child: pauseOrResume),
          const SizedBox(width: AppConstants.paddingL),
          Expanded(flex: 3, child: finish),
        ],
      ),
    );
  }

  /// A customer app order asks how many got in first; an office order
  /// already shows the reception's number and starts straight away.
  Future<void> _start(BuildContext context, DriverTripCubit cubit) async {
    if (!cubit.state.needsPassengersCount) return cubit.startRide();
    return showPassengersCountDialog(
      context: context,
      max: DriverTripState.maxPickablePassengers,
      onConfirm: (count) => cubit.startRide(passengersCount: count),
    );
  }

  Future<void> _confirmFinish(BuildContext context, DriverTripCubit cubit) {
    final l10n = context.l10n;
    return showAppDialog<void>(
      context: context,
      title: l10n.finishTripConfirmTitle,
      message: l10n.finishTripConfirmMessage,
      icon: Icons.flag_rounded,
      confirmLabel: l10n.driverFinishTrip,
      onConfirm: cubit.finishRide,
    );
  }
}
