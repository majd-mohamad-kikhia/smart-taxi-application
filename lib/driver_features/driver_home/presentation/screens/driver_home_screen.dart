import 'package:flutter/material.dart';
import '../../../../core/contact_us/data/models/contact_number_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/account_block_gate_widget.dart';
import '../../../../core/widgets/app_brand_bar_widget.dart';
import '../../../../core/widgets/app_snack_bar_widget.dart';
import '../../../../core/widgets/size_reporter_widget.dart';
import '../../../../core/widgets/wallet_too_low_dialog.dart';
import '../../../driver_auth/data/models/driver_status.dart';
import '../../../driver_auth/presentation/cubit/driver_auth_cubit.dart';
import '../../../driver_auth/data/models/driver_user_model.dart';
import '../../../driver_auth/presentation/cubit/driver_auth_state.dart';
import '../cubit/driver_home_map_cubit.dart';
import '../cubit/driver_orders_cubit.dart';
import '../cubit/driver_orders_state.dart';
import '../cubit/driver_presence_cubit.dart';
import '../cubit/driver_presence_state.dart';
import '../widgets/driver_home_map_widget.dart';
import '../widgets/driver_low_wallet_notice_widget.dart';
import '../widgets/driver_online_toggle_widget.dart';
import '../widgets/driver_order_card_widget.dart';
import '../widgets/driver_orders_panel_widget.dart';
import '../widgets/driver_reconnecting_banner_widget.dart';
import '../widgets/driver_status_card_widget.dart';

/// Driver home tab. An approved driver gets a map that fills the screen: it
/// shows where the driver is (GPS) and, when an offer comes in, where it
/// goes from where to where, with the offer's details in a card at the
/// bottom and the online control floating on top. A driver whose account is
/// not approved yet sees the plain status list instead, since there is
/// nothing to drive to.
///
/// Offers are live cards fed entirely over the socket connection
/// [DriverPresenceCubit] holds (see `DriverOrdersCubit` / docs/socket.md).
/// There is still no REST endpoint to list rides, so cards only exist as
/// long as the socket keeps pushing them.
class DriverHomeScreen extends StatelessWidget {
  /// Widest the floating controls grow on tablets and desktop windows.
  static const double _maxContentWidth = 560;

  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DriverHomeMapCubit>(
      create: (_) => sl<DriverHomeMapCubit>(),
      child: Scaffold(
        backgroundColor: context.colors.backgroundGray,
        appBar: const PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: AppBrandBarWidget(),
        ),
        body: BlocListener<DriverOrdersCubit, DriverOrdersState>(
          bloc: sl<DriverOrdersCubit>(),
          listenWhen: (previous, current) =>
              current.errorMessage != null &&
              current.errorMessage != previous.errorMessage,
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
              return driver.status == DriverStatus.active
                  ? const _MapLayout(maxContentWidth: _maxContentWidth)
                  : _ListLayout(driver: driver);
            },
          ),
        ),
      ),
    );
  }
}

/// The map with the controls floating over it: the online control (and the
/// low-wallet notice) at the top, the offers at the bottom. The map is told
/// how much of it they cover, so the trip it frames stays in the open part.
class _MapLayout extends StatefulWidget {
  final double maxContentWidth;

  const _MapLayout({required this.maxContentWidth});

  @override
  State<_MapLayout> createState() => _MapLayoutState();
}

class _MapLayoutState extends State<_MapLayout> {
  double _topInset = 0;
  double _bottomInset = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DriverHomeMapWidget(
            topInset: _topInset,
            bottomInset: _bottomInset,
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: widget.maxContentWidth),
            child: SizeReporterWidget(
              onSize: (size) => setState(() => _topInset = size.height),
              child: const Padding(
                padding: EdgeInsets.all(AppConstants.paddingL),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DriverLowWalletNoticeWidget(),
                    DriverOnlineToggleWidget(enabled: true),
                  ],
                ),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: widget.maxContentWidth),
            child: SizeReporterWidget(
              onSize: (size) => setState(() => _bottomInset = size.height),
              child: Padding(
                // Clear of the floating nav bar drawn over the map.
                padding: EdgeInsets.fromLTRB(
                  AppConstants.paddingL,
                  0,
                  AppConstants.paddingL,
                  AppConstants.paddingL + MediaQuery.paddingOf(context).bottom,
                ),
                // Blocked drivers get no offers; the online control stays so
                // they can still go offline.
                child: AccountBlockGateWidget(
                  blockedMessage: context.l10n.accountBlockedDriverMessage,
                  contactApp: ContactUsApp.driver,
                  child: const DriverOrdersPanelWidget(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The plain list for a driver whose account is not approved: who they are,
/// the status, and the online control (switched off until approved).
class _ListLayout extends StatelessWidget {
  final DriverUserModel driver;

  const _ListLayout({required this.driver});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        DriverStatusCardWidget(driver: driver),
        const SizedBox(height: 12),
        DriverOnlineToggleWidget(enabled: driver.status == DriverStatus.active),
        const SizedBox(height: 20),
        AccountBlockGateWidget(
          blockedMessage: context.l10n.accountBlockedDriverMessage,
          contactApp: ContactUsApp.driver,
          child: const _OrdersSection(),
        ),
      ],
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
          DriverPresenceStatus.offline ||
          DriverPresenceStatus.error => _OrdersPlaceholder(
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

  const _OrdersList({
    required this.isReconnecting,
    required this.emptyPlaceholder,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DriverOrdersCubit, DriverOrdersState>(
      bloc: sl<DriverOrdersCubit>(),
      builder: (context, ordersState) {
        if (ordersState.orders.isEmpty) return emptyPlaceholder;
        return Column(
          children: [
            if (isReconnecting) const DriverReconnectingBannerWidget(),
            for (final order in ordersState.orders)
              DriverOrderCardWidget(
                key: ValueKey(order.rideId),
                order: order,
                isAccepting: ordersState.acceptingRideId == order.rideId,
                enabled: ordersState.acceptingRideId == null,
                onAccept: () => acceptDriverOrder(context, order),
              ),
          ],
        );
      },
    );
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
        color: context.colors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        border: Border.all(color: context.colors.borderLight),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ExcludeSemantics(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: context.colors.backgroundMuted,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 28, color: context.colors.textSecondary),
            ),
          ),
          const SizedBox(height: AppConstants.paddingL),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: context.colors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
