import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';
import '../../../localization/l10n_context_extension.dart';
import '../../../theme/app_colors.dart';
import '../../../app_version/presentation/widgets/app_version_retry_button_widget.dart';

/// Failure state of the Contact us screen: the reason plus a "Retry" button
/// that shows a spinner while [onRetry] runs.
class ContactUsErrorWidget extends StatelessWidget {
  static const double _maxWidth = 320;

  final String message;
  final Future<void> Function() onRetry;

  const ContactUsErrorWidget({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingXXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.isEmpty ? context.l10n.errServerUnreachable : message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppConstants.paddingL),
              AppVersionRetryButtonWidget(onRetry: onRetry),
            ],
          ),
        ),
      ),
    );
  }
}
