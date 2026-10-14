import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_animated_dialog.dart';
import '../../../../core/widgets/app_neutral_button_widget.dart';
import '../../../../core/widgets/auth_primary_button_widget.dart';
import '../../../../core/widgets/warning_notice_widget.dart';
import '../cubit/driver_trip_cubit.dart';
import '../cubit/driver_trip_state.dart';
import 'call_customer_button_widget.dart';
import 'passengers_count_dialog_widget.dart';
import 'share_ride_info_button_widget.dart';

/// Action buttons for the active ride, driven by [DriverTripStatus]. Each
/// phase has exactly one green primary: "I've arrived" (accepted), Start
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

  /// The finish found no connection and is being sent again by itself.
  final bool isFinishQueued;

  /// The in-progress trip is currently paused — the button becomes Resume.
  final bool isPaused;
  final VoidCallback? onCancel;

  const DriverTripActionsWidget({
    super.key,
    required this.status,
    required this.isUpdating,
    required this.isCancelling,
    this.isFinishQueued = false,
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
          const CallCustomerButtonWidget(),
          const SizedBox(height: AppConstants.paddingM),
          const ShareRideInfoButtonWidget(),
          const SizedBox(height: AppConstants.paddingM),
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
          const CallCustomerButtonWidget(),
          const SizedBox(height: AppConstants.paddingM),
          AuthPrimaryButtonWidget(
            label: l10n.driverStartedTheTrip,
            isLoading: false,
            onPressed: _isBusy ? null : () => _start(context, cubit),
          ),
          const SizedBox(height: AppConstants.paddingM),
          _cancelButton(context),
        ],
      DriverTripStatus.inProgress => [
          if (isFinishQueued) ...[
            WarningNoticeWidget(message: l10n.tripFinishQueued),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: _isBusy ? null : cubit.finishRide,
                child: Text(l10n.retry),
              ),
            ),
          ],
          _inProgressRow(context, cubit),
        ],
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
            child: LinearProgressIndicator(
              minHeight: 3,
              color: context.colors.primaryContent,
              backgroundColor: context.colors.backgroundMuted,
            ),
          ),
          const SizedBox(height: AppConstants.paddingM),
        ],
        ...children,
      ],
    );
  }

  /// Cancel: a soft red pill, with the label in the dark red text color.
  Widget _cancelButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _isBusy || onCancel == null ? null : onCancel,
      icon: const Icon(Icons.close_rounded, size: 18),
      label: Text(context.l10n.cancelTrip, textAlign: TextAlign.center),
      style: OutlinedButton.styleFrom(
        backgroundColor: context.colors.errorSurface,
        foregroundColor: context.colors.errorText,
        disabledBackgroundColor: context.colors.errorSurface.withValues(alpha: 0.5),
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingM,
          vertical: 14,
        ),
      ),
    );
  }

  /// Pause/Resume beside Finish, on the live map (so both have solid
  /// fills). Exactly one of them is the green primary: Finish while the
  /// trip runs, Resume while it is paused.
  Widget _inProgressRow(BuildContext context, DriverTripCubit cubit) {
    final l10n = context.l10n;
    final finish = isPaused
        ? AppNeutralButtonWidget(
            label: l10n.driverFinishTrip,
            backgroundColor: context.colors.backgroundWhite,
            onPressed: _isBusy ? null : () => _confirmFinish(context, cubit),
          )
        : AuthPrimaryButtonWidget(
            // Shares the row with another button: no room for the arrow.
            showArrow: false,
            label: l10n.driverFinishTrip,
            isLoading: false,
            onPressed: _isBusy ? null : () => _confirmFinish(context, cubit),
          );
    final pauseOrResume = isPaused
        ? AuthPrimaryButtonWidget(
            // Shares the row with another button: no room for the arrow.
            showArrow: false,
            label: l10n.driverResumeTrip,
            isLoading: false,
            onPressed: _isBusy ? null : cubit.resumeTrip,
          )
        : AppNeutralButtonWidget(
            label: l10n.driverPauseTrip,
            icon: Icons.pause_rounded,
            backgroundColor: context.colors.backgroundWhite,
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
