import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/format_date.dart';
import '../../../../core/utils/format_price.dart';
import '../../../../core/widgets/app_surface_card_widget.dart';
import '../../data/models/report_reward_model.dart';
import 'wallet_amount_widget.dart';

/// One reward in the month's list: the manager's note (or "Reward" when
/// there is none), when it was given, the wallet balance right after it,
/// and the amount.
class ReportRewardRowWidget extends StatelessWidget {
  final ReportRewardModel reward;

  const ReportRewardRowWidget({super.key, required this.reward});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final secondary = textTheme.bodyLarge?.copyWith(
      color: context.colors.textSecondary,
    );
    return AppSurfaceCardWidget(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: context.colors.warningSurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.card_giftcard_rounded,
              size: 24,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(width: AppConstants.paddingL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.description ?? l10n.reportRewardDefault,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingXS),
                Text(
                  formatDateTime(context, reward.createdAt),
                  style: secondary,
                ),
                const SizedBox(height: AppConstants.paddingXS),
                Text(
                  '${l10n.reportBalanceAfter}: '
                  '${formatNewSyp(l10n, reward.balanceAfter)}',
                  style: secondary,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppConstants.paddingM),
          Flexible(
            child: WalletAmountWidget(
              amount: reward.amount,
              style: textTheme.titleLarge?.copyWith(color: AppColors.success),
              alignment: CrossAxisAlignment.end,
            ),
          ),
        ],
      ),
    );
  }
}
