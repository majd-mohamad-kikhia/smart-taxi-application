import 'package:flutter/material.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/second_ticker_widget.dart';
import '../../data/models/route_session_model.dart';
import 'route_timer_card_widget.dart';

/// The live stopwatch at the top of the route tab: how long the driver has
/// been waiting at the start while waiting, and how long the current stop
/// (coffee, …) has lasted while stopped. Shows nothing otherwise.
/// Time only — the route tab has no prices.
class RouteLiveTimersWidget extends StatelessWidget {
  final RouteSessionModel session;

  const RouteLiveTimersWidget({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final isWaiting = session.phase == RoutePhase.waiting;
    final isPaused = session.phase == RoutePhase.inProgress && session.isPaused;
    if (!isWaiting && !isPaused) return const SizedBox.shrink();

    final l10n = context.l10n;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Align(
          alignment: Alignment.topCenter,
          child: SecondTickerWidget(
            active: true,
            builder: (context) {
              final now = DateTime.now();
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
