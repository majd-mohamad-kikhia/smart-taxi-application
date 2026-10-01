import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/route_session_model.dart';
import '../cubit/route_tracker_cubit.dart';

/// The route tab's buttons for the current step: I've arrived / Start trip
/// (idle), Start trip (waiting), Pause or Resume + Finish (in progress),
/// and Start a new route (finished).
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (phase == RoutePhase.idle) ...[
          _SecondaryButton(
            icon: Icons.place_rounded,
            label: l10n.driverReportArrival,
            onPressed: isStarting ? null : cubit.markArrived,
          ),
          const SizedBox(height: 10),
        ],
        if (phase == RoutePhase.inProgress) ...[
          _SecondaryButton(
            icon: isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            label: isPaused ? l10n.driverResumeTrip : l10n.driverPauseTrip,
            onPressed: isPaused ? cubit.resumeTrip : cubit.pauseTrip,
          ),
          const SizedBox(height: 10),
        ],
        _PrimaryButton(
          label: switch (phase) {
            RoutePhase.idle || RoutePhase.waiting => l10n.driverStartedTheTrip,
            RoutePhase.inProgress => l10n.driverFinishTrip,
            RoutePhase.finished => l10n.routeStartNew,
          },
          color: phase == RoutePhase.inProgress
              ? AppColors.success
              : AppColors.primary,
          foreground: phase == RoutePhase.inProgress
              ? Colors.white
              : AppColors.textOnPrimary,
          isLoading: isStarting,
          onPressed: switch (phase) {
            RoutePhase.idle || RoutePhase.waiting => cubit.startTrip,
            RoutePhase.inProgress => cubit.finishTrip,
            RoutePhase.finished => cubit.startNewRoute,
          },
        ),
      ],
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color foreground;
  final bool isLoading;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.label,
    required this.color,
    required this.foreground,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: foreground,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: isLoading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: foreground,
              ),
            )
          : Text(label),
    );
  }
}
