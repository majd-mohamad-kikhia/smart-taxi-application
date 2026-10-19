import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mshoar/core/services/current_location_service.dart';
import 'package:mshoar/features/home/data/models/place_suggestion_model.dart';
import 'package:mshoar/features/home/data/repositories/places_repository.dart';
import 'package:mshoar/features/home/presentation/cubit/map_pick_cubit.dart';
import 'package:mshoar/features/home/presentation/cubit/map_pick_state.dart';

class _FakePlaces extends Fake implements PlacesRepository {
  int lookups = 0;
  final List<PlaceSuggestionModel> remembered = [];
  List<PlaceSuggestionModel> recent = const [];

  @override
  Future<void> remember(PlaceSuggestionModel place) async => remembered.add(place);

  @override
  Future<List<PlaceSuggestionModel>> recentPlaces({
    String query = '',
    double? nearLatitude,
    double? nearLongitude,
  }) async => recent;

  PlacesException? searchFailure;
  List<PlaceSuggestionModel> found = const [];

  @override
  Future<List<PlaceSuggestionModel>> search(
    String query, {
    double? nearLatitude,
    double? nearLongitude,
  }) async {
    final failure = searchFailure;
    if (failure != null) throw failure;
    return [...recent, ...found];
  }

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

  test(
    'a chosen search result keeps its own name when the map settles on it',
    () async {
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
      expect(
        places.lookups,
        0,
        reason: 'no lookup that could name the street instead',
      );
    },
  );

  test(
    'the controls hide while the map moves and come back when it settles',
    () async {
      cubit.enter(PickTarget.from);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.isDragging, isFalse);

      cubit.onCameraMoveStarted();
      expect(cubit.state.isDragging, isTrue);
      cubit.onCameraMove(35.52, 35.78);
      expect(cubit.state.isDragging, isTrue);

      cubit.onCameraIdle(35.52, 35.78);
      expect(cubit.state.isDragging, isFalse);
    },
  );

  test('outside the pin mode a moving map hides nothing', () {
    cubit.onCameraMoveStarted();
    expect(cubit.state.isDragging, isFalse);
  });

  test('choosing a search result remembers it', () async {
    cubit.enter(PickTarget.from);

    cubit.selectSuggestion(_place);
    await Future<void>.delayed(Duration.zero);

    expect(places.remembered, [_place]);
  });

  test('an empty search box lists the recent places', () async {
    places.recent = [_place.asRecent()];
    cubit.enter(PickTarget.from);

    cubit.search('');
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.suggestions, [_place.asRecent()]);
    expect(cubit.state.isSearching, isFalse);
  });

  test('typing lists the matching recent places before Google answers', () async {
    places.recent = [_place.asRecent()];
    cubit.enter(PickTarget.from);

    cubit.search('بروستد');
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.suggestions, [_place.asRecent()]);
  });

  test('typing something no recent place matches keeps the list as it was', () async {
    cubit.enter(PickTarget.from);
    places.recent = [_place.asRecent()];
    cubit.search('');
    await Future<void>.delayed(Duration.zero);
    places.recent = const [];

    cubit.search('xyz');
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.suggestions, [_place.asRecent()]);
  });

  test('Google failing still leaves the recent places and the error', () async {
    places
      ..recent = [_place.asRecent()]
      ..searchFailure = const PlacesException('down');
    cubit.enter(PickTarget.from);

    cubit.search('بروستد');
    await Future<void>.delayed(const Duration(milliseconds: 500));

    expect(cubit.state.suggestions, [_place.asRecent()]);
    expect(cubit.state.searchError, 'down');
    expect(cubit.state.isSearching, isFalse);
  });

  test(
    'dragging the pin off the chosen place names what is under it',
    () async {
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
    },
  );
}
