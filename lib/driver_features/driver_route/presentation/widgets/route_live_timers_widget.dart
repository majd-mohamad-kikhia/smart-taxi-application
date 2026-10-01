import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/fee_chip_widget.dart';
import '../../../../core/widgets/second_ticker_widget.dart';
import '../../data/models/route_session_model.dart';
import 'route_duration_format.dart';
import 'route_timer_card_widget.dart';

/// What sits at the top of the route tab while a route is not finished:
/// - idle: a one-line note that the route is private and stays on this phone;
/// - waiting: how long the driver has been waiting at the start;
/// - recording: a "Recording · 12:41 · 4.2 km" chip, so the driver can see
///   it is working and how far they have gone;
/// - stopped (coffee, …): how long the current stop has lasted.
/// Time and distance only — the route tab has no prices. Once finished, the
/// summary card takes this place instead.
class RouteLiveTimersWidget extends StatelessWidget {
  final RouteSessionModel session;

  const RouteLiveTimersWidget({super.key, required this.session});

  /// Unicode left-to-right isolate (start, end): keeps a clock's digits in
  /// order when it sits inside right-to-left text.
  static final String _ltrStart = String.fromCharCode(0x2066);
  static final String _ltrEnd = String.fromCharCode(0x2069);

  @override
  Widget build(BuildContext context) {
    final phase = session.phase;
    final isIdle = phase == RoutePhase.idle;
    final isWaiting = phase == RoutePhase.waiting;
    final isPaused = phase == RoutePhase.inProgress && session.isPaused;
    final isRecording = phase == RoutePhase.inProgress && !session.isPaused;
    if (!isIdle && !isWaiting && !isPaused && !isRecording) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(top: AppConstants.paddingM),
        child: Align(
          alignment: Alignment.topCenter,
          child: isIdle
              ? FeeChipWidget(
                  icon: Icons.lock_outline_rounded,
                  label: l10n.routeIdleHint,
                )
              : SecondTickerWidget(
                  active: true,
                  builder: (context) {
                    final now = DateTime.now();
                    if (isRecording) {
                      final time = formatRouteDuration(session.tripDuration(now));
                      return FeeChipWidget(
                        icon: Icons.fiber_manual_record_rounded,
                        label: l10n.routeRecordingStatus(
                          '$_ltrStart$time$_ltrEnd',
                          l10n.distanceKm(
                            (session.distanceMeters / 1000).toStringAsFixed(1),
                          ),
                        ),
                      );
                    }
                    return isWaiting
                        ? RouteTimerCardWidget(
                            icon: Icons.hourglass_top_rounded,
                            label: l10n.waitingAtPickup,
                            duration: session.waitingDuration(now),
                            accent: AppColors.success,
                          )
                        : RouteTimerCardWidget(
                            icon: Icons.coffee_rounded,
                            label: l10n.pauseTripPaused,
                            duration: session.currentPauseDuration(now),
                            accent: AppColors.primary,
                          );
                  },
                ),
        ),
      ),
    );
  }
}
