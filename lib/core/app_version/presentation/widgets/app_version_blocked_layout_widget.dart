import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';
import '../../../theme/app_colors.dart';

/// Shared body of the full-screen "you can't continue" pages (force update,
/// maintenance): an icon, the server's title and message, an optional
/// highlighted line for the one fact the person needs (when it is back),
/// optional extra lines, and the action button(s). Centered and width-capped
/// so it reads the same on phone, tablet and web, and scrolls when the text is
/// long. The title is announced as a heading.
class AppVersionBlockedLayoutWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  /// The key fact, shown prominently under the message ("Back at 3:00 PM").
  final String? highlight;

  /// Secondary text under the message (release notes, ...).
  final List<String> details;
  final List<Widget> actions;

  const AppVersionBlockedLayoutWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.highlight,
    this.details = const [],
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingXXL),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Icon(icon, size: 72, color: AppColors.primary),
              ),
              const SizedBox(height: AppConstants.paddingXL),
              Semantics(
                header: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.paddingM),
              Text(
                message,
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  height: 1.55,
                  color: AppColors.textSecondary,
                ),
              ),
              if (highlight != null) ...[
                const SizedBox(height: AppConstants.paddingXL),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingL,
                    vertical: AppConstants.paddingM,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(
                      AppConstants.radiusLarge,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppConstants.paddingS),
                      Flexible(
                        child: Text(
                          highlight!,
                          textAlign: TextAlign.center,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              for (final line in details) ...[
                const SizedBox(height: AppConstants.paddingM),
                Text(
                  line,
                  textAlign: TextAlign.start,
                  style: textTheme.bodyMedium?.copyWith(
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
