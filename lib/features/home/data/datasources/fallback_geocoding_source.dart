import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/place_suggestion_model.dart';
import '../places_exception.dart';
import 'geocoder_health.dart';
import 'geocoding_source.dart';

/// Asks the [primary] source (Google) and, when it fails, the [fallback]
/// (OpenStreetMap) — so a place search or a pin name still answers when
/// Google refuses the key, runs out of quota or can't be reached.
///
/// Only a failure moves on. An answer of no places is an answer, and a
/// search replaced by a newer one is not a failure either. A [primary] that
/// keeps failing is left alone for a while ([GeocoderHealth]): the fallback
/// answers straight away instead of after the primary's timeout. When both
/// fail, the primary's failure is the one reported.
class FallbackGeocodingSource implements GeocodingSource {
  final GeocodingSource _primary;
  final GeocodingSource _fallback;
  final GeocoderHealth _health;

  FallbackGeocodingSource({
    required GeocodingSource primary,
    required GeocodingSource fallback,
    GeocoderHealth? health,
  }) : _primary = primary,
       _fallback = fallback,
       _health = health ?? GeocoderHealth();

  @override
  Future<List<PlaceSuggestionModel>> search(
    String query, {
    int limit = 8,
    CancelToken? cancelToken,
  }) => _ask(
    'search',
    (source) => source.search(query, limit: limit, cancelToken: cancelToken),
  );

  @override
  Future<String?> reverseGeocode(double latitude, double longitude) =>
      _ask('reverse geocode', (source) => source.reverseGeocode(latitude, longitude));

  Future<T> _ask<T>(
    String what,
    Future<T> Function(GeocodingSource source) request,
  ) async {
    PlacesException? primaryFailure;
    if (_health.isAvailable) {
      try {
        final answer = await request(_primary);
        _health.recordSuccess();
        return answer;
      } on PlacesCancelledException {
        rethrow;
      } on PlacesException catch (e) {
        _health.recordFailure(persistent: e.persistent);
        primaryFailure = e;
        _log('$what: the first source failed (${e.message}), trying OpenStreetMap');
      }
    } else {
      _log(
        '$what: the first source is skipped for '
        '${_health.skippedFor.inSeconds} s more, asking OpenStreetMap',
      );
    }

    try {
      return await request(_fallback);
    } on PlacesCancelledException {
      rethrow;
    } on PlacesException catch (e) {
      _log('$what: OpenStreetMap failed too (${e.message})');
      throw primaryFailure ?? e;
    }
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('[places] $message');
  }
}
