import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/format_price.dart';
import '../../../../core/widgets/price_text_widget.dart';
import '../../../../core/widgets/vehicle_type_icon_widget.dart';
import '../../data/models/vehicle_type_quote_model.dart';

/// One card of the vehicle sheet: the car type's icon, its name and
/// description, its price, and whether it is the current choice. The chosen
/// card takes the brand's green wash, border and glow. A card can be chosen
/// only when [onTap] is set (the type is available and has a price);
/// otherwise it states why — "Currently unavailable" or "Price unavailable" —
/// in readable text with an icon, not by dimming the whole card.
class VehicleTypeTileWidget extends StatelessWidget {
  static const _radius = 18.0;

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
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final isChoosable = onTap != null;
    final statusText = !vehicleType.available
        ? l10n.notAvailableNow
        : (price == null ? l10n.priceUnavailable : null);
    final radius = BorderRadius.circular(_radius);

    return Semantics(
      button: true,
      enabled: isChoosable,
      selected: selected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: selected ? colors.primarySurface : colors.backgroundWhite,
          borderRadius: radius,
          border: Border.all(
            color: selected ? AppColors.primary : colors.border,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingM),
              child: Row(
                children: [
                  Opacity(
                    opacity: isChoosable ? 1 : 0.5,
                    child: VehicleTypeIconWidget(
                      name: vehicleType.name,
                      size: 56,
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicleType.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: isChoosable
                                ? colors.textPrimary
                                : colors.textSecondary,
                          ),
                        ),
                        if (vehicleType.description != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            vehicleType.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                        if (vehicleType.locationFee > 0 &&
                            statusText == null) ...[
                          const SizedBox(height: AppConstants.paddingXS),
                          _FeeChip(
                            text: locationFeeName == null
                                ? l10n.locationFeeIncluded(
                                    formatNewSyp(l10n, vehicleType.locationFee),
                                  )
                                : l10n.locationFeeIncludedFor(
                                    formatNewSyp(l10n, vehicleType.locationFee),
                                    locationFeeName!,
                                  ),
                          ),
                        ],
                        if (statusText != null) ...[
                          const SizedBox(height: AppConstants.paddingXS),
                          Row(
                            children: [
                              Icon(
                                Icons.block_rounded,
                                size: 14,
                                color: colors.textSecondary,
                              ),
                              const SizedBox(width: AppConstants.paddingXS),
                              Flexible(
                                child: Text(
                                  statusText,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colors.textSecondary,
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
                    const SizedBox(width: AppConstants.paddingS),
                    PriceTextWidget(
                      price: price!,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isChoosable
                            ? (selected
                                  ? colors.primaryContent
                                  : colors.textPrimary)
                            : colors.textSecondary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                  if (isChoosable) ...[
                    const SizedBox(width: AppConstants.paddingS),
                    Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: selected ? AppColors.primary : colors.textTertiary,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The location fee, as a small teal-washed pill under the description.
class _FeeChip extends StatelessWidget {
  final String text;

  const _FeeChip({required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.accentSurface,
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colors.textLink,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
