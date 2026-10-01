import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';
import '../../../theme/app_colors.dart';

/// Shared body of the full-screen "you can't continue" pages (force update,
/// maintenance): an icon, the server's title and message, optional extra
/// lines, and the action button(s). Centered and width-capped so it reads the
/// same on phone, tablet and web, and scrolls when the text is long.
class AppVersionBlockedLayoutWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  /// Secondary text under the message (release notes, "back at …").
  final List<String> details;
  final List<Widget> actions;

  const AppVersionBlockedLayoutWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.details = const [],
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingXXL),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 72, color: AppColors.primary),
              const SizedBox(height: AppConstants.paddingXL),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: AppConstants.paddingM),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.55,
                  color: AppColors.textSecondary,
                ),
              ),
              for (final line in details) ...[
                const SizedBox(height: AppConstants.paddingM),
                Text(
                  line,
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
              const SizedBox(height: AppConstants.paddingXXL),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}
