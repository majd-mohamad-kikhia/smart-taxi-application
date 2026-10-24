import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/features/home/data/models/ride_quote_model.dart';
import 'package:mshoar/features/home/presentation/cubit/quote_route_cubit.dart';

// Google's documented example: 3 points.
const _polyline = '_p~iF~ps|U_ulLnnqC_mqNvxq`@';

void main() {
  test('without a street route the sheet draws a straight line', () {
    final cubit = QuoteRouteCubit()
      ..load(fromLat: 35.52, fromLng: 35.79, toLat: 35.58, toLng: 35.83);

    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.points, hasLength(2));
    expect(cubit.state.points.first.lat, 35.52);
    expect(cubit.state.points.last.lng, 35.83);
    cubit.close();
  });

  test('the street route that came with the prices is drawn as it is', () {
    final quote = RideQuoteModel.fromJson({
      'distance_km': 3.01,
      'route_polyline': _polyline,
      'vehicle_types': [],
    });
    final cubit = QuoteRouteCubit()
      ..load(
        fromLat: 35.52,
        fromLng: 35.79,
        toLat: 35.58,
        toLng: 35.83,
        route: quote.route,
      );

    expect(cubit.state.points, hasLength(3));
    expect(cubit.state.points.first.lat, closeTo(38.5, 0.001));
    cubit.close();
  });

  test('a null route_polyline gives no route', () {
    final quote = RideQuoteModel.fromJson({
      'distance_km': 3.01,
      'route_polyline': null,
      'vehicle_types': [],
    });
    expect(quote.route, isEmpty);
  });
}
