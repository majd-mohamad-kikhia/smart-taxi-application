import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_animated_dialog.dart';
import '../cubit/tracking_cubit.dart';
import '../cubit/tracking_state.dart';
import '../widgets/captain_info_widget.dart';
import '../widgets/pickup_payment_widget.dart';
import '../widgets/safety_banner_widget.dart';
import '../widgets/tracking_actions_widget.dart';
import '../widgets/tracking_header_widget.dart';
import '../widgets/tracking_map_widget.dart';

/// Live Trip Tracking screen – captain en route map + driver details panel.
class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TrackingCubit>(
      create: (_) => sl<TrackingCubit>()..initialize(),
      child: const _TrackingView(),
    );
  }
}

class _TrackingView extends StatelessWidget {
  const _TrackingView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: BlocConsumer<TrackingCubit, TrackingState>(
        listenWhen: (prev, curr) =>
            prev.isCancelled != curr.isCancelled && curr.isCancelled,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.tripCancelled),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
        builder: (context, state) {
          return Column(
            children: [
              Expanded(
                flex: 48,
                child: Stack(
                  children: [
                    TrackingMapWidget(trip: state.trip),
                    TrackingHeaderWidget(
                      onBack: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 52,
                child: _TrackingSheet(state: state),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TrackingSheet extends StatelessWidget {
  final TrackingState state;

  const _TrackingSheet({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Column(
                children: [
                  CaptainInfoWidget(captain: state.captain),
                  const SizedBox(height: 14),
                  TrackingActionsWidget(
                    onCall: () => context.read<TrackingCubit>().callCaptain(),
                    onChat: () => context.read<TrackingCubit>().openChat(),
                    onShare: () => context.read<TrackingCubit>().shareTrip(),
                  ),
                  const SizedBox(height: 14),
                  PickupPaymentWidget(trip: state.trip),
                  const SizedBox(height: 12),
                  SafetyBannerWidget(
                    isTrackingEnabled: state.trip.isTrackingEnabled,
                    isSharingEnabled: state.trip.isLocationSharingEnabled,
                  ),
                  const SizedBox(height: 14),
                  _CancelTripButton(
                    isLoading: state.isCancelling,
                    onCancel: () => _showCancelDialog(context),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    final l10n = context.l10n;
    showAppDialog(
      context: context,
      title: l10n.cancelTripQuestion,
      message: l10n.cancelTripMessage,
      confirmLabel: l10n.confirmCancellation,
      cancelLabel: l10n.goBack,
      icon: Icons.cancel_rounded,
      tone: AppDialogTone.destructive,
      onConfirm: () => context.read<TrackingCubit>().cancelTrip(),
    );
  }
}

class _CancelTripButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onCancel;

  const _CancelTripButton({required this.isLoading, this.onCancel});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onCancel,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.errorSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.error,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.close_rounded, color: AppColors.error, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    context.l10n.cancelTrip,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
