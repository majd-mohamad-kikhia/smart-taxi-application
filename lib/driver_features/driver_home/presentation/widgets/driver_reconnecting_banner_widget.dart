import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';

/// Above the offers while the connection is being re-established: they were
/// real a moment ago but may no longer be.
class DriverReconnectingBannerWidget extends StatelessWidget {
  const DriverReconnectingBannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: AppConstants.paddingM),
        padding: const EdgeInsets.all(AppConstants.paddingM),
        decoration: BoxDecoration(
          color: context.colors.warningSurface,
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.sync_problem_rounded,
              color: AppColors.warning,
              size: 20,
            ),
            const SizedBox(width: AppConstants.paddingS),
            Expanded(
              child: Text(
                context.l10n.driverReconnectingStale,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.colors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
