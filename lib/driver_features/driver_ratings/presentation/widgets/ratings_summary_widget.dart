import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/ride_rating/presentation/widgets/star_rating_widget.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/driver_ratings_page_model.dart';

/// The driver's average with its stars and count, and one bar per star
/// showing how many ratings gave it.
class RatingsSummaryWidget extends StatelessWidget {
  final DriverRatingsSummaryModel summary;

  const RatingsSummaryWidget({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final average = summary.average;
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                average == null ? '—' : average.toStringAsFixed(1),
                style: textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: AppConstants.paddingXS),
              StarRatingWidget(value: average ?? 0, size: 18),
              const SizedBox(height: AppConstants.paddingXS),
              Text(
                l10n.ratingsCount(summary.count),
                style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(width: AppConstants.paddingXL),
          Expanded(
            child: Column(
              children: [
                for (var star = 5; star >= 1; star--)
                  _StarBar(star: star, share: summary.shareOf(star), count: summary.distribution[star] ?? 0),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StarBar extends StatelessWidget {
  final int star;
  final double share;
  final int count;

  const _StarBar({required this.star, required this.share, required this.count});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: AppColors.textSecondary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 14, child: Text('$star', style: style)),
          const Icon(Icons.star_rounded, size: 12, color: AppColors.accent),
          const SizedBox(width: AppConstants.paddingS),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.radiusFull),
              child: LinearProgressIndicator(
                value: share,
                minHeight: 6,
                backgroundColor: AppColors.borderLight,
                color: AppColors.accent,
              ),
            ),
          ),
          const SizedBox(width: AppConstants.paddingS),
          SizedBox(
            width: 24,
            child: Text('$count', style: style, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}
