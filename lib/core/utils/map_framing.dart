import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// The smallest area a map is framed to, in degrees (about 440 m): two pins
/// on top of each other must not zoom the map in to the rooftops.
const double minFramingSpanDegrees = 0.004;

/// The box that holds every point in [points] (at least one), grown to
/// [minSpan] degrees on each axis so a handful of near points still gives a
/// sensible zoom.
LatLngBounds framingBounds(
  Iterable<LatLng> points, {
  double minSpan = minFramingSpanDegrees,
}) {
  var south = double.infinity, north = -double.infinity;
  var west = double.infinity, east = -double.infinity;
  for (final p in points) {
    south = math.min(south, p.latitude);
    north = math.max(north, p.latitude);
    west = math.min(west, p.longitude);
    east = math.max(east, p.longitude);
  }
  if (north - south < minSpan) {
    final pad = (minSpan - (north - south)) / 2;
    south -= pad;
    north += pad;
  }
  if (east - west < minSpan) {
    final pad = (minSpan - (east - west)) / 2;
    west -= pad;
    east += pad;
  }
  return LatLngBounds(
    southwest: LatLng(south, west),
    northeast: LatLng(north, east),
  );
}
