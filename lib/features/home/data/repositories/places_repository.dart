import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/geo/geo_exception.dart';
import '../../../../core/geo/geo_models.dart';
import '../../../../core/geo/geo_remote_data_source.dart';
import '../../../../core/localization/app_strings.dart';
import '../pin_label_resolver.dart';

/// What choosing a place (or submitting a search) came to.
sealed class PlaceOutcome {
  const PlaceOutcome();
}

/// The place became a point. [label] is what to show for it (Google's
/// address when the server sent one — shown, never saved).
class PlaceFound extends PlaceOutcome {
  final String label;
  final double latitude;
  final double longitude;

  /// Our id for the place; sent with the order when the pin stays on it.
  final int aliasId;

  /// Set when the server corrected the search ("تم التصحيح إلى …").
  final String? correctedTo;

  const PlaceFound({
    required this.label,
    required this.latitude,
    required this.longitude,
    required this.aliasId,
    this.correctedTo,
  });

  /// The same place under another title.
  PlaceFound withLabel(String label) => PlaceFound(
    label: label,
    latitude: latitude,
    longitude: longitude,
    aliasId: aliasId,
    correctedTo: correctedTo,
  );
}

/// The server suggests another place: ask "did you mean …?". Yes continues
/// with [aliasId]; no with `forceGoogle`.
class PlaceDidYouMean extends PlaceOutcome {
  final int aliasId;
  final String text;

  const PlaceDidYouMean({required this.aliasId, required this.text});
}

/// Nothing found, or the server could not look (budget used up, too many
/// searches, Google down, no connection): the customer places the pin.
class PlaceNotFound extends PlaceOutcome {
  const PlaceNotFound();
}

/// Place search and pin naming, all through our server (Geo v2) — the app
/// never calls Google's web services itself, and keeps no searched place on
/// the device.
///
/// - **Searching** ([submit]): only when the customer presses the keyboard's
///   search key (or the search icon); the server turns the text into a point.
/// - **Naming a pin** ([addressFor]): see [PinLabelResolver] (25 m reuse).
///
/// Google's address (when the server sends one) is shown and goes with the
/// order; it is never written to the device.
class PlacesRepository {
  /// Shortest query that is sent to the server.
  static const int minQueryLength = 2;

  /// A pin this close to the last one named takes its label.
  static const double reuseRadiusMeters = PinLabelResolver.reuseRadiusMeters;

  /// A pin within this distance of the point the server returned counts as
  /// accepting it; beyond [rejectedMeters] as rejecting it.
  static const double acceptedMeters = 150;
  static const double rejectedMeters = 300;

  final GeoRemoteDataSource _geo;
  final PinLabelResolver _pinLabels;

  CancelToken? _resolveToken;
  CancelToken? _suggestToken;

  PlacesRepository(this._geo, [PinLabelResolver? pinLabels])
    : _pinLabels = pinLabels ?? PinLabelResolver(_geo.reverse);

  /// [query] the way it is compared: trimmed, runs of spaces collapsed to
  /// one, lowercase.
  static String normalizeQuery(String query) =>
      query.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  /// Whether [query] is long enough to be sent to the server.
  static bool isSearchable(String query) =>
      normalizeQuery(query).length >= minQueryLength;

  /// Drops the search and the suggestion call in flight, if any: their
  /// answers are no longer wanted.
  void cancelSearch() {
    _resolveToken?.cancel('no longer wanted');
    cancelSuggest();
  }

  /// Drops the suggestion call in flight, if any.
  void cancelSuggest() {
    _suggestToken?.cancel('no longer wanted');
  }

  /// Up to 5 of our own places matching what is being typed (free: the server
  /// never asks Google for these). A call still in flight is replaced.
  /// Any failure is an empty list — the next keystroke simply asks again;
  /// only a replaced call rethrows, so the caller can ignore its answer.
  Future<List<GeoSuggestionModel>> suggest(String text) async {
    _suggestToken?.cancel('replaced by a newer call');
    final token = _suggestToken = CancelToken();
    try {
      return await _geo.suggest(text.trim(), cancelToken: token);
    } on GeoException catch (e) {
      if (e.isCancelled) rethrow;
      debugPrint('PlacesRepository: could not get suggestions: $e');
      return const [];
    }
  }

  /// The customer submitted [text] (the keyboard's search key, or the search
  /// icon), or answered a "did you mean": [aliasId] continues with the place
  /// the server suggested, [forceGoogle] with Google's own answer.
  Future<PlaceOutcome> submit(
    String text, {
    int? aliasId,
    bool forceGoogle = false,
  }) async {
    _resolveToken?.cancel('replaced by a newer search');
    final token = _resolveToken = CancelToken();
    try {
      final result = await _geo.resolve(
        text.trim(),
        aliasId: aliasId,
        forceGoogle: forceGoogle,
        cancelToken: token,
      );
      switch (result) {
        case GeoResolved():
          return PlaceFound(
            label: _nonEmpty(result.address) ?? result.text,
            latitude: result.lat,
            longitude: result.lng,
            aliasId: result.aliasId,
            correctedTo: result.correctedTo,
          );
        case GeoDidYouMean():
          return PlaceDidYouMean(aliasId: result.aliasId, text: result.text);
        case GeoNotFound():
          return const PlaceNotFound();
      }
    } on GeoException catch (e) {
      if (e.isCancelled) rethrow;
      debugPrint('PlacesRepository: could not resolve a place: $e');
      return const PlaceNotFound();
    }
  }

  /// Tells the server whether the customer kept the resolved point: accepted
  /// when the confirmed pin is within [acceptedMeters] of it, rejected beyond
  /// [rejectedMeters], nothing in between. Returns whether the pin stayed on
  /// the place (so the order may carry its [aliasId]).
  bool reportConfirmed({
    required int aliasId,
    required double resolvedLatitude,
    required double resolvedLongitude,
    required double pinLatitude,
    required double pinLongitude,
  }) {
    final meters = PinLabelResolver.distanceMeters(
      resolvedLatitude,
      resolvedLongitude,
      pinLatitude,
      pinLongitude,
    );
    if (meters <= acceptedMeters) {
      unawaited(_geo.sendFeedback(aliasId: aliasId, accepted: true));
      return true;
    }
    if (meters > rejectedMeters) {
      unawaited(_geo.sendFeedback(aliasId: aliasId, accepted: false));
    }
    return false;
  }

  /// The label under a pin (see [PinLabelResolver]): our server's, or the
  /// neutral wording when there is none (budget reached, Google error,
  /// no connection). Never a failure.
  Future<String?> addressFor(
    double latitude,
    double longitude, {
    String reason = 'unspecified',
  }) async {
    final label = await _pinLabels.resolve(latitude, longitude, reason: reason);
    if (label != null) return label;
    // A debug build says why, so a server problem is seen at once.
    return kDebugMode
        ? '${AppStrings.current.pinLabelNeutral} [${_pinLabels.lastFailure ?? '?'}]'
        : AppStrings.current.pinLabelNeutral;
  }

  /// How many label requests were sent since the app started.
  int get labelRequestCount => _pinLabels.requestCount;

  static String? _nonEmpty(String? text) {
    final t = text?.trim();
    return t == null || t.isEmpty ? null : t;
  }
}
