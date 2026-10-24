import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mshoar/core/geo/geo_exception.dart';
import 'package:mshoar/core/geo/geo_models.dart';
import 'package:mshoar/core/localization/app_strings.dart';
import 'package:mshoar/core/services/current_location_service.dart';
import 'package:mshoar/features/home/data/pin_label_resolver.dart';
import 'package:mshoar/features/home/data/repositories/places_repository.dart';
import 'package:mshoar/features/home/presentation/cubit/map_pick_cubit.dart';
import 'package:mshoar/features/home/presentation/cubit/map_pick_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_geo.dart';

class _FakeLocation extends CurrentLocationService {
  @override
  Future<Position?> getPositionIfAllowed() async => null;
}

const _found = GeoResolved(
  aliasId: 12,
  text: 'مشروع ياسين',
  lat: 35.5213,
  lng: 35.7904,
);

/// Longer than the pause before the suggestions are asked.
Future<void> _pause([int ms = 400]) =>
    Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  late FakeGeo geo;
  late PlacesRepository places;
  late MapPickCubit cubit;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    geo = FakeGeo();
    places = PlacesRepository(
      geo,
      PinLabelResolver(geo.reverse, minGap: Duration.zero),
    );
    cubit = MapPickCubit(places, _FakeLocation());
  });

  tearDown(() => cubit.close());

  group('choosing a place', () {
    test(
      'a chosen search result keeps its own name when the map settles on it',
      () async {
        geo.resolveResult = _found;
        cubit.enter(PickTarget.from);
        await _pause(50);
        geo.reversed.clear();

        await cubit.submitSearch('ياسين');
        // The camera animates to the place: it moves, then goes idle on it.
        cubit.onCameraMove(35.5170, 35.7770);
        cubit.onCameraIdle(35.5213, 35.7904);
        await _pause(50);

        expect(cubit.state.address, 'مشروع ياسين');
        expect(cubit.state.isResolving, isFalse);
        expect(
          geo.reversed,
          isEmpty,
          reason: 'no lookup that could name the street instead',
        );
      },
    );

    test('Google\'s address is shown for a resolved place', () async {
      geo.resolveResult = const GeoResolved(
        aliasId: 12,
        text: 'مشروع ياسين',
        lat: 35.5213,
        lng: 35.7904,
        address: 'عنوان من جوجل',
      );
      cubit.enter(PickTarget.from);

      await cubit.submitSearch('ياسين');

      expect(cubit.state.address, 'عنوان من جوجل');
    });

    test('the correction is passed on once', () async {
      geo.resolveResult = const GeoResolved(
        aliasId: 12,
        text: 'مشروع ياسين',
        lat: 35.5213,
        lng: 35.7904,
        correctedTo: 'مشروع ياسين',
      );
      cubit.enter(PickTarget.from);
      final seen = <String?>[];
      final sub = cubit.stream.listen((s) => seen.add(s.correctedTo));

      await cubit.submitSearch('ياسيين');
      await _pause(20);

      expect(seen, contains('مشروع ياسين'));
      expect(cubit.state.correctedTo, isNull);
      await sub.cancel();
    });

    test(
      'the controls hide while the map moves and come back when it settles',
      () async {
        cubit.enter(PickTarget.from);
        await _pause(50);
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

    test(
      'dragging the pin off the chosen place names what is under it',
      () async {
        geo.resolveResult = _found;
        cubit.enter(PickTarget.from);
        await cubit.submitSearch('ياسين');
        cubit.onCameraIdle(35.5213, 35.7904);
        await _pause(50);
        geo.reversed.clear();

        cubit.onCameraMove(35.5300, 35.7900);
        cubit.onCameraIdle(35.5300, 35.7900);
        await _pause(50);

        expect(cubit.state.address, 'شارع القدس، الدباغة');
        expect(geo.reversed, hasLength(1));
      },
    );
  });

  group('typing', () {
    test('typing asks for suggestions once, after the pause', () async {
      cubit.enter(PickTarget.to, autofocusSearch: true);

      for (final text in ['مش', 'مشر', 'مشرو', 'مشروع']) {
        cubit.queryChanged(text);
      }
      expect(geo.suggested, isEmpty);
      await _pause();

      expect(geo.suggested, ['مشروع']);
      expect(geo.resolved, isEmpty);
      expect(cubit.state.isSearching, isFalse);
    });

    test('one letter asks nothing; the same text is not asked twice', () async {
      cubit.enter(PickTarget.to, autofocusSearch: true);

      cubit.queryChanged('م');
      await _pause();
      expect(geo.suggested, isEmpty);

      cubit.queryChanged('مدرسة');
      await _pause();
      cubit.queryChanged(' مدرسة ');
      await _pause();
      expect(geo.suggested, ['مدرسة']);
    });

    test('the answer fills the list; clearing the box empties it', () async {
      geo.suggestions = const [
        GeoSuggestionModel(aliasId: 12, text: 'مدرسة عبد الرحمن'),
      ];
      cubit.enter(PickTarget.to, autofocusSearch: true);

      cubit.queryChanged('مدرسة');
      await _pause();
      expect(cubit.state.suggestions.single.text, 'مدرسة عبد الرحمن');

      cubit.queryChanged('');
      expect(cubit.state.suggestions, isEmpty);
    });

    test('a failed call shows no list', () async {
      geo.suggestFailure = const GeoException(GeoFailure.server);
      cubit.enter(PickTarget.to, autofocusSearch: true);

      cubit.queryChanged('مدرسة');
      await _pause();

      expect(cubit.state.suggestions, isEmpty);
      expect(cubit.state.searchError, isNull);
    });

    test('a suggestion with coordinates moves the map at once and keeps '
        'its text as the title, then the server confirms it', () async {
      geo.resolveResult = _found;
      cubit.enter(PickTarget.to, autofocusSearch: true);

      await cubit.selectSuggestion(
        const GeoSuggestionModel(
          aliasId: 12,
          text: 'مدرسة عبد الرحمن',
          lat: 35.5197,
          lng: 35.7934,
        ),
      );

      expect(cubit.state.address, 'مدرسة عبد الرحمن');
      expect(cubit.state.moveTarget?.latitude, 35.5197);
      expect(cubit.state.suggestions, isEmpty);
      expect(geo.resolved.single.q, 'مدرسة عبد الرحمن');
      expect(geo.resolved.single.aliasId, 12);
    });

    test('a suggestion without coordinates waits for the server', () async {
      geo.resolveResult = _found;
      cubit.enter(PickTarget.to, autofocusSearch: true);

      await cubit.selectSuggestion(
        const GeoSuggestionModel(aliasId: 31, text: 'مدرسة اسراب اليمام'),
      );

      expect(geo.resolved.single.aliasId, 31);
      expect(cubit.state.moveTarget?.latitude, 35.5213);
      expect(cubit.state.address, 'مدرسة اسراب اليمام');
    });

    test(
      'typing turns the main button to Search; placing the pin ends it',
      () async {
        geo.resolveResult = _found;
        cubit.enter(PickTarget.to, autofocusSearch: true);
        expect(cubit.state.isTyping, isFalse);

        cubit.queryChanged('ياسين');
        expect(cubit.state.isTyping, isTrue);

        await cubit.searchTyped();
        expect(geo.resolved.single.q, 'ياسين');
        expect(cubit.state.isTyping, isFalse);
      },
    );

    test('emptying the box, or dragging the pin, ends Search', () async {
      cubit.enter(PickTarget.to, autofocusSearch: true);

      cubit.queryChanged('ياسين');
      cubit.queryChanged('');
      expect(cubit.state.isTyping, isFalse);

      cubit.queryChanged('ياسين');
      cubit.onCameraMoveStarted();
      expect(cubit.state.isTyping, isFalse);
    });

    test('a search that finds nothing keeps Search', () async {
      geo.resolveResult = const GeoNotFound();
      cubit.enter(PickTarget.to, autofocusSearch: true);

      cubit.queryChanged('ياسين');
      await cubit.searchTyped();

      expect(cubit.state.isTyping, isTrue);
      expect(cubit.state.searchError, isNotNull);
    });

    test('typing clears an old message', () async {
      geo.resolveResult = const GeoNotFound();
      cubit.enter(PickTarget.to, autofocusSearch: true);
      await cubit.submitSearch('ياسين');
      expect(cubit.state.searchError, isNotNull);

      cubit.queryChanged('ياسين ٢');

      expect(cubit.state.searchError, isNull);
    });

    test('nothing is kept on the device', () async {
      geo.resolveResult = _found;
      cubit.enter(PickTarget.to, autofocusSearch: true);
      await cubit.submitSearch('ياسين');
      await _pause(50);

      expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
    });
  });

  group('submitting', () {
    test('a text becomes a point and the pin goes there', () async {
      geo.resolveResult = _found;
      cubit.enter(PickTarget.to, autofocusSearch: true);

      await cubit.submitSearch('ياسين');

      expect(cubit.state.address, 'مشروع ياسين');
      expect(cubit.state.moveTarget?.latitude, 35.5213);
      expect(cubit.state.isSearching, isFalse);
      expect(cubit.state.searchError, isNull);
    });

    test('under 2 letters asks nothing and says to type more', () async {
      await cubit.submitSearch('م');
      expect(geo.resolved, isEmpty);
      expect(cubit.state.searchError, AppStrings.current.searchMinChars);
    });

    test('not found says to place the pin', () async {
      geo.resolveResult = const GeoNotFound();
      cubit.enter(PickTarget.to, autofocusSearch: true);

      await cubit.submitSearch('ياسين');

      expect(cubit.state.searchError, AppStrings.current.placesNotFoundMovePin);
      expect(cubit.state.isSearching, isFalse);
    });

    test('a cap or an error says the same, and nothing is retried', () async {
      geo.resolveFailure = const GeoException(GeoFailure.googleDailyCap);
      cubit.enter(PickTarget.to, autofocusSearch: true);

      await cubit.submitSearch('ياسين');
      await _pause(50);

      expect(cubit.state.searchError, AppStrings.current.placesNotFoundMovePin);
      expect(geo.resolved, hasLength(1));
    });

    test(
      'did you mean asks, yes continues with the place, no with Google',
      () async {
        geo.resolveResult = const GeoDidYouMean(
          aliasId: 40,
          text: 'مشروع ياسين',
        );
        cubit.enter(PickTarget.to, autofocusSearch: true);

        await cubit.submitSearch('ياسيين');
        expect(cubit.state.didYouMean?.text, 'مشروع ياسين');

        geo.resolveResult = _found;
        await cubit.answerDidYouMean(yes: true);
        expect(geo.resolved.last.aliasId, 40);
        expect(cubit.state.didYouMean, isNull);
        expect(cubit.state.address, 'مشروع ياسين');

        geo.resolveResult = const GeoDidYouMean(
          aliasId: 40,
          text: 'مشروع ياسين',
        );
        await cubit.submitSearch('ياسيين ٢');
        geo.resolveResult = _found;
        await cubit.answerDidYouMean(yes: false);
        expect(geo.resolved.last.forceGoogle, isTrue);
        expect(geo.resolved.last.aliasId, isNull);
      },
    );
  });

  group('confirming a resolved place', () {
    test(
      'the pin on the place: accepted, and the order carries its alias id',
      () async {
        geo.resolveResult = _found;
        cubit.enter(PickTarget.to, autofocusSearch: true);
        await cubit.submitSearch('ياسين');
        cubit.onCameraIdle(35.5213, 35.7904);

        final picked = await cubit.confirm();
        await _pause(20);

        expect(picked?.aliasId, 12);
        expect(geo.feedback, [(aliasId: 12, accepted: true)]);
      },
    );

    test('the pin moved far away: rejected, and no alias id', () async {
      geo.resolveResult = _found;
      cubit.enter(PickTarget.to, autofocusSearch: true);
      await cubit.submitSearch('ياسين');
      cubit.onCameraMoveStarted();
      cubit.onCameraMove(35.5413, 35.7904);
      cubit.onCameraIdle(35.5413, 35.7904);
      await _pause(50);

      final picked = await cubit.confirm();
      await _pause(20);

      expect(picked?.aliasId, isNull);
      expect(geo.feedback, [(aliasId: 12, accepted: false)]);
    });

    test(
      'a pin that was only dragged has no alias id and sends no feedback',
      () async {
        cubit.enter(PickTarget.to);
        await _pause(50);

        final picked = await cubit.confirm();

        expect(picked?.aliasId, isNull);
        expect(geo.feedback, isEmpty);
      },
    );
  });

  group('coming in through the search box', () {
    test('the map\'s center is not named at once', () async {
      cubit.enter(PickTarget.to, autofocusSearch: true);
      await _pause(50);

      expect(geo.reversed, isEmpty);
      expect(cubit.state.address, isNull);
      expect(cubit.state.addressDeferred, isTrue);
      expect(cubit.state.canConfirm, isTrue);
    });

    test('without the search box the center is named at once', () async {
      cubit.enter(PickTarget.to);
      await _pause(50);

      expect(geo.reversed, hasLength(1));
      expect(cubit.state.addressDeferred, isFalse);
    });

    test(
      'the map settling by itself (keyboard, resize) names nothing',
      () async {
        cubit.enter(PickTarget.to, autofocusSearch: true);

        cubit.onCameraIdle(35.5, 35.78);
        await _pause(50);

        expect(geo.reversed, isEmpty);
        expect(cubit.state.addressDeferred, isTrue);
      },
    );

    test('dragging the map names the spot it settles on', () async {
      cubit.enter(PickTarget.to, autofocusSearch: true);

      cubit.onCameraMoveStarted();
      cubit.onCameraMove(35.51, 35.79);
      cubit.onCameraIdle(35.51, 35.79);
      await _pause(50);

      expect(geo.reversed, hasLength(1));
      expect(cubit.state.address, 'شارع القدس، الدباغة');
    });

    test('confirming names the spot first, then hands it back', () async {
      cubit.enter(PickTarget.to, autofocusSearch: true);
      cubit.onCameraIdle(35.5, 35.78);

      final picked = await cubit.confirm();

      expect(geo.reversed, hasLength(1));
      expect(picked?.address, 'شارع القدس، الدباغة');
      expect(picked?.latitude, 35.5);
      expect(cubit.state.isPicking, isFalse);
    });

    test(
      'with no label the neutral wording stands and confirming works',
      () async {
        geo.reverseLabel = null;
        cubit.enter(PickTarget.to, autofocusSearch: true);

        final picked = await cubit.confirm();

        expect(picked?.address, startsWith(AppStrings.current.pinLabelNeutral));
      },
    );
  });
}
