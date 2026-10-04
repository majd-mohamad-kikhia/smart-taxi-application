import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_loader_widget.dart';
import '../../../../core/widgets/app_neutral_button_widget.dart';
import '../../../../core/widgets/network_photo_widget.dart';
import '../../../driver_auth/data/models/driver_vehicle_model.dart';
import '../cubit/driver_vehicle_state.dart';
import 'profile_info_row_widget.dart';

/// The vehicle section of the profile, with every state spoken: loading, a
/// failure with a Retry, no vehicle registered, and the vehicle itself.
class DriverVehicleCardWidget extends StatelessWidget {
  final DriverVehicleState state;
  final VoidCallback onRetry;

  const DriverVehicleCardWidget({
    super.key,
    required this.state,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final vehicle = state.vehicle;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingL),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(l10n.vehicleInfo, style: textTheme.titleSmall),
          ),
          const SizedBox(height: AppConstants.paddingM),
          if (vehicle != null) ...[
            Semantics(
              image: true,
              label: '${vehicle.brand} ${vehicle.model}',
              excludeSemantics: true,
              child: NetworkPhotoWidget(
                imagePath: vehicle.photoUrl,
                width: double.infinity,
                height: 160,
                placeholderIcon: Icons.directions_car_outlined,
              ),
            ),
            const SizedBox(height: AppConstants.paddingM),
            ProfileInfoRowWidget(
              icon: Icons.directions_car_outlined,
              label: l10n.vehicleType,
              value: vehicle.vehicleTypeName,
            ),
            ProfileInfoRowWidget(
              icon: Icons.local_taxi_outlined,
              label: l10n.vehicleModel,
              value: '${vehicle.brand} ${vehicle.model}',
            ),
            ProfileInfoRowWidget(
              icon: Icons.palette_outlined,
              label: l10n.vehicleColor,
              value: vehicle.color,
            ),
            ProfileInfoRowWidget(
              icon: Icons.pin_outlined,
              label: l10n.vehiclePlate,
              value: vehicle.plateNumber,
              isLtrValue: true,
            ),
            ProfileInfoRowWidget(
              icon: Icons.verified_user_outlined,
              label: l10n.vehicleOwnership,
              value: switch (vehicle.ownership) {
                VehicleOwnership.owner => l10n.vehicleOwnershipOwner,
                VehicleOwnership.company => l10n.vehicleOwnershipCompany,
                null => l10n.vehicleOwnershipUnknown,
              },
            ),
          ] else if (state.isLoading)
            const AppLoaderWidget(size: 100)
          else if (state.errorMessage != null) ...[
            Semantics(
              liveRegion: true,
              child: Text(
                state.errorMessage!,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.errorText,
                ),
              ),
            ),
            const SizedBox(height: AppConstants.paddingM),
            AppNeutralButtonWidget(
              label: l10n.retry,
              icon: Icons.refresh_rounded,
              onPressed: onRetry,
            ),
          ] else
            Text(l10n.profileNoVehicle, style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}
