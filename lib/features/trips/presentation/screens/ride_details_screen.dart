import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_loader_widget.dart';
import '../../data/models/ride_history_model.dart';
import '../cubit/ride_details_cubit.dart';
import '../widgets/ride_detail_row_widget.dart';
import '../widgets/ride_route_map_widget.dart';
import '../widgets/ride_route_widget.dart';
import '../widgets/ride_status_badge_widget.dart';
import '../widgets/trip_card_widget.dart';

/// Full details of one ride (`GET /api/customer/rides/{id}`).
class RideDetailsScreen extends StatelessWidget {
  final int rideId;

  const RideDetailsScreen({super.key, required this.rideId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RideDetailsCubit>(
      create: (_) => sl<RideDetailsCubit>(param1: rideId)..load(),
      child: Scaffold(
        backgroundColor: AppColors.backgroundGray,
        appBar: AppBar(title: Text(context.l10n.rideDetailsTitle('$rideId'))),
        body: BlocBuilder<RideDetailsCubit, RideDetailsState>(
          builder: (context, state) {
            final ride = state.ride;
            if (state.isLoading) return const AppLoaderWidget();
            if (ride == null) {
              return _Error(
                message: state.errorMessage ?? context.l10n.errLoadDetails,
                onRetry: context.read<RideDetailsCubit>().load,
              );
            }
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _Section(child: _Summary(ride: ride)),
                    const SizedBox(height: 12),
                    _Section(
                      child: RideRouteWidget(
                        pickup: ride.pickupAddress,
                        dropoff: ride.dropoffAddress,
                        stops: ride.stops.map((s) => s.address).toList(),
                      ),
                    ),
                    if (ride.route.length >= 2) ...[
                      const SizedBox(height: 12),
                      _Section(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.rideDrivenRouteTitle,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            RideRouteMapWidget(route: ride.route),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _Section(child: _Info(ride: ride)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final Widget child;

  const _Section({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _Summary extends StatelessWidget {
  final RideHistoryModel ride;

  const _Summary({required this.ride});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        RideStatusBadgeWidget(status: ride.status),
        const Spacer(),
        Text(
          formatRidePrice(context.l10n, ride.price),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _Info extends StatelessWidget {
  final RideHistoryModel ride;

  const _Info({required this.ride});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cancelledBy = switch (ride.cancelledBy) {
      'customer' => l10n.cancelledByCustomer,
      'driver' => l10n.cancelledByDriver,
      'manager' => l10n.cancelledByManager,
      _ => null,
    };
    final rows = <(String, String?)>[
      (l10n.detailRequestedAt, formatRideDate(ride.requestedAt)),
      (l10n.detailAcceptedAt, ride.acceptedAt == null ? null : formatRideDate(ride.acceptedAt)),
      (l10n.detailStartedAt, ride.startedAt == null ? null : formatRideDate(ride.startedAt)),
      (l10n.detailCompletedAt, ride.completedAt == null ? null : formatRideDate(ride.completedAt)),
      (l10n.detailCancelledAt, ride.cancelledAt == null ? null : formatRideDate(ride.cancelledAt)),
      (l10n.detailCancelledBy, cancelledBy),
      (l10n.fieldCancelReason, ride.cancellationReason),
      (l10n.detailDistance, ride.distanceKm == null ? null : l10n.distanceKm(ride.distanceKm!.toStringAsFixed(1))),
      (l10n.detailEstimatedDuration, ride.estimatedDurationMin == null ? null : l10n.durationMinutes('${ride.estimatedDurationMin}')),
      (l10n.detailStopsFee, ride.stopsFeeTotal > 0 ? formatRidePrice(l10n, ride.stopsFeeTotal) : null),
    ];
    return Column(
      children: [
        for (final (label, value) in rows)
          if (value != null && value.isNotEmpty)
            RideDetailRowWidget(label: label, value: value),
      ],
    );
  }
}

class _Error extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _Error({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: Text(context.l10n.retry)),
        ],
      ),
    );
  }
}
