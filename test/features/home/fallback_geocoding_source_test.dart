import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/features/home/data/datasources/fallback_geocoding_source.dart';
import 'package:mshoar/features/home/data/datasources/geocoder_health.dart';
import 'package:mshoar/features/home/data/datasources/geocoding_source.dart';
import 'package:mshoar/features/home/data/models/place_suggestion_model.dart';
import 'package:mshoar/features/home/data/repositories/places_repository.dart';

const _fromGoogle = PlaceSuggestionModel(
  description: 'من غوغل',
  latitude: 35.52,
  longitude: 35.79,
);
const _fromOsm = PlaceSuggestionModel(
  description: 'من الخريطة المفتوحة',
  latitude: 35.52,
  longitude: 35.79,
);

/// A source that answers, fails or is cancelled on demand, and counts asks.
class _Source implements GeocodingSource {
  final List<PlaceSuggestionModel> places;
  final String label;
  Object? failure;
  int searches = 0;
  int reverses = 0;

  _Source(this.places, this.label);

  @override
  Future<List<PlaceSuggestionModel>> search(
    String query, {
    int limit = 8,
    CancelToken? cancelToken,
  }) async {
    searches++;
    final error = failure;
    if (error != null) throw error;
    return places;
  }

  @override
  Future<String?> reverseGeocode(double latitude, double longitude) async {
    reverses++;
    final error = failure;
    if (error != null) throw error;
    return label;
  }
}

const _refused = PlacesException(
  'refused',
  status: 'REQUEST_DENIED',
  persistent: true,
);
const _dropped = PlacesException('dropped');

void main() {
  late _Source google;
  late _Source osm;
  late DateTime now;
  late FallbackGeocodingSource source;

  setUp(() {
    google = _Source([_fromGoogle], 'شارع غوغل');
    osm = _Source([_fromOsm], 'شارع الخريطة');
    now = DateTime(2026, 10, 20, 12);
    source = FallbackGeocodingSource(
      primary: google,
      fallback: osm,
      health: GeocoderHealth(now: () => now),
    );
  });

  group('while Google works', () {
    test('Google answers and OpenStreetMap is never asked', () async {
      expect(await source.search('مطار'), [_fromGoogle]);
      expect(await source.reverseGeocode(1, 2), 'شارع غوغل');
      expect(osm.searches + osm.reverses, 0);
    });

    test('no places found is an answer, not a failure', () async {
      final empty = _Source(const [], 'x');
      final source = FallbackGeocodingSource(primary: empty, fallback: osm);

      expect(await source.search('مكان غير موجود'), isEmpty);
      expect(osm.searches, 0);
    });

    test('nothing known at a spot is an answer too', () async {
      final unknown = _Source(const [], 'x');
      final source = FallbackGeocodingSource(
        primary: _NothingAt(unknown),
        fallback: osm,
      );

      expect(await source.reverseGeocode(1, 2), isNull);
      expect(osm.reverses, 0);
    });
  });

  group('when Google fails', () {
    test('a search is answered by OpenStreetMap', () async {
      google.failure = _dropped;

      expect(await source.search('مطار'), [_fromOsm]);
      expect(google.searches, 1);
      expect(osm.searches, 1);
    });

    test('naming a pin is answered by OpenStreetMap', () async {
      google.failure = _refused;

      expect(await source.reverseGeocode(1, 2), 'شارع الخريطة');
    });

    test(
      'a search replaced by a newer one is not a failure: no fallback',
      () async {
        google.failure = const PlacesCancelledException();

        await expectLater(
          source.search('مطار'),
          throwsA(isA<PlacesCancelledException>()),
        );
        expect(osm.searches, 0);
      },
    );

    test('when both fail, the first failure is the one reported', () async {
      google.failure = _refused;
      osm.failure = _dropped;

      await expectLater(source.search('مطار'), throwsA(same(_refused)));
    });

    test(
      'OpenStreetMap being cancelled is passed on, not reported as a failure',
      () async {
        google.failure = _dropped;
        osm.failure = const PlacesCancelledException();

        await expectLater(
          source.search('مطار'),
          throwsA(isA<PlacesCancelledException>()),
        );
      },
    );
  });

  group('not waiting for a source that keeps failing', () {
    test('a refused key is left alone at once, for five minutes', () async {
      google.failure = _refused;

      await source.search('أول');
      await source.search('ثاني');
      await source.reverseGeocode(1, 2);

      expect(google.searches + google.reverses, 1);
      expect(osm.searches, 2);
      expect(osm.reverses, 1);

      now = now.add(const Duration(minutes: 4, seconds: 59));
      await source.search('ثالث');
      expect(google.searches, 1, reason: 'still skipped');

      now = now.add(const Duration(seconds: 2));
      await source.search('رابع');
      expect(google.searches, 2, reason: 'asked again after the cooldown');
    });

    test(
      'plain trouble is tolerated once, then the source is left alone for 30 s',
      () async {
        google.failure = _dropped;

        await source.search('أول'); // the first strike
        await source.search('ثاني'); // the second opens the door
        await source.search('ثالث');
        expect(google.searches, 2);

        now = now.add(const Duration(seconds: 31));
        await source.search('رابع');
        expect(google.searches, 3);
      },
    );

    test('Google coming back is noticed and used again', () async {
      google.failure = _refused;
      await source.search('أول');

      now = now.add(const Duration(minutes: 6));
      google.failure = null;
      expect(await source.search('ثاني'), [_fromGoogle]);
      expect(await source.search('ثالث'), [_fromGoogle]);
      expect(google.searches, 3);
    });

    test(
      'after the cooldown one more failure closes the door again at once',
      () async {
        google.failure = _dropped;
        await source.search('أول');
        await source.search('ثاني');

        now = now.add(const Duration(seconds: 31));
        await source.search('ثالث'); // asked again, fails again
        await source.search('رابع'); // skipped without another strike

        expect(google.searches, 3);
      },
    );

    test('a success in between resets the strikes', () async {
      google.failure = _dropped;
      await source.search('أول');
      google.failure = null;
      await source.search('ثاني');
      google.failure = _dropped;
      await source.search('ثالث');
      await source.search('رابع');

      // Only now are there two in a row.
      expect(google.searches, 4);
      await source.search('خامس');
      expect(google.searches, 4);
    });
  });

  test(
    'the repository keeps what OpenStreetMap answered: asking again costs nothing',
    () async {
      google.failure = _refused;
      final places = PlacesRepository(source);

      final first = await places.search('مطار');
      final second = await places.search('مطار');

      expect(first.single.description, _fromOsm.description);
      expect(second, first);
      expect(osm.searches, 1);
      expect(google.searches, 1);
    },
  );
}

/// A source that finds nothing at any spot.
class _NothingAt implements GeocodingSource {
  final _Source inner;

  _NothingAt(this.inner);

  @override
  Future<List<PlaceSuggestionModel>> search(
    String query, {
    int limit = 8,
    CancelToken? cancelToken,
  }) => inner.search(query, limit: limit, cancelToken: cancelToken);

  @override
  Future<String?> reverseGeocode(double latitude, double longitude) async =>
      null;
}
