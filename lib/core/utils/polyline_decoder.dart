import '../models/route_point_model.dart';

/// Decodes Google's encoded-polyline format (precision 5), the compact
/// string the Routes API returns for a route's line — several times smaller
/// than the same line as GeoJSON.
class PolylineDecoder {
  PolylineDecoder._();

  static const double _precision = 1e5;

  static List<RoutePointModel> decode(String encoded) {
    final points = <RoutePointModel>[];
    final length = encoded.length;
    var index = 0;
    var lat = 0;
    var lng = 0;

    while (index < length) {
      var shift = 0;
      var result = 0;
      int byte;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20 && index < length);
      lat += (result & 1) != 0 ? ~(result >> 1) : result >> 1;
      // A truncated string ends mid-pair: drop the half point.
      if (index >= length) break;

      shift = 0;
      result = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20 && index < length);
      lng += (result & 1) != 0 ? ~(result >> 1) : result >> 1;

      points.add(RoutePointModel(lat / _precision, lng / _precision));
    }
    return points;
  }
}
