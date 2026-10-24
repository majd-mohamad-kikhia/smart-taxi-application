import 'package:equatable/equatable.dart';
import '../models/route_point_model.dart';
import '../utils/polyline_decoder.dart';

/// One typing suggestion (`GET /api/v2/geo/suggest`).
class GeoSuggestionModel extends Equatable {
  final int aliasId;
  final String text;

  /// Null when the coordinates expired ([hasCoords] false): tapping it calls
  /// resolve with [aliasId].
  final double? lat;
  final double? lng;

  const GeoSuggestionModel({
    required this.aliasId,
    required this.text,
    this.lat,
    this.lng,
  });

  factory GeoSuggestionModel.fromJson(Map<String, dynamic> json) {
    final lat = (json['lat'] as num?)?.toDouble();
    final lng = (json['lng'] as num?)?.toDouble();
    final hasCoords =
        json['has_coords'] as bool? ?? (lat != null && lng != null);
    return GeoSuggestionModel(
      aliasId: (json['alias_id'] as num).toInt(),
      text: json['text'] as String,
      lat: hasCoords ? lat : null,
      lng: hasCoords ? lng : null,
    );
  }

  bool get hasCoords => lat != null && lng != null;

  @override
  List<Object?> get props => [aliasId, text, lat, lng];
}

/// The answer of `POST /api/v2/geo/resolve`.
sealed class GeoResolveResult {
  const GeoResolveResult();

  factory GeoResolveResult.fromJson(Map<String, dynamic> json) {
    switch (json['status']) {
      case 'ok':
        return GeoResolved(
          aliasId: (json['alias_id'] as num).toInt(),
          text: json['text'] as String,
          lat: (json['lat'] as num).toDouble(),
          lng: (json['lng'] as num).toDouble(),
          address: json['address'] as String?,
          correctedTo: json['corrected_to'] as String?,
        );
      case 'did_you_mean':
        return GeoDidYouMean(
          aliasId: (json['alias_id'] as num).toInt(),
          text: json['text'] as String,
        );
      default:
        return const GeoNotFound();
    }
  }
}

/// The text became a point. [address] is Google's: shown, never saved.
class GeoResolved extends GeoResolveResult {
  final int aliasId;
  final String text;
  final double lat;
  final double lng;
  final String? address;
  final String? correctedTo;

  const GeoResolved({
    required this.aliasId,
    required this.text,
    required this.lat,
    required this.lng,
    this.address,
    this.correctedTo,
  });
}

/// The server suggests another place: ask "did you mean …?".
class GeoDidYouMean extends GeoResolveResult {
  final int aliasId;
  final String text;

  const GeoDidYouMean({required this.aliasId, required this.text});
}

class GeoNotFound extends GeoResolveResult {
  const GeoNotFound();
}

/// The answer of `POST /api/v2/geo/route-quote`.
class GeoRouteQuoteModel extends Equatable {
  final double fare;

  /// The final fare differs from the one shown before by more than 15 %:
  /// the customer confirms again.
  final bool needsReconfirm;

  /// Only with `method: routes`; empty otherwise. Drawn, never saved.
  final List<RoutePointModel> route;

  const GeoRouteQuoteModel({
    required this.fare,
    required this.needsReconfirm,
    this.route = const [],
  });

  factory GeoRouteQuoteModel.fromJson(Map<String, dynamic> json) {
    final polyline = json['polyline'] as String?;
    return GeoRouteQuoteModel(
      fare: (json['fare'] as num).toDouble(),
      needsReconfirm: json['needs_reconfirm'] as bool? ?? false,
      route: polyline == null || polyline.isEmpty
          ? const []
          : PolylineDecoder.decode(polyline),
    );
  }

  @override
  List<Object?> get props => [fare, needsReconfirm, route];
}
