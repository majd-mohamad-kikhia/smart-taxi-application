/// The onboarding screens, in the order they are shown. Each one is a photo
/// with its own text (`OnboardingStepText`).
enum OnboardingStep {
  bookFast('assets/images/onboarding/onboarding_book_fast.jpg'),
  liveTracking('assets/images/onboarding/onboarding_live_tracking.jpg'),
  rideOptions('assets/images/onboarding/onboarding_ride_options.jpg'),
  callCenter('assets/images/onboarding/onboarding_call_center.jpg');

  final String imageAsset;

  const OnboardingStep(this.imageAsset);

  static int get count => values.length;
}
