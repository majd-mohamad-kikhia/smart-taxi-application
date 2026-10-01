import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_animated_dialog.dart';
import '../../../../core/widgets/app_neutral_button_widget.dart';
import '../../../../core/widgets/auth_error_banner_widget.dart';
import '../../../../core/widgets/auth_primary_button_widget.dart';
import '../../data/location_ticker.dart';
import '../cubit/driver_orders_cubit.dart';
import '../cubit/driver_presence_cubit.dart';
import '../cubit/driver_presence_state.dart';

/// The driver's online/offline control for the live-location connection.
/// [enabled] gates it on the driver's account being approved — see
/// `DriverStatusCardWidget`.
///
/// It states where the driver stands and offers the one next action:
/// offline shows a yellow "Go online", connecting shows "Connecting…" with an
/// amber tile (no spinner), online shows a green "You're online" with a
/// neutral "Go offline". A failure
/// shows its reason in the error banner, with a real "Open settings" button
/// when the fix is in the device settings. Going offline while offers are on
/// screen asks first, so a stray tap can't drop the driver mid-decision.
class DriverOnlineToggleWidget extends StatelessWidget {
  final bool enabled;

  const DriverOnlineToggleWidget({super.key, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DriverPresenceCubit, DriverPresenceState>(
      bloc: sl<DriverPresenceCubit>(),
      builder: (context, state) {
        final isOnline = state.status == DriverPresenceStatus.online;
        final isConnecting = state.status == DriverPresenceStatus.connecting;
        final textTheme = Theme.of(context).textTheme;
        final l10n = context.l10n;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppConstants.paddingL),
          decoration: BoxDecoration(
            color: isOnline ? AppColors.successSurface : AppColors.backgroundWhite,
            borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
            border: Border.all(
              color: isOnline
                  ? AppColors.success.withValues(alpha: 0.3)
                  : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _StatusIcon(isOnline: isOnline, isConnecting: isConnecting),
                  const SizedBox(width: AppConstants.paddingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // A live region: a screen reader announces the change
                        // when the driver goes online, offline or reconnects.
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _title(context, state.status),
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (isOnline)
                          Text(l10n.presenceOnline, style: textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
              if (state.status == DriverPresenceStatus.error &&
                  state.errorMessage != null) ...[
                const SizedBox(height: AppConstants.paddingM),
                AuthErrorBannerWidget(message: state.errorMessage!),
                if (state.locationFailureReason != null) ...[
                  const SizedBox(height: AppConstants.paddingS),
                  AppNeutralButtonWidget(
                    label: l10n.openSettings,
                    icon: Icons.settings_outlined,
                    onPressed: () => state.locationFailureReason ==
                            LocationFailureReason.serviceDisabled
                        ? Geolocator.openLocationSettings()
                        : Geolocator.openAppSettings(),
                  ),
                ],
              ] else if (!enabled) ...[
                const SizedBox(height: AppConstants.paddingM),
                Text(
                  l10n.driverAvailabilityPaused,
                  style: textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: AppConstants.paddingL),
              _action(context, state.status),
            ],
          ),
        );
      },
    );
  }

  /// The one next action for the current status.
  Widget _action(BuildContext context, DriverPresenceStatus status) {
    final l10n = context.l10n;
    final cubit = sl<DriverPresenceCubit>();
    return switch (status) {
      DriverPresenceStatus.online || DriverPresenceStatus.connecting =>
        AppNeutralButtonWidget(
          label: l10n.presenceGoOffline,
          onPressed: () => _goOffline(context, cubit),
        ),
      DriverPresenceStatus.offline || DriverPresenceStatus.error =>
        AuthPrimaryButtonWidget(
          label: l10n.presenceGoOnline,
          isLoading: false,
          onPressed: enabled ? cubit.goOnline : null,
        ),
    };
  }

  /// With offers on screen, going offline makes them vanish — ask first.
  Future<void> _goOffline(BuildContext context, DriverPresenceCubit cubit) {
    if (sl<DriverOrdersCubit>().state.orders.isEmpty) {
      cubit.goOffline();
      return Future.value();
    }
    final l10n = context.l10n;
    return showAppDialog<void>(
      context: context,
      title: l10n.goOfflineConfirmTitle,
      message: l10n.goOfflineConfirmMessage,
      icon: Icons.power_settings_new_rounded,
      tone: AppDialogTone.warning,
      confirmLabel: l10n.presenceGoOffline,
      onConfirm: cubit.goOffline,
    );
  }

  String _title(BuildContext context, DriverPresenceStatus status) {
    final l10n = context.l10n;
    return switch (status) {
      DriverPresenceStatus.online => l10n.presenceYouAreOnline,
      DriverPresenceStatus.connecting => l10n.presenceConnecting,
      DriverPresenceStatus.offline ||
      DriverPresenceStatus.error => l10n.presenceYouAreOffline,
    };
  }
}

/// A round status tile with a car icon: green when online, amber while
/// connecting, grey when offline. No spinner: the title says the state in
/// words ("Connecting…"), so the tile only needs a quiet tint. Decorative.
class _StatusIcon extends StatelessWidget {
  final bool isOnline;
  final bool isConnecting;

  const _StatusIcon({required this.isOnline, required this.isConnecting});

  @override
  Widget build(BuildContext context) {
    final color = isOnline
        ? AppColors.success
        : (isConnecting ? AppColors.accent : AppColors.textSecondary);
    final wash = isOnline
        ? AppColors.success.withValues(alpha: 0.18)
        : (isConnecting ? AppColors.accentSurface : AppColors.backgroundMuted);
    return ExcludeSemantics(
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: wash, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Icon(Icons.local_taxi_rounded, size: 22, color: color),
      ),
    );
  }
}
