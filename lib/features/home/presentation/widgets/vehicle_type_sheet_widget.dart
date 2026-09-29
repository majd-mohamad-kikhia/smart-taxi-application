import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/vehicle_type_icon_widget.dart';
import '../../data/models/ride_quote_model.dart';
import '../../data/models/vehicle_type_quote_model.dart';

/// Bottom sheet listing every vehicle type with its quoted price for the
/// requested trip. Purely presentational — it pops itself with the
/// chosen `vehicle_type_id`, and the caller fires the booking request.
class VehicleTypeSheetWidget extends StatelessWidget {
  final RideQuoteModel quote;

  const VehicleTypeSheetWidget({super.key, required this.quote});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                ),
              ),
            ),
            const SizedBox(height: AppConstants.paddingXL),
            Text(
              context.l10n.pickVehicleType,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppConstants.paddingS),
            const SizedBox(height: AppConstants.paddingXL),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: quote.vehicleTypes.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppConstants.paddingM),
                itemBuilder: (context, index) {
                  final vehicleType = quote.vehicleTypes[index];
                  return _VehicleTypeTileWidget(
                    vehicleType: vehicleType,
                    distanceKm: quote.distanceKm,
                    onTap: vehicleType.available
                        ? () => Navigator.of(
                            context,
                          ).pop(vehicleType.vehicleTypeId)
                        : null,
                  );
                },
              ),
            ),
            const SizedBox(height: AppConstants.paddingM),
            Text(
              context.l10n.priceEstimateNote,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single selectable vehicle type row with its quoted price.
class _VehicleTypeTileWidget extends StatelessWidget {
  final VehicleTypeQuoteModel vehicleType;
  final double distanceKm;
  final VoidCallback? onTap;

  const _VehicleTypeTileWidget({
    required this.vehicleType,
    required this.distanceKm,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isAvailable = vehicleType.available;
    final price = vehicleType.displayPrice(distanceKm);

    return Material(
      color: AppColors.backgroundMuted,
      borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        child: Opacity(
          opacity: isAvailable ? 1 : 0.45,
          child: Container(
            padding: const EdgeInsets.all(AppConstants.paddingL),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                VehicleTypeIconWidget(name: vehicleType.name),
                const SizedBox(width: AppConstants.paddingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicleType.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (vehicleType.description != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          vehicleType.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      if (!isAvailable) ...[
                        const SizedBox(height: 2),
                        Text(
                          context.l10n.notAvailableNow,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (price != null)
                  Text(
                    context.l10n.priceSyp(price.toStringAsFixed(0)),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
