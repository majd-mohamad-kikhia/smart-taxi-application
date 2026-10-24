import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/models/route_point_model.dart';
import 'quote_route_state.dart';

/// The line between pickup and drop-off drawn on the price sheet's map while
/// the customer chooses a car: the street route the server priced the trip
/// on (it comes with the quote), or a straight line when the server had none.
/// Google is never asked from here.
class QuoteRouteCubit extends Cubit<QuoteRouteState> {
  QuoteRouteCubit() : super(const QuoteRouteState());

  void load({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
    List<RoutePointModel> route = const [],
  }) {
    emit(
      QuoteRouteState(
        points: route.length >= 2
            ? route
            : [
                RoutePointModel(fromLat, fromLng),
                RoutePointModel(toLat, toLng),
              ],
        isLoading: false,
      ),
    );
  }
}
