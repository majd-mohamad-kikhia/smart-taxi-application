import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/auth_language_toggle_widget.dart';

/// The top of the onboarding: "01 / 04" at the start edge, and the language
/// switch and Skip at the end edge.
class OnboardingTopBarWidget extends StatelessWidget {
  final int page;
  final int pageCount;
  final VoidCallback onSkip;

  const OnboardingTopBarWidget({
    super.key,
    required this.page,
    required this.pageCount,
    required this.onSkip,
  });

  String _two(int value) => value.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingXL),
      child: Row(
        children: [
          // Latin digits in both languages, and always read left to right —
          // inside a right-to-left line the slash would swap the two numbers.
          Text(
            '${_two(page + 1)} / ${_two(pageCount)}',
            textDirection: TextDirection.ltr,
            style: theme.labelMedium?.copyWith(color: colors.textTertiary),
          ),
          const Spacer(),
          const AuthLanguageToggleWidget(),
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(
              foregroundColor: colors.primaryContent,
              minimumSize: const Size(48, 48),
              textStyle: theme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            child: Text(context.l10n.onboardingSkip),
          ),
        ],
      ),
    );
  }
}
