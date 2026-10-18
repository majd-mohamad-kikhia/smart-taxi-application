import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/models/order_offer_model.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../driver_auth/presentation/cubit/driver_auth_cubit.dart';
import '../cubit/driver_orders_cubit.dart';
import '../cubit/driver_orders_state.dart';
import '../cubit/driver_presence_cubit.dart';
import '../cubit/driver_presence_state.dart';
import 'driver_order_card_widget.dart';
import 'driver_reconnecting_banner_widget.dart';

/// Accepts [order] and, when the driver won it, opens the trip screen. The
/// trip's commission has come out of the wallet by the time they are back.
Future<void> acceptDriverOrder(
  BuildContext context,
  OrderOfferModel order,
) async {
  final result = await sl<DriverOrdersCubit>().acceptOrder(order.rideId);
  if (result.ok && context.mounted) {
    await Navigator.of(context).pushNamed(
      AppRouter.driverTrip,
      arguments: DriverTripRouteArgs(order: order.withPickupEta(result.eta)),
    );
    sl<DriverAuthCubit>().refreshWalletBalance();
  }
}

/// What sits at the bottom of the driver's map, by where the connection
/// stands: while offers are on the list, the one being looked at (with
/// previous / next arrows when there are several — the map shows the
/// trip of the one in view); otherwise a short pill saying what the app is
/// waiting for. A reconnect keeps the offers, with a warning that they may
/// be stale, instead of hiding them mid-decision.
class DriverOrdersPanelWidget extends StatelessWidget {
  const DriverOrdersPanelWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DriverPresenceCubit, DriverPresenceState>(
      bloc: sl<DriverPresenceCubit>(),
      builder: (context, presence) {
        return BlocBuilder<DriverOrdersCubit, DriverOrdersState>(
          bloc: sl<DriverOrdersCubit>(),
          builder: (context, orders) {
            final l10n = context.l10n;
            final order = orders.selectedOrder;
            if (order == null) {
              return switch (presence.status) {
                DriverPresenceStatus.offline ||
                DriverPresenceStatus.error => _StatusPill(
                  icon: Icons.local_taxi_outlined,
                  message: l10n.driverGoOnlineHint,
                ),
                DriverPresenceStatus.connecting => _StatusPill(
                  icon: Icons.wifi_tethering_rounded,
                  message: l10n.presenceConnecting,
                ),
                DriverPresenceStatus.online => _StatusPill(
                  icon: Icons.hourglass_empty_rounded,
                  message: l10n.driverWaitingForOrders,
                ),
              };
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (presence.status == DriverPresenceStatus.connecting)
                  const DriverReconnectingBannerWidget(),
                if (orders.orders.length > 1)
                  _OrderPager(
                    index: orders.selectedIndex,
                    count: orders.orders.length,
                    onSelect: (i) => sl<DriverOrdersCubit>().selectOrder(
                      orders.orders[i].rideId,
                    ),
                  ),
                // A long note or a small screen scrolls inside the card
                // instead of pushing the map away.
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.5,
                  ),
                  child: SingleChildScrollView(
                    child: DriverOrderCardWidget(
                      // A new card for each offer: its countdown restarts.
                      key: ValueKey(order.rideId),
                      order: order,
                      isAccepting: orders.acceptingRideId == order.rideId,
                      enabled: orders.acceptingRideId == null,
                      onAccept: () => acceptDriverOrder(context, order),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// "Order 2 of 3" between two arrows, to look at the offers one at a time.
class _OrderPager extends StatelessWidget {
  final int index;
  final int count;
  final ValueChanged<int> onSelect;

  const _OrderPager({
    required this.index,
    required this.count,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.paddingS),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.backgroundWhite,
          borderRadius: BorderRadius.circular(AppConstants.radiusFull),
          border: Border.all(color: colors.borderLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              color: colors.textSecondary,
              onPressed: index > 0 ? () => onSelect(index - 1) : null,
            ),
            Semantics(
              liveRegion: true,
              child: Text(
                context.l10n.driverOrderPosition('${index + 1}', '$count'),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              color: colors.textSecondary,
              onPressed: index < count - 1 ? () => onSelect(index + 1) : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// A short rounded note at the foot of the map: an icon and what the app is
/// waiting for.
class _StatusPill extends StatelessWidget {
  final IconData icon;
  final String message;

  const _StatusPill({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      liveRegion: true,
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.backgroundWhite,
          borderRadius: BorderRadius.circular(AppConstants.radiusFull),
          border: Border.all(color: colors.borderLight),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingL,
            vertical: AppConstants.paddingM,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: colors.textSecondary),
              const SizedBox(width: AppConstants.paddingM),
              Flexible(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
