import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/location_ticker.dart';
import '../cubit/driver_presence_cubit.dart';
import '../cubit/driver_presence_state.dart';

/// Online/offline switch for the driver's live-location connection.
/// [enabled] gates it on the driver's account being approved — see
/// `DriverStatusCardWidget`.
class DriverOnlineToggleWidget extends StatelessWidget {
  final bool enabled;

  const DriverOnlineToggleWidget({super.key, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DriverPresenceCubit, DriverPresenceState>(
      bloc: sl<DriverPresenceCubit>(),
      builder: (context, state) {
        final isToggledOn = state.status == DriverPresenceStatus.online ||
            state.status == DriverPresenceStatus.connecting;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.backgroundWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title(context, state.status),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (state.status == DriverPresenceStatus.error &&
                        state.errorMessage != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        state.errorMessage!,
                        style: const TextStyle(fontSize: 12, color: AppColors.error),
                      ),
                      if (state.locationFailureReason != null) ...[
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => state.locationFailureReason ==
                                  LocationFailureReason.serviceDisabled
                              ? Geolocator.openLocationSettings()
                              : Geolocator.openAppSettings(),
                          child: Text(
                            context.l10n.openSettings,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ] else if (!enabled) ...[
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.driverAvailabilityPaused,
                        style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                      ),
                    ],
                  ],
                ),
              ),
              Switch(
                value: isToggledOn,
                activeThumbColor: AppColors.success,
                onChanged: !enabled
                    ? null
                    : (value) {
                        final cubit = sl<DriverPresenceCubit>();
                        if (value) {
                          cubit.goOnline();
                        } else {
                          cubit.goOffline();
                        }
                      },
              ),
            ],
          ),
        );
      },
    );
  }

  String _title(BuildContext context, DriverPresenceStatus status) {
    final l10n = context.l10n;
    return switch (status) {
      DriverPresenceStatus.online => l10n.presenceOnline,
      DriverPresenceStatus.connecting => l10n.presenceConnecting,
      DriverPresenceStatus.offline => l10n.presenceOffline,
      DriverPresenceStatus.error => l10n.presenceOffline,
    };
  }
}
