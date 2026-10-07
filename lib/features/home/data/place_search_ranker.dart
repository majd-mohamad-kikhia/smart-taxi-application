import 'package:geolocator/geolocator.dart';
import 'models/place_suggestion_model.dart';

/// Orders place-search results nearest-first from the customer, without
/// letting a loosely related place beat the one that was asked for.
///
/// A place "matches" when every word the customer typed starts a word of
/// its description (the last, half-typed word included). Matches come
/// before the rest; inside each group the nearest comes first. Arabic
/// spelling variants compare equal (see [_normalize]), so `جامع الروضة`
/// finds `جامع الروضه` and `الروضة`.
class PlaceSearchRanker {
  PlaceSearchRanker._();

  /// Two results of the same description this close (~110 m, in degrees)
  /// are the same place mapped twice (e.g. a node and a building outline).
  static const double _samePlaceDegrees = 0.001;

  /// How many of [places] match [query] (see the class comment) — to tell
  /// whether a search found what was asked for or only loosely related
  /// places.
  static int countMatches(String query, Iterable<PlaceSuggestionModel> places) {
    final queryWords = _words(query);
    return places.where((p) => _matches(queryWords, _words(p.description))).length;
  }

  /// [places] ranked for [query] by distance from ([fromLatitude],
  /// [fromLongitude]), duplicates dropped, at most [limit] kept — each with
  /// its [PlaceSuggestionModel.distanceMeters] filled in.
  static List<PlaceSuggestionModel> rank(
    String query,
    Iterable<PlaceSuggestionModel> places, {
    required double fromLatitude,
    required double fromLongitude,
    int limit = 8,
  }) {
    final queryWords = _words(query);
    final entries = <_Entry>[];
    for (final place in places) {
      if (entries.any((e) => _isSamePlace(e.place, place))) continue;
      entries.add(_Entry(
        place: place.withDistance(Geolocator.distanceBetween(
          fromLatitude,
          fromLongitude,
          place.latitude,
          place.longitude,
        )),
        matches: _matches(queryWords, _words(place.description)),
        position: entries.length,
      ));
    }

    // `List.sort` isn't stable, so equal keys fall back to the order the
    // service gave them.
    entries.sort((a, b) {
      if (a.matches != b.matches) return a.matches ? -1 : 1;
      final byDistance = a.place.distanceMeters!.compareTo(b.place.distanceMeters!);
      return byDistance != 0 ? byDistance : a.position.compareTo(b.position);
    });
    return [for (final e in entries.take(limit)) e.place];
  }

  static bool _isSamePlace(PlaceSuggestionModel a, PlaceSuggestionModel b) {
    return a.description == b.description &&
        (a.latitude - b.latitude).abs() < _samePlaceDegrees &&
        (a.longitude - b.longitude).abs() < _samePlaceDegrees;
  }

  static bool _matches(List<String> queryWords, List<String> placeWords) {
    if (queryWords.isEmpty) return false;
    return queryWords.every((q) => placeWords.any((w) => w.startsWith(q)));
  }

  static final RegExp _separators = RegExp(r'[^\p{L}\p{N}]+', unicode: true);

  /// The words of [text], normalized, without the Arabic article "ال" (so
  /// `الروضة` and `روضة` are the same word).
  static List<String> _words(String text) {
    return [
      for (final word in _normalize(text).split(_separators))
        if (word.isNotEmpty)
          word.startsWith('ال') && word.length > 3 ? word.substring(2) : word,
    ];
  }

  /// Lower-cases, drops Arabic diacritics and tatweel, and folds the
  /// letters people spell interchangeably: أ إ آ → ا, ى → ي, ة → ه,
  /// ؤ → و, ئ → ي.
  static String _normalize(String text) {
    final out = StringBuffer();
    for (final rune in text.toLowerCase().runes) {
      if ((rune >= 0x064B && rune <= 0x065F) || rune == 0x0670 || rune == 0x0640) {
        continue;
      }
      out.writeCharCode(switch (rune) {
        0x0623 || 0x0625 || 0x0622 || 0x0671 => 0x0627,
        0x0649 || 0x0626 => 0x064A,
        0x0629 => 0x0647,
        0x0624 => 0x0648,
        _ => rune,
      });
    }
    return out.toString();
  }
}

class _Entry {
  final PlaceSuggestionModel place;
  final bool matches;
  final int position;

  const _Entry({required this.place, required this.matches, required this.position});
}
