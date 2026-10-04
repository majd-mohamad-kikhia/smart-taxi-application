import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format_date.dart';
import '../../../../core/widgets/second_ticker_widget.dart';
import '../../data/models/shared_order_preview_model.dart';

/// What the driver can do with the order, in the app's own words (the
/// API's `message` is only an English hint). A scheduled order also counts
/// down to [opensAt] during its last day.
class SharedOrderStatusWidget extends StatelessWidget {
  final SharedOrderAvailability availability;
  final DateTime? opensAt;
  final String? vehicleTypeName;

  const SharedOrderStatusWidget({
    super.key,
    required this.availability,
    this.opensAt,
    this.vehicleTypeName,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tone = _toneOf(availability);
    final opensAt = this.opensAt;
    final showCountdown = availability == SharedOrderAvailability.scheduled &&
        opensAt != null &&
        opensAt.difference(DateTime.now().toUtc()) < const Duration(days: 1);
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppConstants.paddingM),
        decoration: BoxDecoration(
          color: tone.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          border: Border.all(color: tone.color.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_iconOf(availability), color: tone.color, size: 22),
            const SizedBox(width: AppConstants.paddingS),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _messageOf(context, l10n),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                  ),
                  if (showCountdown)
                    SecondTickerWidget(
                      active: true,
                      builder: (context) => Text(
                        l10n.sharedOrderOpensIn(_countdown(opensAt)),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
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

  String _messageOf(BuildContext context, AppLocalizations l10n) {
    return switch (availability) {
      SharedOrderAvailability.available => l10n.sharedOrderAvailable,
      SharedOrderAvailability.scheduled => opensAt == null
          ? l10n.sharedOrderNotOpenYet
          : l10n.sharedOrderOpensAt(formatDateTimeValue(context, opensAt!.toLocal())),
      SharedOrderAvailability.busy => l10n.sharedOrderBusy,
      SharedOrderAvailability.wrongVehicleType =>
        l10n.sharedOrderWrongVehicle(vehicleTypeName ?? '—'),
      SharedOrderAvailability.noVehicle => l10n.sharedOrderNoVehicle,
      SharedOrderAvailability.notActive => l10n.sharedOrderNotActive,
      SharedOrderAvailability.blocked => l10n.sharedOrderBlocked,
      SharedOrderAvailability.yours => l10n.sharedOrderYours,
      SharedOrderAvailability.taken => l10n.sharedOrderTaken,
      SharedOrderAvailability.cancelled => l10n.sharedOrderCancelled,
      SharedOrderAvailability.unknown => l10n.sharedOrderUnavailable,
    };
  }

  /// `h:mm:ss` left until [opensAt], never below zero.
  static String _countdown(DateTime opensAt) {
    final left = opensAt.difference(DateTime.now().toUtc());
    final seconds = left.isNegative ? 0 : left.inSeconds;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${seconds ~/ 3600}:${two(seconds % 3600 ~/ 60)}:${two(seconds % 60)}';
  }

  static IconData _iconOf(SharedOrderAvailability availability) {
    return switch (availability) {
      SharedOrderAvailability.available => Icons.check_circle_rounded,
      SharedOrderAvailability.scheduled => Icons.schedule_rounded,
      SharedOrderAvailability.busy => Icons.local_taxi_rounded,
      SharedOrderAvailability.wrongVehicleType ||
      SharedOrderAvailability.noVehicle => Icons.directions_car_filled_outlined,
      SharedOrderAvailability.notActive ||
      SharedOrderAvailability.blocked => Icons.block_rounded,
      SharedOrderAvailability.yours => Icons.verified_rounded,
      SharedOrderAvailability.taken => Icons.person_off_rounded,
      SharedOrderAvailability.cancelled => Icons.cancel_rounded,
      SharedOrderAvailability.unknown => Icons.info_outline_rounded,
    };
  }

  static ({Color color, Color surface}) _toneOf(SharedOrderAvailability availability) {
    return switch (availability) {
      SharedOrderAvailability.available ||
      SharedOrderAvailability.yours => (color: AppColors.success, surface: AppColors.successSurface),
      SharedOrderAvailability.taken ||
      SharedOrderAvailability.cancelled ||
      SharedOrderAvailability.blocked ||
      SharedOrderAvailability.notActive => (color: AppColors.error, surface: AppColors.errorSurface),
      _ => (color: AppColors.accent, surface: AppColors.accentSurface),
    };
  }
}
