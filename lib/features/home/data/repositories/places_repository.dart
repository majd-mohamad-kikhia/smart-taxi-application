import 'dart:collection';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../datasources/geocoding_source.dart';
import '../models/place_suggestion_model.dart';
import '../place_search_ranker.dart';
import '../places_exception.dart';
import '../syria_region.dart';

export '../places_exception.dart';

/// Place search and pin naming, both on Google Geocoding — the repository
/// exists to send as few paid requests as it can:
///
/// - **Search** runs only for a query of at least [minQueryLength] letters;
///   the query is normalized (trimmed, spaces collapsed, lowercase) and that
///   is also the key of an in-memory LRU cache, so asking again costs
///   nothing. Only one search is ever in flight: a different query cancels
///   the earlier one, and the same query joins it.
/// - **Naming a pin** remembers recent spots in an LRU cache keyed by the
///   coordinates rounded to 4 decimals (~11 m), and a new spot within
///   [reuseRadiusMeters] of one named recently takes that label — a pin
///   dragged a few meters, or a GPS fix that drifted, costs nothing.
///
/// Everything is kept in memory for the session only; Google's results are
/// never written to storage. In debug builds each call is logged (type,
/// trigger, cache hit or miss) — never the key or the request address.
class PlacesRepository {
  /// Shortest query that is sent to Google.
  static const int minQueryLength = 3;

  /// A pin this close to the last one named takes its label.
  static const double reuseRadiusMeters = 25;

  static const int _maxSuggestions = 8;
  static const int _searchCacheSize = 50;
  static const int _reverseCacheSize = 100;

  final GeocodingSource _google;

  /// Searches already answered, by normalized query, least recently used
  /// first. They hold Google's order; the ranking by distance is applied on
  /// the way out, since the customer may have moved.
  final LinkedHashMap<String, List<PlaceSuggestionModel>> _searchCache =
      LinkedHashMap();

  /// The search being asked of Google, with what is needed to join or cancel
  /// it.
  String? _inFlightKey;
  Future<List<PlaceSuggestionModel>>? _inFlight;
  CancelToken? _inFlightToken;

  /// Spots named recently, by rounded coordinates, least recently used first.
  final LinkedHashMap<String, _NamedSpot> _reverseCache = LinkedHashMap();
  final Map<String, Future<String?>> _reverseInFlight = {};

  int _googleCalls = 0;

  PlacesRepository(this._google);

  /// How many requests were sent to Google since the app started.
  int get googleCallCount => _googleCalls;

  /// [query] the way it is compared and cached: trimmed, runs of spaces
  /// collapsed to one, lowercase.
  static String normalizeQuery(String query) =>
      query.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  /// Whether [query] is long enough to be searched.
  static bool isSearchable(String query) =>
      normalizeQuery(query).length >= minQueryLength;

  /// Places for [query]: Latakia's first, then the rest of Syria, then the
  /// others; inside each group, those that match what was typed come before
  /// loosely related ones, each by distance from ([nearLatitude],
  /// [nearLongitude]) — pass the customer's own position, not the map's
  /// center, so "nearest to me" means the customer. Without a position
  /// there is nothing to rank by and Google's own order is kept.
  ///
  /// A query shorter than [minQueryLength] asks nothing and finds nothing.
  /// [reason] says what asked, for the debug log.
  ///
  /// Throws [PlacesException] when Google can't answer, and
  /// [PlacesCancelledException] when a different search replaced this one
  /// before it came back.
  Future<List<PlaceSuggestionModel>> search(
    String query, {
    double? nearLatitude,
    double? nearLongitude,
    String reason = 'submit',
  }) async {
    final key = normalizeQuery(query);
    if (key.length < minQueryLength) return const [];

    final cached = _searchCache.remove(key);
    if (cached != null) {
      _searchCache[key] = cached;
      _log('forward', reason, 'cache hit');
      return _rank(key, cached, nearLatitude, nearLongitude);
    }

    final running = _inFlight;
    if (running != null && _inFlightKey == key) {
      _log('forward', reason, 'joined the search in flight');
      return _rank(key, await running, nearLatitude, nearLongitude);
    }

    // A different search replaces the one in flight.
    _inFlightToken?.cancel('replaced by a newer search');
    final token = CancelToken();
    final request = _google.search(
      key,
      limit: _maxSuggestions,
      cancelToken: token,
    );
    _inFlightKey = key;
    _inFlight = request;
    _inFlightToken = token;
    _googleCalls++;
    _log('forward', reason, 'miss, asking Google');
    try {
      final found = await request;
      _searchCache[key] = found;
      while (_searchCache.length > _searchCacheSize) {
        _searchCache.remove(_searchCache.keys.first);
      }
      return _rank(key, found, nearLatitude, nearLongitude);
    } finally {
      if (identical(_inFlightToken, token)) {
        _inFlightKey = null;
        _inFlight = null;
        _inFlightToken = null;
      }
    }
  }

  /// Drops the search in flight, if any: its answer is no longer wanted
  /// (the box was cleared, or something else was chosen).
  void cancelSearch() {
    _inFlightToken?.cancel('no longer wanted');
  }

  List<PlaceSuggestionModel> _rank(
    String query,
    List<PlaceSuggestionModel> found,
    double? nearLatitude,
    double? nearLongitude,
  ) {
    return SyriaRegion.latakiaFirst(
      nearLatitude == null || nearLongitude == null
          ? found
          : PlaceSearchRanker.rank(
              query,
              found,
              fromLatitude: nearLatitude,
              fromLongitude: nearLongitude,
              limit: _maxSuggestions,
            ),
    );
  }

  /// Best-effort reverse geocode for a dropped/dragged pin — this fires
  /// automatically as the user moves the map, not from an explicit
  /// action, so a failure here just leaves the address unset rather than
  /// surfacing an error; `PickedLocationModel.displayLabel` already
  /// falls back to raw coordinates when the address is null.
  ///
  /// A spot named recently comes from the cache, and one within
  /// [reuseRadiusMeters] of such a spot (the nearest, if several) takes its
  /// label: neither sends a request. [reason] says what asked, for the debug
  /// log.
  Future<String?> addressFor(
    double latitude,
    double longitude, {
    String reason = 'unspecified',
  }) async {
    final key =
        '${latitude.toStringAsFixed(4)},${longitude.toStringAsFixed(4)}';
    final cached = _reverseCache.remove(key);
    if (cached != null) {
      _reverseCache[key] = cached;
      _log('reverse', reason, 'cache hit');
      return cached.label;
    }

    final near = _nearestNamedSpot(latitude, longitude);
    if (near != null) {
      _reverseCache.remove(near.key);
      _reverseCache[near.key] = near.spot;
      _log('reverse', reason, 'reused a label named within 25 m');
      return near.spot.label;
    }

    final running = _reverseInFlight[key];
    if (running != null) {
      _log('reverse', reason, 'joined the lookup in flight');
      return running;
    }

    _googleCalls++;
    _log('reverse', reason, 'miss, asking Google');
    final lookup = _lookUp(key, latitude, longitude);
    _reverseInFlight[key] = lookup;
    try {
      return await lookup;
    } finally {
      _reverseInFlight.remove(key);
    }
  }

  Future<String?> _lookUp(String key, double latitude, double longitude) async {
    try {
      final label = await _google.reverseGeocode(latitude, longitude);
      if (label != null) {
        _reverseCache[key] = _NamedSpot(latitude, longitude, label);
        while (_reverseCache.length > _reverseCacheSize) {
          _reverseCache.remove(_reverseCache.keys.first);
        }
      }
      return label;
    } on PlacesException catch (e) {
      debugPrint('PlacesRepository: could not name the pin: $e');
      return null;
    }
  }

  /// The recently named spot nearest to ([latitude], [longitude]) that is
  /// within [reuseRadiusMeters], or null when there is none.
  ({String key, _NamedSpot spot})? _nearestNamedSpot(
    double latitude,
    double longitude,
  ) {
    ({String key, _NamedSpot spot})? best;
    var bestDistance = reuseRadiusMeters;
    for (final entry in _reverseCache.entries) {
      final spot = entry.value;
      final d = distanceMeters(spot.lat, spot.lng, latitude, longitude);
      if (d <= bestDistance) {
        bestDistance = d;
        best = (key: entry.key, spot: spot);
      }
    }
    return best;
  }

  /// Straight-line distance between two points in meters (haversine).
  @visibleForTesting
  static double distanceMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadius = 6371000.0;
    double radians(double degrees) => degrees * math.pi / 180;
    final dLat = radians(lat2 - lat1);
    final dLng = radians(lng2 - lng1);
    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(radians(lat1)) *
            math.cos(radians(lat2)) *
            math.pow(math.sin(dLng / 2), 2);
    return 2 * earthRadius * math.asin(math.sqrt(a));
  }

  void _log(String type, String reason, String outcome) {
    if (!kDebugMode) return;
    debugPrint(
      '[places] $type | $reason | $outcome | requests to Google: $_googleCalls',
    );
  }
}

/// A spot that was named: where it is and what it was called.
class _NamedSpot {
  final double lat;
  final double lng;
  final String label;

  const _NamedSpot(this.lat, this.lng, this.label);
}
