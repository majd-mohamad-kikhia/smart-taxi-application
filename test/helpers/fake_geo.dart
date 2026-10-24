import 'package:dio/dio.dart';
import 'package:mshoar/core/geo/geo_exception.dart';
import 'package:mshoar/core/geo/geo_models.dart';
import 'package:mshoar/core/geo/geo_remote_data_source.dart';
import 'package:mshoar/core/network/api_endpoints.dart';

/// Our Geo v2 endpoints played in memory: no network, no Google, no real
/// server. Each call is recorded; each answer is what the test sets.
class FakeGeo extends GeoRemoteDataSource {
  FakeGeo() : super(Dio(), const ApiEndpoints());

  List<GeoSuggestionModel> suggestions = const [];
  GeoResolveResult resolveResult = const GeoNotFound();
  String? reverseLabel = 'شارع القدس، الدباغة';
  GeoRouteQuoteModel? quote;

  /// Set to make the call fail with this.
  GeoException? suggestFailure;
  GeoException? resolveFailure;
  GeoException? reverseFailure;
  GeoException? quoteFailure;

  final List<String> suggested = [];
  final List<({String q, int? aliasId, bool forceGoogle})> resolved = [];
  final List<({int aliasId, bool accepted})> feedback = [];
  final List<({double lat, double lng})> reversed = [];
  final List<String> quoteKeys = [];

  @override
  Future<List<GeoSuggestionModel>> suggest(
    String query, {
    CancelToken? cancelToken,
  }) async {
    suggested.add(query);
    final failure = suggestFailure;
    if (failure != null) throw failure;
    return suggestions;
  }

  @override
  Future<GeoResolveResult> resolve(
    String query, {
    int? aliasId,
    bool forceGoogle = false,
    CancelToken? cancelToken,
  }) async {
    resolved.add((q: query, aliasId: aliasId, forceGoogle: forceGoogle));
    final failure = resolveFailure;
    if (failure != null) throw failure;
    return resolveResult;
  }

  @override
  Future<void> sendFeedback({
    required int aliasId,
    required bool accepted,
  }) async {
    feedback.add((aliasId: aliasId, accepted: accepted));
  }

  @override
  Future<String?> reverse(double lat, double lng) async {
    reversed.add((lat: lat, lng: lng));
    final failure = reverseFailure;
    if (failure != null) throw failure;
    return reverseLabel;
  }

  @override
  Future<GeoRouteQuoteModel> routeQuote({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
    required String idempotencyKey,
    int? vehicleTypeId,
    double? fareEst,
  }) async {
    quoteKeys.add(idempotencyKey);
    final failure = quoteFailure;
    if (failure != null) throw failure;
    return quote ?? const GeoRouteQuoteModel(fare: 800, needsReconfirm: false);
  }
}
