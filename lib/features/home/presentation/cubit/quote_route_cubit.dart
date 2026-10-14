import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/planned_route_loader.dart';
import 'quote_route_state.dart';

/// Loads the road route for the trip whose prices are on screen, so the
/// customer can see the path they are paying for.
class QuoteRouteCubit extends Cubit<QuoteRouteState> {
  final PlannedRouteLoader _loader;

  QuoteRouteCubit(this._loader) : super(const QuoteRouteState());

  Future<void> load({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    final points = await _loader.load(
      fromLat: fromLat,
      fromLng: fromLng,
      toLat: toLat,
      toLng: toLng,
    );
    if (isClosed) return;
    emit(QuoteRouteState(points: points, isLoading: false));
  }
}
