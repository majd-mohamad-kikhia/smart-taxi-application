import 'models/place_suggestion_model.dart';

/// Where the app's customers are: Syria, and Latakia first. Every place
/// search leans on it — Google with a `bounds`, OpenStreetMap with a
/// `viewbox` — and the answers are shown Latakia first, then the rest of
/// Syria, then anywhere else.
abstract final class SyriaRegion {
  /// The box around Syria.
  static const double _syriaSouth = 32.3;
  static const double _syriaWest = 35.6;
  static const double _syriaNorth = 37.4;
  static const double _syriaEast = 42.4;

  /// The box around Latakia (city and its surroundings): a search is biased
  /// to it, so Latakia's places come first.
  static const double latakiaSouth = 35.1;
  static const double latakiaWest = 35.7;
  static const double latakiaNorth = 35.95;
  static const double latakiaEast = 36.3;

  /// 0 for a place in Latakia, 1 for the rest of Syria, 2 for anywhere else:
  /// the order places are shown in (stable within each group).
  static int rank(double latitude, double longitude) {
    bool inside(double south, double west, double north, double east) =>
        latitude >= south &&
        latitude <= north &&
        longitude >= west &&
        longitude <= east;
    if (inside(latakiaSouth, latakiaWest, latakiaNorth, latakiaEast)) return 0;
    if (inside(_syriaSouth, _syriaWest, _syriaNorth, _syriaEast)) return 1;
    return 2;
  }

  /// [places] with Latakia's first, then the rest of Syria, then the others;
  /// the order inside each group is kept.
  static List<PlaceSuggestionModel> latakiaFirst(
    List<PlaceSuggestionModel> places,
  ) {
    final indexed = places.indexed.toList()
      ..sort((a, b) {
        final byRegion = rank(
          a.$2.latitude,
          a.$2.longitude,
        ).compareTo(rank(b.$2.latitude, b.$2.longitude));
        return byRegion != 0 ? byRegion : a.$1.compareTo(b.$1);
      });
    return [for (final entry in indexed) entry.$2];
  }
}
