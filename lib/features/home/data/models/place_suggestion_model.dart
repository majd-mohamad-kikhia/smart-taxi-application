import 'package:equatable/equatable.dart';

/// A single search suggestion shown while searching for a place on the
/// location picker, sourced from Photon (a free, keyless OSM-based
/// geocoder). Carries coordinates directly, since Photon's search
/// results already include them — no separate "place details" round
/// trip needed.
class PlaceSuggestionModel extends Equatable {
  final String description;
  final double latitude;
  final double longitude;

  const PlaceSuggestionModel({
    required this.description,
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [description, latitude, longitude];
}
