import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format_price.dart';
import '../../../../core/widgets/price_text_widget.dart';
import '../../../../core/widgets/vehicle_type_icon_widget.dart';
import '../../data/models/vehicle_type_quote_model.dart';

/// One row of the vehicle sheet: the type, its price and whether it is the
/// current choice. A tile can be chosen only when [onTap] is set (the type
/// is available and has a price). Otherwise it states why — "Currently
/// unavailable" or "Price unavailable" — in readable text with an icon, not
/// by dimming the whole row.
class VehicleTypeTileWidget extends StatelessWidget {
  final VehicleTypeQuoteModel vehicleType;

  /// The area behind this car's location fee, when the server named one.
  final String? locationFeeName;

  /// The price to show, or null when the server could not quote one.
  final double? price;
  final bool selected;
  final VoidCallback? onTap;

  const VehicleTypeTileWidget({
    super.key,
    required this.vehicleType,
    this.locationFeeName,
    required this.price,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final isChoosable = onTap != null;
    final statusText = !vehicleType.available
        ? l10n.notAvailableNow
        : (price == null ? l10n.priceUnavailable : null);

    return Semantics(
      button: true,
      enabled: isChoosable,
      selected: selected,
      child: Material(
        color: selected ? AppColors.primarySurface : AppColors.backgroundMuted,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          child: Container(
            padding: const EdgeInsets.all(AppConstants.paddingL),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Opacity(
                  opacity: isChoosable ? 1 : 0.5,
                  child: VehicleTypeIconWidget(name: vehicleType.name),
                ),
                const SizedBox(width: AppConstants.paddingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicleType.name,
                        style: textTheme.titleMedium?.copyWith(
                          color: isChoosable
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                      if (vehicleType.description != null) ...[
                        const SizedBox(height: AppConstants.paddingXS),
                        Text(
                          vehicleType.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      if (vehicleType.locationFee > 0 && statusText == null) ...[
                        const SizedBox(height: AppConstants.paddingXS),
                        Text(
                          locationFeeName == null
                              ? l10n.locationFeeIncluded(
                                  formatNewSyp(l10n, vehicleType.locationFee),
                                )
                              : l10n.locationFeeIncludedFor(
                                  formatNewSyp(l10n, vehicleType.locationFee),
                                  locationFeeName!,
                                ),
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      if (statusText != null) ...[
                        const SizedBox(height: AppConstants.paddingXS),
                        Row(
                          children: [
                            const Icon(
                              Icons.block_rounded,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: AppConstants.paddingXS),
                            Flexible(
                              child: Text(
                                statusText,
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (price != null) ...[
                  const SizedBox(width: AppConstants.paddingM),
                  PriceTextWidget(
                    price: price!,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isChoosable
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
                if (isChoosable) ...[
                  const SizedBox(width: AppConstants.paddingM),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: selected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
