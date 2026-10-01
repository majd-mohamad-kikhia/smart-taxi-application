import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';
import '../localization/l10n_context_extension.dart';
import '../models/account_block_model.dart';
import '../theme/app_colors.dart';

/// "Your account is blocked until …" panel shown in place of the order
/// button (customer) or the ride offers (driver) while a manager's block is
/// active. [message] explains what the block means for the signed-in role.
class AccountBlockedWidget extends StatelessWidget {
  final AccountBlockModel block;
  final String message;

  const AccountBlockedWidget({
    super.key,
    required this.block,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final until = block.blockedUntil;
    final locale = Localizations.localeOf(context).toString();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppConstants.paddingXL),
          decoration: BoxDecoration(
            color: AppColors.errorSurface,
            borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.block_rounded, color: AppColors.error, size: 40),
              const SizedBox(height: AppConstants.paddingM),
              Text(
                l10n.accountBlockedTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              if (until != null) ...[
                const SizedBox(height: AppConstants.paddingS),
                Text(
                  l10n.accountBlockedUntil(
                    DateFormat.yMMMd(locale).add_jm().format(until),
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                ),
              ],
              const SizedBox(height: AppConstants.paddingS),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              if (block.reason != null) ...[
                const SizedBox(height: AppConstants.paddingS),
                Text(
                  l10n.accountBlockedReason(block.reason!),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (block.strikeLimit > 0) ...[
                const SizedBox(height: AppConstants.paddingS),
                Text(
                  l10n.accountBlockedStrikes(
                    block.cancelStrikes,
                    block.strikeLimit,
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
