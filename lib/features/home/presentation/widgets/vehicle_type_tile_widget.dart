import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/format_price.dart';
import '../../../../core/widgets/marquee_text_widget.dart';
import '../../../../core/widgets/price_text_widget.dart';
import '../../../../core/widgets/vehicle_type_photo_widget.dart';
import '../../data/models/vehicle_type_quote_model.dart';
import 'vehicle_type_info_sheet_widget.dart';

/// One card of the vehicle sheet: a rounded thumbnail with the car type's
/// icon, its name and description, and its price at the end. The chosen card
/// is filled with the brand's green wash. A card can be chosen only when
/// [onTap] is set (the type is available and has a price); otherwise it
/// states why — "Currently unavailable" or "Price unavailable" — in readable
/// text with an icon, not by dimming the whole card.
class VehicleTypeTileWidget extends StatelessWidget {
  static const _radius = AppConstants.radiusMedium;
  static const _thumbWidth = 56.0;
  static const _thumbHeight = 42.0;

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
    final hasWalletDiscount =
        price != null &&
        vehicleType.hasWalletDiscount &&
        vehicleType.priceAfterWallet != null;

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
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingM,
                vertical: AppConstants.paddingS,
              ),
              child: Row(
                children: [
                  Opacity(
                    opacity: isChoosable ? 1 : 0.5,
                    child: _ThumbnailWidget(
                      name: vehicleType.name,
                      imageUrl: vehicleType.imageUrl,
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
                        // A long name slides to show the rest of itself.
                        MarqueeTextWidget(
                          text: vehicleType.name,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: isChoosable
                                ? colors.textPrimary
                                : colors.textSecondary,
                          ),
                        ),
                        // The description, and beside it the way to read about
                        // the car without choosing it.
                        Row(
                          children: [
                            Expanded(
                              child: vehicleType.description == null
                                  ? const SizedBox.shrink()
                                  : Text(
                                      vehicleType.description!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: colors.textSecondary,
                                      ),
                                    ),
                            ),
                            IconButton(
                              tooltip: l10n.aboutThisCar,
                              icon: const Icon(Icons.info_outline_rounded),
                              iconSize: 18,
                              color: colors.primaryContent,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              onPressed: () => showVehicleTypeInfoSheet(
                                context,
                                vehicleType,
                              ),
                            ),
                          ],
                        ),
                        if (vehicleType.locationFee > 0 &&
                            statusText == null) ...[
                          const SizedBox(height: AppConstants.paddingXS),
                          _FeeChip(
                            selected: selected,
                            text: locationFeeName == null
                                ? l10n.locationFeeIncluded(
                                    formatPlainSyp(
                                      l10n,
                                      vehicleType.locationFee,
                                    ),
                                  )
                                : l10n.locationFeeIncludedFor(
                                    formatPlainSyp(
                                      l10n,
                                      vehicleType.locationFee,
                                    ),
                                    locationFeeName!,
                                  ),
                          ),
                        ],
                        if (hasWalletDiscount && statusText == null) ...[
                          const SizedBox(height: AppConstants.paddingXS),
                          _FeeChip(
                            selected: selected,
                            text: l10n.walletFromYourWallet(
                              formatPlainSyp(l10n, vehicleType.walletUsed),
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
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // The wallet covers part of it: the cash to pay is
                        // the price, the full price struck through above.
                        if (hasWalletDiscount)
                          Text(
                            formatPlainSyp(l10n, price!),
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                              decoration: TextDecoration.lineThrough,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        PriceTextWidget(
                          price: hasWalletDiscount
                              ? vehicleType.priceAfterWallet!
                              : price!,
                          plain: true,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: isChoosable
                                ? colors.textPrimary
                                : colors.textSecondary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
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

/// The rounded picture slot at the start of a card: the car's picture, or —
/// when the type has none, or it can't be loaded — the icon that fits the
/// type's name, on a soft wash.
class _ThumbnailWidget extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final bool selected;
  final double width;
  final double height;

  const _ThumbnailWidget({
    required this.name,
    required this.imageUrl,
    required this.selected,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return VehicleTypePhotoWidget(
      name: name,
      imageUrl: imageUrl,
      width: width,
      height: height,
      borderRadius: AppConstants.radiusMedium,
      background: selected ? colors.backgroundWhite : colors.backgroundMuted,
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
