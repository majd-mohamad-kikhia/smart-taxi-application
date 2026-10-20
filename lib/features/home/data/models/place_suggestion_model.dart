import 'package:equatable/equatable.dart';

/// A single search suggestion shown after the customer submits a search for
/// a place on the location picker, from Google Geocoding (or OpenStreetMap
/// when Google fails). Carries coordinates directly, since the search results
/// already include them — no separate "place details" round trip needed.
class PlaceSuggestionModel extends Equatable {
  final String description;
  final double latitude;
  final double longitude;

  /// Straight-line distance from the customer, in meters. Set once the
  /// search results are ranked by it; null when the customer's position
  /// isn't known.
  final double? distanceMeters;

  /// The customer picked this place before: it comes from the device, not
  /// from the search that is running.
  final bool isRecent;

  const PlaceSuggestionModel({
    required this.description,
    required this.latitude,
    required this.longitude,
    this.distanceMeters,
    this.isRecent = false,
  });

  /// Reads a place saved by [toJson]. Throws when a field is missing or of
  /// the wrong type, so the caller can drop a corrupt entry.
  factory PlaceSuggestionModel.fromJson(Map<String, dynamic> json) {
    return PlaceSuggestionModel(
      description: json['description'] as String,
      latitude: (json['lat'] as num).toDouble(),
      longitude: (json['lng'] as num).toDouble(),
      isRecent: true,
    );
  }

  /// Only what is worth keeping: the distance is recomputed from where the
  /// customer is next time, and the recent flag is set when reading back.
  Map<String, dynamic> toJson() => {
        'description': description,
        'lat': latitude,
        'lng': longitude,
      };

  PlaceSuggestionModel withDistance(double meters) => PlaceSuggestionModel(
        description: description,
        latitude: latitude,
        longitude: longitude,
        distanceMeters: meters,
        isRecent: isRecent,
      );

  PlaceSuggestionModel asRecent() => PlaceSuggestionModel(
        description: description,
        latitude: latitude,
        longitude: longitude,
        distanceMeters: distanceMeters,
        isRecent: true,
      );

  @override
  List<Object?> get props => [
        description,
        latitude,
        longitude,
        distanceMeters,
        isRecent,
      ];
}
