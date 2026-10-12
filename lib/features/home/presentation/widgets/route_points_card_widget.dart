import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/models/picked_location_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';

/// The From / To card at the bottom of the home map: two tappable rows joined
/// by a dotted connector.
///
/// A `null` [onPickFrom] / [onPickTo] locks that control — while a
/// quote or booking is in flight, or a ride is live, the points can't change.
class RoutePointsCardWidget extends StatelessWidget {
  final PickedLocationModel? from;
  final PickedLocationModel? to;
  final VoidCallback? onPickFrom;
  final VoidCallback? onPickTo;

  const RoutePointsCardWidget({
    super.key,
    required this.from,
    required this.to,
    required this.onPickFrom,
    required this.onPickTo,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsetsDirectional.only(
        start: AppConstants.paddingL,
        end: AppConstants.paddingM,
        top: AppConstants.paddingXS,
        bottom: AppConstants.paddingXS,
      ),
      decoration: BoxDecoration(
        color: context.colors.neutralSurface,
        borderRadius: BorderRadius.circular(AppConstants.radiusXL),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PointRowWidget(
                  label: l10n.fromLabel,
                  placeholder: l10n.pickPickupPoint,
                  marker: Icon(
                    Icons.trip_origin_rounded,
                    color: context.colors.primaryContent,
                    size: 20,
                  ),
                  value: from,
                  onTap: onPickFrom,
                ),
                const _ConnectorWidget(),
                _PointRowWidget(
                  label: l10n.toLabel,
                  placeholder: l10n.pickDestination,
                  marker: const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.accent,
                    size: 20,
                  ),
                  value: to,
                  onTap: onPickTo,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PointRowWidget extends StatelessWidget {
  final String label;
  final String placeholder;
  final Widget marker;
  final PickedLocationModel? value;
  final VoidCallback? onTap;

  const _PointRowWidget({
    required this.label,
    required this.placeholder,
    required this.marker,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final details = value?.addressDetails;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Row(
          children: [
            SizedBox(width: 24, child: Center(child: marker)),
            const SizedBox(width: AppConstants.paddingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value?.displayLabel ?? placeholder,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: value != null
                          ? context.colors.textPrimary
                          : context.colors.textTertiary,
                    ),
                  ),
                  if (details != null)
                    Text(
                      details,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            // A word, not an icon: change this point.
            if (value != null && onTap != null)
              TextButton(
                onPressed: onTap,
                style: TextButton.styleFrom(
                  backgroundColor: context.colors.primarySurface,
                  foregroundColor: context.colors.primaryContent,
                  minimumSize: const Size(56, 34),
                  padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
                  shape: const StadiumBorder(
                    side: BorderSide(color: AppColors.primary, width: 1),
                  ),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
                child: Text(context.l10n.editPoint),
              ),
          ],
        ),
      ),
    );
  }
}

/// The dotted line between the two markers, with a divider after it.
class _ConnectorWidget extends StatelessWidget {
  const _ConnectorWidget();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              3,
              (_) => Container(
                width: 3,
                height: 3,
                margin: const EdgeInsets.symmetric(vertical: 1.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.colors.borderStrong,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppConstants.paddingM),
        Expanded(
          child: Divider(height: 1, color: context.colors.borderLight),
        ),
      ],
    );
  }
}
