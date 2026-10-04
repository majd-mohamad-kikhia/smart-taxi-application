import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_loader_widget.dart';
import '../../../../core/widgets/app_neutral_button_widget.dart';
import '../../../../core/widgets/app_snack_bar_widget.dart';
import '../../../../core/widgets/auth_primary_button_widget.dart';
import '../../data/models/shared_order_preview_model.dart';
import '../cubit/shared_order_cubit.dart';
import '../cubit/shared_order_state.dart';
import '../widgets/shared_order_accept_button_widget.dart';
import '../widgets/shared_order_details_widget.dart';
import '../widgets/shared_order_status_widget.dart';

/// An office order opened from its WhatsApp link. Opening it accepts the
/// order and moves to the normal trip screen; when it can't be taken, the
/// order is shown with the reason (and Accept, once it can be). If another
/// driver is faster, the screen turns to "taken" by itself.
class SharedOrderScreen extends StatelessWidget {
  final String token;

  const SharedOrderScreen({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SharedOrderCubit>(
      create: (_) => sl<SharedOrderCubit>(param1: token)..open(),
      child: const _SharedOrderView(),
    );
  }
}

class _SharedOrderView extends StatefulWidget {
  const _SharedOrderView();

  @override
  State<_SharedOrderView> createState() => _SharedOrderViewState();
}

class _SharedOrderViewState extends State<_SharedOrderView> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Something may have happened while the app was in the background.
    _lifecycle = AppLifecycleListener(
      onResume: () => context.read<SharedOrderCubit>().load(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(title: Text(context.l10n.sharedOrderTitle)),
      body: MultiBlocListener(
        listeners: [
          BlocListener<SharedOrderCubit, SharedOrderState>(
            listenWhen: (previous, current) =>
                current is SharedOrderAccepted || current is SharedOrderBackToTrip,
            listener: _leave,
          ),
          BlocListener<SharedOrderCubit, SharedOrderState>(
            listenWhen: (previous, current) =>
                previous is SharedOrderLoaded &&
                previous.accepting &&
                current is SharedOrderLoaded &&
                current.acceptError != null,
            listener: (context, state) => showAppSnackBar(
              context,
              context.l10n.sharedOrderAcceptFailed,
              type: AppSnackBarType.error,
            ),
          ),
        ],
        child: BlocBuilder<SharedOrderCubit, SharedOrderState>(
          builder: (context, state) => switch (state) {
            SharedOrderLoading() ||
            SharedOrderAccepted() ||
            SharedOrderBackToTrip() => const Center(child: AppLoaderWidget()),
            SharedOrderFailure(:final message) => _MessageView(
                icon: Icons.wifi_off_rounded,
                message: message,
                actionLabel: context.l10n.retry,
                onAction: () => context.read<SharedOrderCubit>().open(),
              ),
            SharedOrderInvalidLink() => _MessageView(
                icon: Icons.link_off_rounded,
                message: context.l10n.sharedOrderInvalidLink,
                actionLabel: context.l10n.close,
                onAction: () => Navigator.of(context).maybePop(),
              ),
            SharedOrderLoaded() => _LoadedView(state: state),
            SharedOrderClosed() => _ClosedView(state: state),
          },
        ),
      ),
    );
  }

  /// Accepted → the normal trip screen in place of this one. Already the
  /// driver's trip → back to it.
  void _leave(BuildContext context, SharedOrderState state) {
    final navigator = Navigator.of(context);
    if (state is SharedOrderAccepted) {
      navigator.pushReplacementNamed(
        AppRouter.driverTrip,
        arguments: DriverTripRouteArgs(order: state.ride.order, resume: state.ride),
      );
    } else {
      navigator.maybePop();
    }
  }
}

/// Keeps the page readable on tablets and wide screens.
class _PageBody extends StatelessWidget {
  final List<Widget> children;

  const _PageBody({required this.children});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.paddingL),
          children: children,
        ),
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  final SharedOrderLoaded state;

  const _LoadedView({required this.state});

  @override
  Widget build(BuildContext context) {
    final preview = state.preview;
    final showGoToTrip =
        preview.availability == SharedOrderAvailability.busy && state.hasOpenTrip;
    return Column(
      children: [
        Expanded(
          child: _PageBody(
            children: [
              SharedOrderStatusWidget(
                availability: preview.availability,
                opensAt: preview.opensAt,
                vehicleTypeName: preview.vehicleTypeName,
              ),
              if (showGoToTrip) ...[
                const SizedBox(height: AppConstants.paddingM),
                AppNeutralButtonWidget(
                  label: context.l10n.sharedOrderGoToTrip,
                  icon: Icons.local_taxi_rounded,
                  onPressed: () => Navigator.of(context).popUntil(
                    (route) => route.settings.name == AppRouter.driverTrip || route.isFirst,
                  ),
                ),
              ],
              const SizedBox(height: AppConstants.paddingM),
              SharedOrderDetailsWidget(preview: preview),
            ],
          ),
        ),
        if (preview.canAccept)
          SharedOrderAcceptButtonWidget(
            isAccepting: state.accepting,
            onAccept: () => context.read<SharedOrderCubit>().accept(),
          ),
      ],
    );
  }
}

class _ClosedView extends StatelessWidget {
  final SharedOrderClosed state;

  const _ClosedView({required this.state});

  @override
  Widget build(BuildContext context) {
    final preview = state.preview;
    return _PageBody(
      children: [
        SharedOrderStatusWidget(availability: state.availability),
        const SizedBox(height: AppConstants.paddingL),
        AppNeutralButtonWidget(
          label: context.l10n.close,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        if (preview != null) ...[
          const SizedBox(height: AppConstants.paddingL),
          Opacity(
            opacity: 0.6,
            child: SharedOrderDetailsWidget(preview: preview),
          ),
        ],
      ],
    );
  }
}

/// A whole-screen message with one way forward (retry, close).
class _MessageView extends StatelessWidget {
  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _MessageView({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingXXL),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: AppColors.textSecondary),
              const SizedBox(height: AppConstants.paddingL),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: AppConstants.paddingXL),
              AuthPrimaryButtonWidget(
                label: actionLabel,
                isLoading: false,
                onPressed: onAction,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
