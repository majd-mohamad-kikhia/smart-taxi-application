import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/onboarding_step.dart';

/// What an onboarding page shows where its photo would be if the photo can't
/// be loaded: the brand's green with a large icon for the step, so the page
/// still looks designed.
class OnboardingPhotoFallbackWidget extends StatelessWidget {
  final OnboardingStep step;

  const OnboardingPhotoFallbackWidget({super.key, required this.step});

  IconData get _icon => switch (step) {
    OnboardingStep.bookFast => Icons.local_taxi_rounded,
    OnboardingStep.liveTracking => Icons.my_location_rounded,
    OnboardingStep.rideOptions => Icons.directions_car_rounded,
    OnboardingStep.callCenter => Icons.support_agent_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryBright],
        ),
      ),
      child: Center(
        child: ExcludeSemantics(
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _icon,
              size: 88,
              color: AppColors.white,
              semanticLabel: null,
            ),
          ),
        ),
      ),
    );
  }
}
