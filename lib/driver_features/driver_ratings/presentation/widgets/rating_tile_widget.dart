import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/ride_rating/presentation/widgets/star_rating_widget.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format_date.dart';
import '../../data/models/driver_ratings_page_model.dart';

/// One customer rating: the stars, the comment, who gave it (first name) and
/// the trip it was for.
class RatingTileWidget extends StatelessWidget {
  final DriverRatingItemModel rating;

  const RatingTileWidget({super.key, required this.rating});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final name = rating.customerFirstName;
    final route = [rating.pickupAddress, rating.dropoffAddress]
        .whereType<String>()
        .where((a) => a.trim().isNotEmpty)
        .join(' → ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingL),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StarRatingWidget(value: rating.stars.toDouble(), size: 20),
              const Spacer(),
              if (rating.ratedAt != null)
                Text(
                  formatDateTime(context, rating.ratedAt!),
                  style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
            ],
          ),
          if (rating.comment != null) ...[
            const SizedBox(height: AppConstants.paddingS),
            Text(rating.comment!, style: textTheme.bodyMedium),
          ],
          const SizedBox(height: AppConstants.paddingS),
          Text(
            [
              if (name != null && name.isNotEmpty) l10n.ratingFromCustomer(name),
              l10n.ratingTripNumber(rating.rideId),
            ].join(' · '),
            style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          if (route.isNotEmpty)
            Text(
              route,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
            ),
        ],
      ),
    );
  }
}
