import 'package:equatable/equatable.dart';
import '../../../../core/models/route_point_model.dart';

/// The road line between pickup and drop-off drawn on the price sheet's map.
/// [points] stays empty while [isLoading] and when no route could be found —
/// the map then shows only the two pins.
class QuoteRouteState extends Equatable {
  final List<RoutePointModel> points;
  final bool isLoading;

  const QuoteRouteState({this.points = const [], this.isLoading = true});

  @override
  List<Object?> get props => [points, isLoading];
}
