import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/widgets/app_neutral_button_widget.dart';
import '../../../../core/widgets/auth_error_banner_widget.dart';
import '../../data/location_ticker.dart';
import '../cubit/driver_presence_cubit.dart';
import '../cubit/driver_presence_state.dart';

/// [DriverPresenceErrorWidget] for the current connection status: shown only
/// while going online has failed, nothing otherwise. Sits under the same
/// spacing as the notices above the offers.
class DriverPresenceErrorBannerWidget extends StatelessWidget {
  const DriverPresenceErrorBannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DriverPresenceCubit, DriverPresenceState>(
      bloc: sl<DriverPresenceCubit>(),
      builder: (context, state) {
        final message = state.errorMessage;
        if (state.status != DriverPresenceStatus.error || message == null) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: AppConstants.paddingM),
          child: DriverPresenceErrorWidget(
            message: message,
            reason: state.locationFailureReason,
          ),
        );
      },
    );
  }
}

/// Why going online failed: the reason in an error banner, and — when the
/// fix is in the device settings — a real "Open settings" button under it.
class DriverPresenceErrorWidget extends StatelessWidget {
  final String message;
  final LocationFailureReason? reason;

  const DriverPresenceErrorWidget({
    super.key,
    required this.message,
    required this.reason,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthErrorBannerWidget(message: message),
        if (reason != null) ...[
          const SizedBox(height: AppConstants.paddingS),
          AppNeutralButtonWidget(
            label: context.l10n.openSettings,
            icon: Icons.settings_outlined,
            onPressed: () => reason == LocationFailureReason.serviceDisabled
                ? Geolocator.openLocationSettings()
                : Geolocator.openAppSettings(),
          ),
        ],
      ],
    );
  }
}
