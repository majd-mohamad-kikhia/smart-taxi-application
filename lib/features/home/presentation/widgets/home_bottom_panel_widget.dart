import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/widgets/app_destructive_button_widget.dart';
import '../../../../core/widgets/auth_error_banner_widget.dart';
import '../../../../core/widgets/auth_primary_button_widget.dart';
import '../../../../core/widgets/cancel_reason_dialog_widget.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import 'active_ride_card_widget.dart';
import 'home_gps_button_widget.dart';
import 'route_points_card_widget.dart';

/// Everything pinned to the bottom of the home map: the From / To card and
/// the Search (or Cancel request) button.
class HomeBottomPanelWidget extends StatelessWidget {
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;

  const HomeBottomPanelWidget({
    super.key,
    required this.onPickFrom,
    required this.onPickTo,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        final isLocked = state.arePointsLocked;
        final cubit = context.read<HomeCubit>();
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.errorMessage != null) ...[
              AuthErrorBannerWidget(message: state.errorMessage!),
              const SizedBox(height: AppConstants.paddingM),
            ],
            if (state.activeRide != null) ...[
              ActiveRideCardWidget(ride: state.activeRide!),
              const SizedBox(height: AppConstants.paddingM),
            ],
            // "Use my location", above the From / To card at its right end.
            Align(
              alignment: Alignment.centerRight,
              child: HomeGpsButtonWidget(
                isLoading: state.isLocating,
                onTap: isLocked ? null : cubit.locateMe,
                size: 64,
              ),
            ),
            const SizedBox(height: AppConstants.paddingS),
            RoutePointsCardWidget(
              from: state.fromLocation,
              to: state.toLocation,
              onPickFrom: isLocked ? null : onPickFrom,
              onPickTo: isLocked ? null : onPickTo,
            ),
            const SizedBox(height: AppConstants.paddingM),
            if (state.hasActiveRide)
              AppDestructiveButtonWidget(
                label: l10n.cancelRequest,
                isLoading: state.isCancelling,
                onPressed: () => _confirmCancel(context),
              )
            else
              // While ordering is blocked the home screen shows the blocked
              // panel instead of this whole widget.
              AuthPrimaryButtonWidget(
                label: l10n.search,
                isLoading: state.isSearching || state.isBooking,
                onPressed: state.canSearch ? cubit.searchRide : null,
              ),
          ],
        );
      },
    );
  }

  /// Asks for a reason first, like the tracking screen, so a request can't
  /// be cancelled by one stray tap.
  Future<void> _confirmCancel(BuildContext context) async {
    final cubit = context.read<HomeCubit>();
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => CancelReasonDialogWidget(
        title: context.l10n.cancelRequest,
        showCancelLimit: false,
      ),
    );
    if (reason != null) cubit.cancelRide(reason: reason);
  }
}
