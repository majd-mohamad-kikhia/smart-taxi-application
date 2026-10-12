import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import 'app_logo_widget.dart';

class AuthHeaderWidget extends StatelessWidget {
  final String title;
  final String subtitle;

  /// On the solid brand-green header: white text and a white ring around
  /// the logo.
  final bool onBrand;

  const AuthHeaderWidget({
    super.key,
    required this.title,
    required this.subtitle,
    this.onBrand = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: onBrand ? AppColors.white.withValues(alpha: 0.18) : null,
            borderRadius: BorderRadius.circular(28),
          ),
          child: const AppLogoWidget(size: 84),
        ),
        const SizedBox(height: AppConstants.paddingL),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: onBrand ? AppColors.textOnPrimary : null,
          ),
        ),
        const SizedBox(height: AppConstants.paddingXS),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: onBrand ? AppColors.textOnPrimary.withValues(alpha: 0.85) : null,
          ),
        ),
      ],
    );
  }
}
