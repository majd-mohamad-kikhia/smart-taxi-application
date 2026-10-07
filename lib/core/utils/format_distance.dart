import '../l10n/generated/app_localizations.dart';

/// A road or straight-line distance as the customer reads it: whole meters
/// under a kilometer ("437 m"), kilometers with one decimal above it
/// ("2.3 km"). Latin digits in both languages, like the rest of the app's
/// numbers.
String formatDistance(AppLocalizations l10n, num meters) {
  // The same step as `TripEtaModel.metersThreshold`.
  if (meters < 1000) return l10n.distanceMetersShort('${meters.round()}');
  return l10n.distanceKm((meters / 1000).toStringAsFixed(1));
}
