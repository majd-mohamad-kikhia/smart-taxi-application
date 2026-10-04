import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format_date.dart';
import '../../../../core/widgets/price_text_widget.dart';
import '../../../../core/widgets/meta_item_widget.dart';
import '../../../../core/widgets/order_route_details_widget.dart';
import '../../../../core/widgets/vehicle_type_icon_widget.dart';
import '../../data/models/shared_order_preview_model.dart';
import 'shared_order_map_widget.dart';

/// The office order itself: a map of the two points, the car type, price,
/// distance and time, the pickup time of a scheduled order, then the route
/// with its details and the customer's note.
class SharedOrderDetailsWidget extends StatelessWidget {
  final SharedOrderPreviewModel preview;

  const SharedOrderDetailsWidget({super.key, required this.preview});

  @override
  Widget build(BuildContext context) {
    final order = preview.order;
    final mapHeight = (MediaQuery.sizeOf(context).height * 0.26).clamp(160.0, 320.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          child: SizedBox(
            height: mapHeight,
            child: SharedOrderMapWidget(
              pickup: LatLng(order.pickupLat, order.pickupLng),
              dropoff: LatLng(order.dropoffLat, order.dropoffLng),
            ),
          ),
        ),
        const SizedBox(height: AppConstants.paddingM),
        _Card(child: _Summary(preview: preview)),
        const SizedBox(height: AppConstants.paddingM),
        _Card(
          child: OrderRouteDetailsWidget(order: order, stops: preview.stops),
        ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  final SharedOrderPreviewModel preview;

  const _Summary({required this.preview});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final order = preview.order;
    final textTheme = Theme.of(context).textTheme;
    final vehicleTypeName = preview.vehicleTypeName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (vehicleTypeName != null) ...[
              VehicleTypeIconWidget(name: vehicleTypeName, size: 40),
              const SizedBox(width: AppConstants.paddingS),
              Expanded(
                child: Text(
                  vehicleTypeName,
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ] else
              const Spacer(),
            PriceTextWidget(
              price: order.estimatedPrice,
              prefix: order.priceIsEstimate ? '~' : '',
              style: textTheme.titleLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.paddingM),
        Wrap(
          spacing: AppConstants.paddingL,
          runSpacing: AppConstants.paddingS,
          children: [
            MetaItemWidget(
              icon: Icons.route_rounded,
              label: l10n.distanceKm(order.distanceKm.toStringAsFixed(1)),
            ),
            MetaItemWidget(
              icon: Icons.schedule_rounded,
              label: l10n.durationMinutesShort('${order.estimatedDurationMin}'),
            ),
            if (preview.scheduledAt != null)
              MetaItemWidget(
                icon: Icons.event_rounded,
                label: l10n.rideScheduledAt(formatUtcDateTime(context, preview.scheduledAt)),
              ),
          ],
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}
