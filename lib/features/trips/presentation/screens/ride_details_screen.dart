import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format_date.dart';
import '../../../../core/utils/format_price.dart';
import '../../../../core/widgets/app_loader_widget.dart';
import '../../../../core/widgets/bill_row_widget.dart';
import '../../../../core/widgets/live_fee_card_widget.dart';
import '../../../../core/widgets/meta_item_widget.dart';
import '../../data/models/ride_history_model.dart';
import '../cubit/ride_details_cubit.dart';
import '../widgets/ride_detail_row_widget.dart';
import '../widgets/ride_route_map_widget.dart';
import '../widgets/ride_route_widget.dart';
import '../widgets/ride_status_badge_widget.dart';

/// Full details of one ride (`GET /api/customer/rides/{id}`): its status,
/// route, what it cost and whether it was paid, and when each step happened.
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
                  padding: const EdgeInsets.all(AppConstants.paddingL),
                  children: [
                    _Section(child: _Summary(ride: ride)),
                    const SizedBox(height: AppConstants.paddingM),
                    if (ride.shownPrice != null) ...[
                      _Section(child: _Fare(ride: ride)),
                      const SizedBox(height: AppConstants.paddingM),
                    ],
                    _Section(
                      child: RideRouteWidget(
                        pickup: ride.pickupAddress,
                        dropoff: ride.dropoffAddress,
                        stops: ride.stops.map((s) => s.address).toList(),
                      ),
                    ),
                    if (ride.route.length >= 2) ...[
                      const SizedBox(height: AppConstants.paddingM),
                      _Section(child: _DrivenRoute(ride: ride)),
                    ],
                    if (ride.status == RideStatus.cancelled) ...[
                      const SizedBox(height: AppConstants.paddingM),
                      _Section(child: _Cancellation(ride: ride)),
                    ],
                    const SizedBox(height: AppConstants.paddingM),
                    _Section(child: _Times(ride: ride)),
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
      padding: const EdgeInsets.all(AppConstants.paddingL),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

/// Status, when it was requested, and how far and how long it was.
class _Summary extends StatelessWidget {
  final RideHistoryModel ride;

  const _Summary({required this.ride});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final distance = ride.shownDistanceKm;
    final duration = ride.estimatedDurationMin;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppConstants.paddingM,
          runSpacing: AppConstants.paddingS,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            RideStatusBadgeWidget(status: ride.status),
            Text(
              formatDateTime(context, ride.requestedAt),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        if (distance != null || duration != null) ...[
          const SizedBox(height: AppConstants.paddingM),
          Wrap(
            spacing: AppConstants.paddingL,
            runSpacing: AppConstants.paddingXS,
            children: [
              if (distance != null)
                MetaItemWidget(
                  icon: Icons.straighten_rounded,
                  label: l10n.distanceKm(distance.toStringAsFixed(1)),
                ),
              if (duration != null)
                MetaItemWidget(
                  icon: Icons.schedule_rounded,
                  label: l10n.durationMinutesShort('$duration'),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// What the ride cost: the price as the hero, then (once completed) where it
/// came from and whether the customer has paid. Before completion the price
/// is labelled as an estimate.
class _Fare extends StatelessWidget {
  final RideHistoryModel ride;

  const _Fare({required this.ride});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final price = ride.shownPrice;
    if (price == null) return const SizedBox.shrink();
    String money(double amount) => l10n.priceSyp(formatPrice(amount));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          ride.isPriceEstimate ? l10n.fareEstimatedPrice : l10n.fareFinalPrice,
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: AppConstants.paddingXS),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              money(price),
              style: textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
        if (ride.isCompleted) ...[
          const Divider(height: AppConstants.paddingXXL),
          if (ride.tripFare > 0)
            BillRowWidget(label: l10n.fareTripFare, value: money(ride.tripFare)),
          if (ride.stopsFeeTotal > 0)
            BillRowWidget(
              label: l10n.fareStopsFee,
              value: money(ride.stopsFeeTotal),
            ),
          if (ride.waitingFee > 0)
            BillRowWidget(
              label: l10n.fareWaiting,
              value: money(ride.waitingFee),
            ),
          if (ride.pauseFeeTotal > 0)
            BillRowWidget(
              label: l10n.farePauses,
              detail: ride.pauseCount > 0
                  ? l10n.farePausesDetail(
                      '${ride.pauseCount}',
                      LiveFeeCardWidget.clock(ride.pauseTotalSeconds),
                    )
                  : null,
              value: money(ride.pauseFeeTotal),
            ),
          const Divider(height: AppConstants.paddingXXL),
          _PaymentStatus(ride: ride),
        ],
      ],
    );
  }
}

/// "Paid · 27 Sep 2026, 1:00 PM" or "Waiting for payment", with an icon so
/// the state is never color alone.
class _PaymentStatus extends StatelessWidget {
  final RideHistoryModel ride;

  const _PaymentStatus({required this.ride});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final paidAt = ride.paidAt;
    final text = ride.isPaid
        ? (paidAt == null || paidAt.isEmpty
              ? l10n.detailPaymentPaid
              : '${l10n.detailPaymentPaid} · ${formatDateTime(context, paidAt)}')
        : l10n.detailPaymentUnpaid;
    return Row(
      children: [
        Icon(
          ride.isPaid ? Icons.check_circle_rounded : Icons.schedule_rounded,
          color: ride.isPaid ? AppColors.success : AppColors.accent,
        ),
        const SizedBox(width: AppConstants.paddingM),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.titleSmall),
        ),
      ],
    );
  }
}

/// The path the driver actually drove. The map has no readable content of
/// its own, so it is named for screen readers instead.
class _DrivenRoute extends StatelessWidget {
  final RideHistoryModel ride;

  const _DrivenRoute({required this.ride});

  @override
  Widget build(BuildContext context) {
    final title = context.l10n.rideDrivenRouteTitle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: Theme.of(context).textTheme.titleSmall),
        ),
        const SizedBox(height: AppConstants.paddingM),
        Semantics(
          label: title,
          image: true,
          excludeSemantics: true,
          child: RideRouteMapWidget(route: ride.route),
        ),
      ],
    );
  }
}

/// Who cancelled and why, with the full reason (never cut short).
class _Cancellation extends StatelessWidget {
  final RideHistoryModel ride;

  const _Cancellation({required this.ride});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cancelledBy = switch (ride.cancelledBy) {
      'customer' => l10n.cancelledByCustomer,
      'driver' => l10n.cancelledByDriver,
      'manager' => l10n.cancelledByManager,
      _ => null,
    };
    final reason = ride.cancellationReason;
    return Column(
      children: [
        if (cancelledBy != null)
          RideDetailRowWidget(label: l10n.detailCancelledBy, value: cancelledBy),
        if (reason != null && reason.isNotEmpty)
          RideDetailRowWidget(label: l10n.fieldCancelReason, value: reason),
        if (ride.cancelledAt != null)
          RideDetailRowWidget(
            label: l10n.detailCancelledAt,
            value: formatDateTime(context, ride.cancelledAt),
          ),
      ],
    );
  }
}

/// When each step happened. Steps that didn't happen are left out.
class _Times extends StatelessWidget {
  final RideHistoryModel ride;

  const _Times({required this.ride});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rows = <(String, String?)>[
      (l10n.detailRequestedAt, ride.requestedAt),
      (l10n.detailAcceptedAt, ride.acceptedAt),
      (l10n.detailStartedAt, ride.startedAt),
      (l10n.detailCompletedAt, ride.completedAt),
    ];
    return Column(
      children: [
        for (final (label, value) in rows)
          if (value != null && value.isNotEmpty)
            RideDetailRowWidget(
              label: label,
              value: formatDateTime(context, value),
            ),
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
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingXXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppConstants.paddingM),
            Semantics(
              liveRegion: true,
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: AppConstants.paddingL),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
