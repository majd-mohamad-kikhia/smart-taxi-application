import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/models/order_offer_model.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_brand_bar_widget.dart';
import '../../../driver_auth/data/models/driver_status.dart';
import '../../../driver_auth/presentation/cubit/driver_auth_cubit.dart';
import '../../../driver_auth/presentation/cubit/driver_auth_state.dart';
import '../cubit/driver_orders_cubit.dart';
import '../cubit/driver_orders_state.dart';
import '../cubit/driver_presence_cubit.dart';
import '../cubit/driver_presence_state.dart';
import '../widgets/driver_online_toggle_widget.dart';
import '../widgets/driver_order_card_widget.dart';
import '../widgets/driver_status_card_widget.dart';

/// Driver home tab: the driver's own status/toggle, plus — once online —
/// live ride-offer cards fed entirely over the socket connection
/// [DriverPresenceCubit] holds (see `DriverOrdersCubit` / docs/socket.md).
/// There is still no REST endpoint to list rides, so cards only exist as
/// long as the socket keeps pushing them.
class DriverHomeScreen extends StatelessWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: AppBrandBarWidget(),
      ),
      body: BlocListener<DriverOrdersCubit, DriverOrdersState>(
        bloc: sl<DriverOrdersCubit>(),
        listenWhen: (previous, current) =>
            current.errorMessage != null && current.errorMessage != previous.errorMessage,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        },
        child: BlocBuilder<DriverAuthCubit, DriverAuthState>(
          bloc: sl<DriverAuthCubit>(),
          builder: (context, state) {
            final driver = state.driver;
            if (driver == null) return const SizedBox.shrink();
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DriverStatusCardWidget(driver: driver),
                const SizedBox(height: 12),
                DriverOnlineToggleWidget(enabled: driver.status == DriverStatus.active),
                const SizedBox(height: 20),
                const _OrdersSection(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OrdersSection extends StatelessWidget {
  const _OrdersSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DriverPresenceCubit, DriverPresenceState>(
      bloc: sl<DriverPresenceCubit>(),
      builder: (context, presenceState) {
        if (presenceState.status != DriverPresenceStatus.online) {
          return _OrdersPlaceholder(
            icon: Icons.local_taxi_outlined,
            message: context.l10n.driverGoOnlineHint,
          );
        }
        return BlocBuilder<DriverOrdersCubit, DriverOrdersState>(
          bloc: sl<DriverOrdersCubit>(),
          builder: (context, ordersState) {
            if (ordersState.orders.isEmpty) {
              return _OrdersPlaceholder(
                icon: Icons.hourglass_empty_rounded,
                message: context.l10n.driverWaitingForOrders,
              );
            }
            return Column(
              children: [
                for (final order in ordersState.orders)
                  DriverOrderCardWidget(
                    key: ValueKey(order.rideId),
                    order: order,
                    isAccepting: ordersState.acceptingRideId == order.rideId,
                    enabled: ordersState.acceptingRideId == null,
                    onAccept: () => _acceptOrder(context, order),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _acceptOrder(BuildContext context, OrderOfferModel order) async {
    final ok = await sl<DriverOrdersCubit>().acceptOrder(order.rideId);
    if (ok && context.mounted) {
      await Navigator.of(context).pushNamed(
        AppRouter.driverTrip,
        arguments: DriverTripRouteArgs(order: order),
      );
    }
  }
}

class _OrdersPlaceholder extends StatelessWidget {
  final IconData icon;
  final String message;

  const _OrdersPlaceholder({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: AppColors.textTertiary),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
