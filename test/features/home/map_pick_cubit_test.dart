import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mshoar/core/localization/app_strings.dart';
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

  final List<String> lookupReasons = [];
  String? label = 'شارع القدس، الدباغة';

  final List<String> searched = [];
  List<PlaceSuggestionModel> found = const [];
  Object? searchFailure;
  Completer<List<PlaceSuggestionModel>>? searchGate;
  int cancels = 0;

  @override
  Future<String?> addressFor(
    double latitude,
    double longitude, {
    String reason = 'unspecified',
  }) async {
    lookups++;
    lookupReasons.add(reason);
    return label;
  }

  @override
  Future<List<PlaceSuggestionModel>> search(
    String query, {
    double? nearLatitude,
    double? nearLongitude,
    String reason = 'submit',
  }) async {
    searched.add(query);
    final gate = searchGate;
    if (gate != null) return gate.future;
    final failure = searchFailure;
    if (failure != null) throw failure;
    return found;
  }

  @override
  void cancelSearch() => cancels++;
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

    cubit.queryChanged('');
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.suggestions, [_place.asRecent()]);
    expect(cubit.state.isSearching, isFalse);
  });

  test('typing lists the matching recent places without asking Google', () async {
    places.recent = [_place.asRecent()];
    cubit.enter(PickTarget.from);

    cubit.queryChanged('بروستد');
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.suggestions, [_place.asRecent()]);
    expect(places.searched, isEmpty);
  });

  test('typing something no recent place matches keeps the list as it was', () async {
    cubit.enter(PickTarget.from);
    places.recent = [_place.asRecent()];
    cubit.queryChanged('');
    await Future<void>.delayed(Duration.zero);
    places.recent = const [];

    cubit.queryChanged('xyz');
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.suggestions, [_place.asRecent()]);
  });

  test('Google failing still leaves the recent places and the error', () async {
    places
      ..recent = [_place.asRecent()]
      ..searchFailure = const PlacesException('down');
    cubit.enter(PickTarget.from);

    await cubit.submitSearch('بروستد');

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

  group('searching', () {
    test('nothing is searched while the customer types', () async {
      cubit.enter(PickTarget.to);
      cubit.queryChanged('م');
      cubit.queryChanged('مط');
      cubit.queryChanged('مطا');
      cubit.queryChanged('مطار');
      await Future<void>.delayed(const Duration(milliseconds: 700));

      expect(places.searched, isEmpty);
      expect(cubit.state.isSearching, isFalse);
    });

    test('submitting runs one search, with the query normalized', () async {
      places.found = [_place];
      cubit.enter(PickTarget.to);

      await cubit.submitSearch('  Airport   ROAD ');

      expect(places.searched, ['airport road']);
      expect(cubit.state.suggestions, [_place]);
      expect(cubit.state.isSearching, isFalse);
      expect(cubit.state.searchError, isNull);
    });

    test(
      'an answer with no places says so instead of staying silent',
      () async {
        places.found = const [];
        cubit.enter(PickTarget.to);

        await cubit.submitSearch('مطار');

        expect(cubit.state.suggestions, isEmpty);
        expect(cubit.state.searchError, AppStrings.current.placesNoResults);
        expect(cubit.state.isSearching, isFalse);

        // A later answer with places clears the message.
        places.found = [_place];
        await cubit.submitSearch('مطار الدولي');
        expect(cubit.state.searchError, isNull);
        expect(cubit.state.suggestions, [_place]);
      },
    );

    test('under 3 letters asks nothing and says to type more', () async {
      places.found = [_place];
      cubit.enter(PickTarget.to);
      await cubit.submitSearch('مطار');
      expect(cubit.state.suggestions, isNotEmpty);

      await cubit.submitSearch('مط');

      expect(places.searched, ['مطار']);
      expect(cubit.state.suggestions, isEmpty);
      expect(cubit.state.searchError, AppStrings.current.searchMinChars);
    });

    test(
      'submitting the same query again while its answer is shown asks nothing',
      () async {
        places.found = [_place];
        cubit.enter(PickTarget.to);

        await cubit.submitSearch('مطار');
        await cubit.submitSearch(' مطار ');

        expect(places.searched, ['مطار']);
      },
    );

    test(
      'after a failure or an empty answer the same query is tried again',
      () async {
        cubit.enter(PickTarget.to);
        places.searchFailure = const PlacesException('down');
        await cubit.submitSearch('مطار');
        expect(cubit.state.searchError, 'down');

        places.searchFailure = null;
        places.found = [_place];
        await cubit.submitSearch('مطار');

        expect(places.searched, ['مطار', 'مطار']);
        expect(cubit.state.suggestions, [_place]);
        expect(cubit.state.searchError, isNull);
      },
    );

    test('an answer for an older query never replaces the newer one', () async {
      cubit.enter(PickTarget.to);
      final slow = places.searchGate = Completer<List<PlaceSuggestionModel>>();
      final first = cubit.submitSearch('مطار');
      await Future<void>.delayed(Duration.zero);

      places.searchGate = null;
      places.found = const [];
      await cubit.submitSearch('محطة');
      slow.complete([_place]);
      await first;

      expect(cubit.state.suggestions, isEmpty);
      expect(cubit.state.isSearching, isFalse);
    });

    test('a search replaced by a newer one is not an error', () async {
      cubit.enter(PickTarget.to);
      places.searchFailure = const PlacesCancelledException();

      await cubit.submitSearch('مطار');

      expect(cubit.state.searchError, isNull);
    });

    test(
      'emptying the box clears the results and drops a search on its way',
      () async {
        places.found = [_place];
        cubit.enter(PickTarget.to);
        await cubit.submitSearch('مطار');
        places.cancels = 0;

        cubit.queryChanged('');

        expect(cubit.state.suggestions, isEmpty);
        expect(places.cancels, 1);
      },
    );
  });

  group('coming in through the search box', () {
    test('the map\'s center is not named at once', () async {
      cubit.enter(PickTarget.to, autofocusSearch: true);
      await Future<void>.delayed(Duration.zero);

      expect(places.lookups, 0);
      expect(cubit.state.address, isNull);
      expect(cubit.state.isResolving, isFalse);
      expect(cubit.state.addressDeferred, isTrue);
      expect(cubit.state.canConfirm, isTrue);
    });

    test(
      'without the search box the center is named at once, as before',
      () async {
        cubit.enter(PickTarget.to);
        await Future<void>.delayed(Duration.zero);

        expect(places.lookups, 1);
        expect(places.lookupReasons, ['pick mode opened']);
        expect(cubit.state.addressDeferred, isFalse);
      },
    );

    test(
      'the map settling by itself (keyboard, resize) names nothing',
      () async {
        cubit.enter(PickTarget.to, autofocusSearch: true);

        cubit.onCameraIdle(35.5, 35.78);
        await Future<void>.delayed(Duration.zero);

        expect(places.lookups, 0);
        expect(cubit.state.addressDeferred, isTrue);
      },
    );

    test('dragging the map names the spot it settles on', () async {
      cubit.enter(PickTarget.to, autofocusSearch: true);

      cubit.onCameraMoveStarted();
      cubit.onCameraMove(35.51, 35.79);
      cubit.onCameraIdle(35.51, 35.79);
      await Future<void>.delayed(Duration.zero);

      expect(places.lookups, 1);
      expect(places.lookupReasons, ['camera idle']);
      expect(cubit.state.address, 'شارع القدس، الدباغة');
      expect(cubit.state.addressDeferred, isFalse);
    });

    test('confirming names the spot first, then hands it back', () async {
      cubit.enter(PickTarget.to, autofocusSearch: true);
      cubit.onCameraIdle(35.5, 35.78);

      final picked = await cubit.confirm();

      expect(places.lookups, 1);
      expect(places.lookupReasons, ['confirm']);
      expect(picked?.address, 'شارع القدس، الدباغة');
      expect(picked?.latitude, 35.5);
      expect(cubit.state.isPicking, isFalse);
    });

    test(
      'confirming when nothing is found stays in the mode, with a retry',
      () async {
        places.label = null;
        cubit.enter(PickTarget.to, autofocusSearch: true);

        final picked = await cubit.confirm();

        expect(picked, isNull);
        expect(cubit.state.isPicking, isTrue);
        expect(cubit.state.addressDeferred, isFalse);
        expect(cubit.state.canConfirm, isFalse);

        places.label = 'شارع القدس';
        cubit.retryResolve();
        await Future<void>.delayed(Duration.zero);
        expect(cubit.state.address, 'شارع القدس');
      },
    );

    test('choosing a search result names the pin without any lookup', () async {
      cubit.enter(PickTarget.to, autofocusSearch: true);

      cubit.selectSuggestion(_place);
      cubit.onCameraMoveStarted();
      cubit.onCameraIdle(_place.latitude, _place.longitude);
      await Future<void>.delayed(Duration.zero);

      expect(places.lookups, 0);
      expect(cubit.state.address, _place.description);
      expect(cubit.state.addressDeferred, isFalse);
      expect(cubit.state.canConfirm, isTrue);
    });
  });
}
