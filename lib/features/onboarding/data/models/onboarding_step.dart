/// The onboarding screens, in the order they are shown. Each one is a photo
/// with its own text (`OnboardingStepText`).
enum OnboardingStep {
  bookFast('assets/images/onboarding/onboarding_book_fast.jpg'),
  liveTracking('assets/images/onboarding/onboarding_live_tracking.jpg'),
  rideOptions('assets/images/onboarding/onboarding_ride_options.jpg'),
  safetyComfort('assets/images/onboarding/onboarding_safety_comfort.jpg');

  final String imageAsset;

  const OnboardingStep(this.imageAsset);

  static int get count => values.length;
}
