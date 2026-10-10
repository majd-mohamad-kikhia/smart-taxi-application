import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mshoar/core/services/current_location_service.dart';
import 'package:mshoar/features/home/data/models/place_suggestion_model.dart';
import 'package:mshoar/features/home/data/repositories/places_repository.dart';
import 'package:mshoar/features/home/presentation/cubit/map_pick_cubit.dart';
import 'package:mshoar/features/home/presentation/cubit/map_pick_state.dart';

class _FakePlaces extends Fake implements PlacesRepository {
  int lookups = 0;

  @override
  Future<String?> addressFor(double latitude, double longitude) async {
    lookups++;
    return 'شارع القدس، الدباغة';
  }
}

class _FakeLocation extends CurrentLocationService {
  @override
  Future<Position?> getPositionIfAllowed() async => null;
}

const _place = PlaceSuggestionModel(
  description: 'بروستد القصور، اللاذقية',
  latitude: 35.5174673,
  longitude: 35.7774104,
);

void main() {
  late _FakePlaces places;
  late MapPickCubit cubit;

  setUp(() {
    places = _FakePlaces();
    cubit = MapPickCubit(places, _FakeLocation());
  });

  tearDown(() => cubit.close());

  test('a chosen search result keeps its own name when the map settles on it', () async {
    cubit.enter(PickTarget.from);
    await Future<void>.delayed(Duration.zero);
    places.lookups = 0;

    cubit.selectSuggestion(_place);
    // The camera animates to the place: it moves, then goes idle on it.
    cubit.onCameraMove(35.5170, 35.7770);
    cubit.onCameraIdle(_place.latitude, _place.longitude);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.address, 'بروستد القصور، اللاذقية');
    expect(cubit.state.isResolving, isFalse);
    expect(places.lookups, 0, reason: 'no lookup that could name the street instead');
  });

  test('dragging the pin off the chosen place names what is under it', () async {
    cubit.enter(PickTarget.from);
    cubit.selectSuggestion(_place);
    cubit.onCameraIdle(_place.latitude, _place.longitude);
    await Future<void>.delayed(Duration.zero);
    places.lookups = 0;

    cubit.onCameraMove(35.5200, 35.7800);
    cubit.onCameraIdle(35.5200, 35.7800);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.address, 'شارع القدس، الدباغة');
    expect(places.lookups, 1);
  });
}
