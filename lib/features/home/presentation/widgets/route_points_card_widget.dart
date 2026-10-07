import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/models/picked_location_model.dart';
import '../../../../core/theme/app_colors.dart';

/// The From / To card at the bottom of the home map: two tappable rows joined
/// by a dotted connector, with a swap button at the end edge.
///
/// A `null` [onPickFrom] / [onPickTo] / [onSwap] locks that control — while a
/// quote or booking is in flight, or a ride is live, the points can't change.
class RoutePointsCardWidget extends StatelessWidget {
  final PickedLocationModel? from;
  final PickedLocationModel? to;
  final VoidCallback? onPickFrom;
  final VoidCallback? onPickTo;
  final VoidCallback? onSwap;

  const RoutePointsCardWidget({
    super.key,
    required this.from,
    required this.to,
    required this.onPickFrom,
    required this.onPickTo,
    required this.onSwap,
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
        color: AppColors.neutralSurface,
        borderRadius: BorderRadius.circular(AppConstants.radiusXL),
        border: Border.all(color: AppColors.border),
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
                  marker: const Icon(
                    Icons.trip_origin_rounded,
                    color: AppColors.primary,
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
          if (onSwap != null) ...[
            const SizedBox(width: AppConstants.paddingS),
            _SwapButtonWidget(onTap: onSwap!),
          ],
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
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
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
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                    ),
                  ),
                  if (details != null)
                    Text(
                      details,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
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
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.borderStrong,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppConstants.paddingM),
        const Expanded(
          child: Divider(height: 1, color: AppColors.borderLight),
        ),
      ],
    );
  }
}

class _SwapButtonWidget extends StatelessWidget {
  final VoidCallback onTap;

  const _SwapButtonWidget({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = context.l10n.swapPickupAndDestination;
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: AppColors.neutralMuted,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                Icons.swap_vert_rounded,
                color: AppColors.textPrimary,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
