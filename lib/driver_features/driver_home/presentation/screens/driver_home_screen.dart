import 'package:flutter/material.dart';
import '../../../../core/contact_us/data/models/contact_number_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/models/order_offer_model.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/account_block_gate_widget.dart';
import '../../../../core/widgets/app_brand_bar_widget.dart';
import '../../../../core/widgets/app_snack_bar_widget.dart';
import '../../../../core/widgets/wallet_too_low_dialog.dart';
import '../../../driver_auth/data/models/driver_status.dart';
import '../../../driver_auth/presentation/cubit/driver_auth_cubit.dart';
import '../../../driver_auth/presentation/cubit/driver_auth_state.dart';
import '../cubit/driver_orders_cubit.dart';
import '../cubit/driver_orders_state.dart';
import '../cubit/driver_presence_cubit.dart';
import '../cubit/driver_presence_state.dart';
import '../widgets/driver_low_wallet_notice_widget.dart';
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
          if (state.errorIsWalletTooLow) {
            showWalletTooLowDialog(context, state.errorMessage!);
            return;
          }
          showAppSnackBar(
            context,
            state.errorMessage!,
            type: AppSnackBarType.error,
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
                // Only for an approved driver: one still pending has an empty
                // wallet and can't accept anything yet anyway.
                if (driver.status == DriverStatus.active) const DriverLowWalletNoticeWidget(),
                DriverOnlineToggleWidget(enabled: driver.status == DriverStatus.active),
                const SizedBox(height: 20),
                // Blocked drivers get no offers; the toggle stays so they can
                // still go offline.
                AccountBlockGateWidget(
                  blockedMessage: context.l10n.accountBlockedDriverMessage,
                  contactApp: ContactUsApp.driver,
                  child: const _OrdersSection(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// What sits under the online control, by connection status: a hint while
/// offline or failed (the reason is in the control above), a spinner while
/// connecting, and the offers while online. A reconnect keeps the offers on
/// screen with a warning that they may be stale, instead of hiding them
/// mid-decision.
class _OrdersSection extends StatelessWidget {
  const _OrdersSection();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<DriverPresenceCubit, DriverPresenceState>(
      bloc: sl<DriverPresenceCubit>(),
      builder: (context, presenceState) {
        return switch (presenceState.status) {
          DriverPresenceStatus.offline || DriverPresenceStatus.error =>
            _OrdersPlaceholder(
              icon: Icons.local_taxi_outlined,
              message: l10n.driverGoOnlineHint,
            ),
          DriverPresenceStatus.connecting => _OrdersList(
              isReconnecting: true,
              emptyPlaceholder: _OrdersPlaceholder(
                icon: Icons.wifi_tethering_rounded,
                message: l10n.presenceConnecting,
              ),
            ),
          DriverPresenceStatus.online => _OrdersList(
              isReconnecting: false,
              emptyPlaceholder: _OrdersPlaceholder(
                icon: Icons.hourglass_empty_rounded,
                message: l10n.driverWaitingForOrders,
              ),
            ),
        };
      },
    );
  }
}

class _OrdersList extends StatelessWidget {
  final bool isReconnecting;
  final Widget emptyPlaceholder;

  const _OrdersList({required this.isReconnecting, required this.emptyPlaceholder});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DriverOrdersCubit, DriverOrdersState>(
      bloc: sl<DriverOrdersCubit>(),
      builder: (context, ordersState) {
        if (ordersState.orders.isEmpty) return emptyPlaceholder;
        return Column(
          children: [
            if (isReconnecting) const _ReconnectingBanner(),
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
  }

  Future<void> _acceptOrder(BuildContext context, OrderOfferModel order) async {
    final result = await sl<DriverOrdersCubit>().acceptOrder(order.rideId);
    if (result.ok && context.mounted) {
      await Navigator.of(context).pushNamed(
        AppRouter.driverTrip,
        arguments: DriverTripRouteArgs(order: order.withPickupEta(result.eta)),
      );
      // The trip's commission has come out of the wallet by now.
      sl<DriverAuthCubit>().refreshWalletBalance();
    }
  }
}

/// Shown in place of the offers: an icon and a message, centered and padded
/// so long text wraps well. No spinner, even while connecting: the message
/// says so in words.
class _OrdersPlaceholder extends StatelessWidget {
  final IconData icon;
  final String message;

  const _OrdersPlaceholder({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingXXL,
        vertical: AppConstants.paddingXXL,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ExcludeSemantics(
            child: Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.backgroundMuted,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 28, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: AppConstants.paddingL),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }
}

/// Above the offers while the connection is being re-established: they were
/// real a moment ago but may no longer be.
class _ReconnectingBanner extends StatelessWidget {
  const _ReconnectingBanner();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: AppConstants.paddingM),
        padding: const EdgeInsets.all(AppConstants.paddingM),
        decoration: BoxDecoration(
          color: AppColors.accentSurface,
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.sync_problem_rounded, color: AppColors.accent, size: 20),
            const SizedBox(width: AppConstants.paddingS),
            Expanded(
              child: Text(
                context.l10n.driverReconnectingStale,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
