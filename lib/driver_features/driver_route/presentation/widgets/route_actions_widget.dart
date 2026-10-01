import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_animated_dialog.dart';
import '../../../../core/widgets/app_neutral_button_widget.dart';
import '../../../../core/widgets/auth_primary_button_widget.dart';
import '../../data/models/route_session_model.dart';
import '../cubit/route_tracker_cubit.dart';

/// The route tab's buttons for the current step. Each step has one yellow
/// primary, as on the trip screen: Start recording (idle, waiting), Finish
/// while recording, Resume while stopped. "I've arrived" and Pause are
/// neutral. Finish asks first, because it ends the recording; "Start a new
/// route" (finished) is neutral and asks first, because it deletes the
/// route and its summary from the phone.
///
/// While a start is in flight the buttons dim and a thin progress bar runs
/// above them; the labels stay put.
class RouteActionsWidget extends StatelessWidget {
  final RoutePhase phase;
  final bool isPaused;
  final bool isStarting;

  const RouteActionsWidget({
    super.key,
    required this.phase,
    required this.isPaused,
    required this.isStarting,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RouteTrackerCubit>();
    final l10n = context.l10n;

    final children = switch (phase) {
      RoutePhase.idle => [
          AuthPrimaryButtonWidget(
            label: l10n.routeStartRecording,
            isLoading: false,
            onPressed: isStarting ? null : cubit.startTrip,
          ),
          const SizedBox(height: AppConstants.paddingM),
          AppNeutralButtonWidget(
            label: l10n.driverReportArrival,
            icon: Icons.place_rounded,
            onPressed: isStarting ? null : cubit.markArrived,
          ),
        ],
      RoutePhase.waiting => [
          AuthPrimaryButtonWidget(
            label: l10n.routeStartRecording,
            isLoading: false,
            onPressed: isStarting ? null : cubit.startTrip,
          ),
        ],
      RoutePhase.inProgress => [_inProgressRow(context, cubit)],
      RoutePhase.finished => [
          AppNeutralButtonWidget(
            label: l10n.routeStartNew,
            icon: Icons.restart_alt_rounded,
            onPressed: () => _confirmStartNew(context, cubit),
          ),
        ],
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isStarting) ...[
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

  /// Pause/Resume beside Finish, on the live map (so both have solid
  /// fills). Exactly one is the yellow primary: Finish while recording,
  /// Resume while stopped.
  Widget _inProgressRow(BuildContext context, RouteTrackerCubit cubit) {
    final l10n = context.l10n;
    final finish = isPaused
        ? AppNeutralButtonWidget(
            label: l10n.routeFinish,
            backgroundColor: AppColors.backgroundWhite,
            onPressed: () => _confirmFinish(context, cubit),
          )
        : AuthPrimaryButtonWidget(
            label: l10n.routeFinish,
            isLoading: false,
            onPressed: () => _confirmFinish(context, cubit),
          );
    final pauseOrResume = isPaused
        ? AuthPrimaryButtonWidget(
            label: l10n.routeResume,
            isLoading: false,
            onPressed: cubit.resumeTrip,
          )
        : AppNeutralButtonWidget(
            label: l10n.routePause,
            icon: Icons.pause_rounded,
            backgroundColor: AppColors.backgroundWhite,
            onPressed: cubit.pauseTrip,
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

  Future<void> _confirmFinish(BuildContext context, RouteTrackerCubit cubit) {
    final l10n = context.l10n;
    return showAppDialog<void>(
      context: context,
      title: l10n.routeFinishConfirmTitle,
      message: l10n.routeFinishConfirmMessage,
      icon: Icons.flag_rounded,
      confirmLabel: l10n.routeFinish,
      onConfirm: cubit.finishTrip,
    );
  }

  Future<void> _confirmStartNew(BuildContext context, RouteTrackerCubit cubit) {
    final l10n = context.l10n;
    return showAppDialog<void>(
      context: context,
      title: l10n.routeStartNewConfirmTitle,
      message: l10n.routeStartNewConfirmMessage,
      icon: Icons.delete_outline_rounded,
      tone: AppDialogTone.destructive,
      confirmLabel: l10n.routeStartNew,
      onConfirm: cubit.startNewRoute,
    );
  }
}
