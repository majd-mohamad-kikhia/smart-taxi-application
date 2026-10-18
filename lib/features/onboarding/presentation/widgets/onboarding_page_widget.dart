import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../data/models/onboarding_step.dart';
import 'onboarding_photo_fallback_widget.dart';
import 'onboarding_tag_widget.dart';

/// One onboarding page: the photo filling the room above, then the tag,
/// the title and the subtitle. The photo takes whatever height the text
/// leaves, so a longer title (or a larger text size) never overflows.
class OnboardingPageWidget extends StatelessWidget {
  final OnboardingStep step;

  const OnboardingPageWidget({super.key, required this.step});

  /// Which part of the photo stays in view when the card crops it. The call
  /// center photo has the agent's face in its upper right.
  Alignment get _photoFocus => switch (step) {
    OnboardingStep.callCenter => const Alignment(0.55, -0.3),
    _ => Alignment.center,
  };

  ({String tag, String title, String subtitle}) _copy(AppLocalizations l10n) =>
      switch (step) {
        OnboardingStep.bookFast => (
          tag: l10n.onboardingBookFastTag,
          title: l10n.onboardingBookFastTitle,
          subtitle: l10n.onboardingBookFastSubtitle,
        ),
        OnboardingStep.liveTracking => (
          tag: l10n.onboardingTrackingTag,
          title: l10n.onboardingTrackingTitle,
          subtitle: l10n.onboardingTrackingSubtitle,
        ),
        OnboardingStep.rideOptions => (
          tag: l10n.onboardingRideOptionsTag,
          title: l10n.onboardingRideOptionsTitle,
          subtitle: l10n.onboardingRideOptionsSubtitle,
        ),
        OnboardingStep.callCenter => (
          tag: l10n.onboardingCallCenterTag,
          title: l10n.onboardingCallCenterTitle,
          subtitle: l10n.onboardingCallCenterSubtitle,
        ),
      };

  @override
  Widget build(BuildContext context) {
    final copy = _copy(context.l10n);
    final theme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.radiusXL),
              child: SizedBox.expand(
                child: Image.asset(
                  step.imageAsset,
                  fit: BoxFit.cover,
                  alignment: _photoFocus,
                  // A decoration: the title below says what the page is about.
                  excludeFromSemantics: true,
                  // A photo that is missing or can't be read never leaves a
                  // hole in the page.
                  errorBuilder: (_, _, _) =>
                      OnboardingPhotoFallbackWidget(step: step),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppConstants.paddingXL),
          OnboardingTagWidget(label: copy.tag),
          const SizedBox(height: AppConstants.paddingM),
          Text(copy.title, style: theme.displaySmall),
          const SizedBox(height: AppConstants.paddingS),
          Text(copy.subtitle, style: theme.bodyMedium?.copyWith(height: 1.5)),
        ],
      ),
    );
  }
}
