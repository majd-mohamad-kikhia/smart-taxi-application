import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/geo/geo_exception.dart';
import 'package:mshoar/core/geo/geo_models.dart';
import 'package:mshoar/core/geo/saved_places_cleanup.dart';
import 'package:mshoar/core/localization/app_strings.dart';
import 'package:mshoar/features/home/data/pin_label_resolver.dart';
import 'package:mshoar/features/home/data/repositories/places_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_geo.dart';

GeoResolved _resolved({String? address, String? corrected}) => GeoResolved(
  aliasId: 12,
  text: 'مشروع ياسين',
  lat: 35.5213,
  lng: 35.7904,
  address: address,
  correctedTo: corrected,
);

void main() {
  late FakeGeo geo;
  late PlacesRepository places;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    geo = FakeGeo();
    places = PlacesRepository(
      geo,
      PinLabelResolver(geo.reverse, minGap: Duration.zero),
    );
  });

  group('resolving', () {
    test('a text becomes a point', () async {
      geo.resolveResult = _resolved();

      final outcome = await places.submit('ياسين');

      expect(outcome, isA<PlaceFound>());
      final found = outcome as PlaceFound;
      expect(found.aliasId, 12);
      expect(found.latitude, 35.5213);
      expect(found.label, 'مشروع ياسين');
      expect(geo.resolved.single.aliasId, isNull);
      expect(geo.resolved.single.forceGoogle, isFalse);
    });

    test(
      "Google's address is shown, and the correction is passed on",
      () async {
        geo.resolveResult = _resolved(
          address: 'عنوان من جوجل',
          corrected: 'مشروع ياسين',
        );

        final found = await places.submit('ياسين') as PlaceFound;

        expect(found.label, 'عنوان من جوجل');
        expect(found.correctedTo, 'مشروع ياسين');
      },
    );

    test(
      'did you mean carries the suggested place; yes and no continue',
      () async {
        geo.resolveResult = const GeoDidYouMean(
          aliasId: 40,
          text: 'مشروع ياسين',
        );

        final outcome = await places.submit('ياسيين');
        expect(outcome, isA<PlaceDidYouMean>());

        geo.resolveResult = _resolved();
        await places.submit('ياسيين', aliasId: 40);
        await places.submit('ياسيين', forceGoogle: true);
        expect(geo.resolved[1].aliasId, 40);
        expect(geo.resolved[2].forceGoogle, isTrue);
      },
    );

    test(
      'not found, a cap, a rate limit, Google down and offline all mean: place the pin',
      () async {
        geo.resolveResult = const GeoNotFound();
        expect(await places.submit('x1'), isA<PlaceNotFound>());
        for (final failure in [
          GeoFailure.googleDailyCap,
          GeoFailure.rateLimited,
          GeoFailure.googleUnavailable,
          GeoFailure.offline,
          GeoFailure.server,
        ]) {
          geo.resolveFailure = GeoException(failure);
          expect(
            await places.submit('x1'),
            isA<PlaceNotFound>(),
            reason: '$failure',
          );
        }
        // Never retried: one call per submit.
        expect(geo.resolved, hasLength(6));
      },
    );
  });

  group('nothing is kept on the device', () {
    test('a resolved place leaves no trace in storage', () async {
      geo.resolveResult = _resolved(address: 'عنوان من جوجل');

      await places.submit('ياسين');
      await places.addressFor(35.5, 35.8);

      expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
    });

    test('what older versions saved is deleted', () async {
      SharedPreferences.setMockInitialValues({
        'recent_places': '[{"description":"x"}]',
        'place_history_v2': '[]',
        'locale': 'ar',
      });

      await deleteSavedPlacesFromDevice();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('recent_places'), isFalse);
      expect(prefs.containsKey('place_history_v2'), isFalse);
      expect(prefs.getString('locale'), 'ar', reason: 'other settings stay');
    });
  });

  group('feedback after the pin is confirmed', () {
    Future<bool> confirm(double metersNorth) async {
      final stayed = places.reportConfirmed(
        aliasId: 12,
        resolvedLatitude: 35.5,
        resolvedLongitude: 35.8,
        pinLatitude: 35.5 + metersNorth / 111195,
        pinLongitude: 35.8,
      );
      await Future<void>.delayed(Duration.zero);
      return stayed;
    }

    test('within 150 m: accepted', () async {
      expect(await confirm(100), isTrue);
      expect(geo.feedback, [(aliasId: 12, accepted: true)]);
    });

    test('beyond 300 m: rejected', () async {
      expect(await confirm(400), isFalse);
      expect(geo.feedback, [(aliasId: 12, accepted: false)]);
    });

    test('between 150 and 300 m: nothing is sent', () async {
      expect(await confirm(200), isFalse);
      expect(geo.feedback, isEmpty);
    });
  });

  group('the pin label', () {
    test('is the server label', () async {
      expect(await places.addressFor(35.5, 35.8), 'شارع القدس، الدباغة');
    });

    test(
      'the neutral wording when there is none or the server cannot say',
      () async {
        geo.reverseLabel = null;
        expect(
          await places.addressFor(35.5, 35.8),
          startsWith(AppStrings.current.pinLabelNeutral),
        );
        geo.reverseFailure = const GeoException(GeoFailure.rateLimited);
        expect(
          await places.addressFor(36.5, 35.8),
          startsWith(AppStrings.current.pinLabelNeutral),
        );
      },
    );

    test('a pin within 25 m reuses the label', () async {
      await places.addressFor(35.5, 35.8);
      await places.addressFor(35.5 + 0.00009, 35.8);
      expect(geo.reversed, hasLength(1));
      expect(places.labelRequestCount, 1);
    });
  });
}
