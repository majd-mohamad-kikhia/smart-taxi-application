import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_locales.dart';
import '../../../../core/theme/app_palette.dart';

/// The small green pill above an onboarding title ("BOOK FAST"). Capitals
/// and letter spacing are for Latin text only: they mean nothing in Arabic,
/// and spacing would pull its joined letters apart.
class OnboardingTagWidget extends StatelessWidget {
  final String label;

  const OnboardingTagWidget({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isArabic =
        Localizations.localeOf(context).languageCode ==
        AppLocales.arabic.languageCode;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primarySurface,
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingM,
          vertical: AppConstants.paddingXS + 2,
        ),
        child: Text(
          isArabic ? label : label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colors.primaryContent,
            fontWeight: FontWeight.w800,
            letterSpacing: isArabic ? null : 0.8,
          ),
        ),
      ),
    );
  }
}
