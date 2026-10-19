import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/network_photo_widget.dart';
import '../../data/models/ride_driver_model.dart';
import '../../data/models/ride_vehicle_model.dart';

/// The driver card of the live trip, set apart from the sheet so it is the
/// first thing the customer reads: a large photo beside the driver's details
/// and, under a divider, the car and its plate. Every detail reads as
/// "label: value" (name, rating, phone, car, car plate). Shown once
/// `customer:ride_accepted` (or a restored `customer:active_ride`) arrives.
class RideDriverCardWidget extends StatelessWidget {
  static const double _photoSize = 72;

  final RideDriverModel driver;
  final RideVehicleModel vehicle;

  const RideDriverCardWidget({super.key, required this.driver, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final car = [vehicle.brand, vehicle.model, vehicle.color]
        .where((part) => part.trim().isNotEmpty)
        .join(' • ');
    final hasPlate = vehicle.plateNumber.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      decoration: BoxDecoration(
        color: colors.neutralSurface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NetworkPhotoWidget(
                imagePath: driver.photoUrl,
                width: _photoSize,
                height: _photoSize,
                borderRadius: _photoSize / 2,
                placeholderIcon: Icons.person_rounded,
              ),
              const SizedBox(width: AppConstants.paddingL),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _LabeledValueWidget(
                            label: l10n.driverCardName,
                            value: driver.fullName,
                            valueStyle: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Every driver who can take a ride has an approved account.
                        Tooltip(
                          message: l10n.driverVerified,
                          child: Icon(
                            Icons.verified_rounded,
                            size: 22,
                            color: colors.primaryContent,
                            semanticLabel: l10n.driverVerified,
                          ),
                        ),
                      ],
                    ),
                    if (driver.rating != null) ...[
                      const SizedBox(height: 6),
                      _LabeledValueWidget(
                        label: l10n.driverCardRating,
                        value: driver.rating!.toStringAsFixed(1),
                        trailing: const Icon(
                          Icons.star_rounded,
                          color: AppColors.star,
                          size: 20,
                        ),
                      ),
                    ],
                    if (driver.phoneNumber.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _LabeledValueWidget(
                        label: l10n.phoneNumber,
                        value: driver.phoneNumber,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (hasPlate || car.isNotEmpty) ...[
            const SizedBox(height: AppConstants.paddingM),
            Divider(height: 1, color: colors.borderLight),
            const SizedBox(height: AppConstants.paddingM),
            // The car and its plate: what the customer looks for.
            if (car.isNotEmpty)
              _LabeledValueWidget(label: l10n.driverCardCar, value: car),
            if (car.isNotEmpty && hasPlate) const SizedBox(height: 6),
            if (hasPlate)
              _LabeledValueWidget(
                label: l10n.driverCardPlate,
                value: vehicle.plateNumber,
                valueStyle: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// One "label: value" line — the label quiet, the value bold. The value is
/// wrapped in a left-to-right isolate so numbers and Latin plates keep their
/// order inside Arabic text.
class _LabeledValueWidget extends StatelessWidget {
  // Left-to-right isolate: U+2066 opens it, U+2069 closes it.
  static final String _ltrIsolateStart = String.fromCharCode(0x2066);
  static final String _ltrIsolateEnd = String.fromCharCode(0x2069);

  final String label;
  final String value;
  final TextStyle? valueStyle;

  /// Shown right after the value (e.g. the rating's star).
  final Widget? trailing;

  const _LabeledValueWidget({
    required this.label,
    required this.value,
    this.valueStyle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final labelStyle = textTheme.bodyMedium?.copyWith(
      color: colors.textSecondary,
      fontWeight: FontWeight.w600,
    );
    final style = valueStyle ??
        textTheme.bodyLarge?.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w700,
        );
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$label: ', style: labelStyle),
          TextSpan(text: '$_ltrIsolateStart$value$_ltrIsolateEnd', style: style),
          if (trailing != null)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 4),
                child: trailing,
              ),
            ),
        ],
      ),
    );
  }
}
