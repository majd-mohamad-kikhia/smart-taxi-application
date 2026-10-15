import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/format_price.dart';
import '../../../../core/widgets/price_text_widget.dart';
import '../../../../core/widgets/vehicle_type_icon_widget.dart';
import '../../data/models/vehicle_type_quote_model.dart';
import 'vehicle_type_info_sheet_widget.dart';

/// One card of the vehicle sheet: a rounded thumbnail with the car type's
/// icon, its name and description, and its price at the end. The chosen card
/// is filled with the brand's green wash. A card can be chosen only when
/// [onTap] is set (the type is available and has a price); otherwise it
/// states why — "Currently unavailable" or "Price unavailable" — in readable
/// text with an icon, not by dimming the whole card.
class VehicleTypeTileWidget extends StatelessWidget {
  static const _radius = AppConstants.radiusLarge;
  static const _thumbWidth = 64.0;
  static const _thumbHeight = 52.0;

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
            color: selected ? colors.primarySurface : colors.borderLight,
          ),
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
                    child: _ThumbnailWidget(
                      name: vehicleType.name,
                      selected: selected,
                      width: _thumbWidth,
                      height: _thumbHeight,
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
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
                            ),
                            // Reads about the car without choosing it.
                            IconButton(
                              tooltip: l10n.aboutThisCar,
                              icon: const Icon(Icons.info_outline_rounded),
                              iconSize: 20,
                              color: colors.primaryContent,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              onPressed: () => showVehicleTypeInfoSheet(
                                context,
                                vehicleType,
                              ),
                            ),
                          ],
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
                            selected: selected,
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
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isChoosable
                            ? colors.textPrimary
                            : colors.textSecondary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
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

/// The rounded picture slot at the start of a card. The API carries no car
/// photo, so it holds the icon that fits the type's name, on a soft wash.
class _ThumbnailWidget extends StatelessWidget {
  final String name;
  final bool selected;
  final double width;
  final double height;

  const _ThumbnailWidget({
    required this.name,
    required this.selected,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ExcludeSemantics(
      child: Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? colors.backgroundWhite : colors.backgroundMuted,
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        ),
        child: Icon(
          VehicleTypeIconWidget.iconFor(name),
          size: 30,
          color: colors.primaryContent,
        ),
      ),
    );
  }
}

/// The location fee, as a small green-washed pill under the description.
class _FeeChip extends StatelessWidget {
  final String text;
  final bool selected;

  const _FeeChip({required this.text, required this.selected});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected ? colors.backgroundWhite : colors.primarySurface,
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
