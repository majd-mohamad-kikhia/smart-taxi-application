import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';
import '../localization/l10n_context_extension.dart';
import '../models/account_block_model.dart';
import '../theme/app_colors.dart';
import 'countdown_text_widget.dart';

/// "Your account is blocked" panel shown in place of the order button
/// (customer) or the ride offers (driver) while a block is active, with a
/// countdown to its end. The server's own text is shown when it sent one;
/// otherwise the end time, [message] (what the block means for the signed-in
/// role) and the reason.
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
    final serverMessage = block.message;
    const detailStyle = TextStyle(
      fontSize: 13,
      color: AppColors.textSecondary,
      height: 1.4,
    );

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
              Semantics(
                header: true,
                child: Text(
                  l10n.accountBlockedTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (until != null) ...[
                const SizedBox(height: AppConstants.paddingS),
                CountdownTextWidget(
                  until: until,
                  label: l10n.accountBlockedEndsIn,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                ),
              ],
              const SizedBox(height: AppConstants.paddingS),
              if (serverMessage != null)
                Text(serverMessage, textAlign: TextAlign.center, style: detailStyle)
              else ...[
                if (until != null)
                  Text(
                    l10n.accountBlockedUntil(_endTime(context, until)),
                    textAlign: TextAlign.center,
                    style: detailStyle,
                  ),
                Text(message, textAlign: TextAlign.center, style: detailStyle),
                if (block.reason != null) ...[
                  const SizedBox(height: AppConstants.paddingS),
                  Text(
                    l10n.accountBlockedReason(block.reason!),
                    textAlign: TextAlign.center,
                    style: detailStyle,
                  ),
                ],
              ],
              if (block.strikeLimit > 0 && block.cancelStrikes > 0) ...[
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

  /// The server's Damascus time when it sent one, otherwise the UTC end
  /// shown in the phone's time.
  String _endTime(BuildContext context, DateTime until) {
    final local = block.blockedUntilLocal;
    if (local != null) return local;
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(locale).add_jm().format(until.toLocal());
  }
}
