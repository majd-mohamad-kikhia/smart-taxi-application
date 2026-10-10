import 'package:equatable/equatable.dart';

/// A single search suggestion shown while searching for a place on the
/// location picker, sourced from Google Places. Carries coordinates
/// directly, since the search results already include them — no separate
/// "place details" round trip needed.
class PlaceSuggestionModel extends Equatable {
  final String description;
  final double latitude;
  final double longitude;

  /// Straight-line distance from the customer, in meters. Set once the
  /// search results are ranked by it; null when the customer's position
  /// isn't known.
  final double? distanceMeters;

  const PlaceSuggestionModel({
    required this.description,
    required this.latitude,
    required this.longitude,
    this.distanceMeters,
  });

  PlaceSuggestionModel withDistance(double meters) => PlaceSuggestionModel(
        description: description,
        latitude: latitude,
        longitude: longitude,
        distanceMeters: meters,
      );

  @override
  List<Object?> get props => [description, latitude, longitude, distanceMeters];
}
