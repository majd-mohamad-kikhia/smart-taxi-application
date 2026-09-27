import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';

/// Logo + title block shown at the top of every auth screen.
class AuthHeaderWidget extends StatelessWidget {
  final String title;
  final String subtitle;

  const AuthHeaderWidget({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.local_taxi_rounded,
            color: AppColors.textOnPrimary,
            size: 36,
          ),
        ),
        const SizedBox(height: AppConstants.paddingL),
        Text(title, style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: AppConstants.paddingXS),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
