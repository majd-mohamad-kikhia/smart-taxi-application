import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snack_bar_widget.dart';
import '../../data/models/route_session_model.dart';
import '../cubit/route_tracker_cubit.dart';
import '../cubit/route_tracker_state.dart';
import '../widgets/route_actions_widget.dart';
import '../widgets/route_live_timers_widget.dart';
import '../widgets/route_locate_button_widget.dart';
import '../widgets/route_map_widget.dart';
import '../widgets/route_summary_card_widget.dart';

/// The driver's private "route" tab (مسار): arrived, start trip, stops for
/// a coffee and finish, with the path drawn as the driver goes and a summary
/// card at the end. Everything happens and stays on this phone — no server,
/// no other user. The route is kept until the driver starts a new one.
class DriverRouteScreen extends StatelessWidget {
  const DriverRouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RouteTrackerCubit>(
      create: (_) => sl<RouteTrackerCubit>()..load(),
      child: const _DriverRouteView(),
    );
  }
}

class _DriverRouteView extends StatelessWidget {
  const _DriverRouteView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: BlocListener<RouteTrackerCubit, RouteTrackerState>(
        listenWhen: (previous, current) =>
            current.errorMessage != null &&
            current.errorMessage != previous.errorMessage,
        listener: (context, state) => showAppSnackBar(
          context,
          state.errorMessage!,
          type: AppSnackBarType.error,
        ),
        child: Stack(
          children: [
            BlocBuilder<RouteTrackerCubit, RouteTrackerState>(
              buildWhen: (previous, current) =>
                  previous.carLat != current.carLat ||
                  previous.carLng != current.carLng ||
                  previous.session.points != current.session.points ||
                  previous.phase != current.phase ||
                  previous.locateRequest != current.locateRequest,
              builder: (context, state) => RouteMapWidget(
                carLat: state.carLat,
                carLng: state.carLng,
                path: state.session.points,
                isFinished: state.phase == RoutePhase.finished,
                locateRequest: state.locateRequest,
              ),
            ),
            const _TopOverlay(),
            const _BottomPanel(),
          ],
        ),
      ),
    );
  }
}

/// Live stopwatches while waiting / stopped, the summary card once finished.
class _TopOverlay extends StatelessWidget {
  const _TopOverlay();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RouteTrackerCubit, RouteTrackerState>(
      buildWhen: (previous, current) =>
          previous.phase != current.phase ||
          previous.session.isPaused != current.session.isPaused ||
          previous.session.finishedAt != current.session.finishedAt ||
          // The recording chip shows the distance driven so far.
          previous.session.distanceMeters != current.session.distanceMeters,
      builder: (context, state) {
        if (state.phase == RoutePhase.finished) {
          return RouteSummaryCardWidget(session: state.session);
        }
        return RouteLiveTimersWidget(session: state.session);
      },
    );
  }
}

class _BottomPanel extends StatelessWidget {
  const _BottomPanel();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The locate button rides just above the panel, whatever its height.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: BlocSelector<RouteTrackerCubit, RouteTrackerState, bool>(
                  selector: (state) => state.isLocating,
                  builder: (context, isLocating) => RouteLocateButtonWidget(
                    isLoading: isLocating,
                    onPressed: context.read<RouteTrackerCubit>().locateMe,
                  ),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
              child: BlocBuilder<RouteTrackerCubit, RouteTrackerState>(
                buildWhen: (previous, current) =>
                    previous.phase != current.phase ||
                    previous.session.isPaused != current.session.isPaused ||
                    previous.isStarting != current.isStarting,
                builder: (context, state) => RouteActionsWidget(
                  phase: state.phase,
                  isPaused: state.session.isPaused,
                  isStarting: state.isStarting,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
