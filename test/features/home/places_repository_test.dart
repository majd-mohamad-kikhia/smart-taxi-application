import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/features/home/data/datasources/google_places_data_source.dart';
import 'package:mshoar/features/home/data/datasources/recent_places_local_data_source.dart';
import 'package:mshoar/features/home/data/models/place_suggestion_model.dart';
import 'package:mshoar/features/home/data/repositories/places_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeGoogle extends Fake implements GooglePlacesDataSource {
  List<PlaceSuggestionModel> answer;
  final List<String> queries = [];
  final List<CancelToken?> tokens = [];
  bool fail = false;

  /// A search for this query waits until its gate is completed.
  final Map<String, Completer<void>> gates = {};

  _FakeGoogle(this.answer);

  @override
  Future<List<PlaceSuggestionModel>> search(
    String query, {
    int limit = 8,
    CancelToken? cancelToken,
  }) async {
    queries.add(query);
    tokens.add(cancelToken);
    final gate = gates[query];
    if (gate != null) {
      await gate.future;
      if (cancelToken?.isCancelled ?? false) {
        throw const PlacesCancelledException();
      }
    }
    if (fail) throw const PlacesException('down');
    return answer;
  }

  final List<(double, double)> reverseCalls = [];
  String Function(double lat, double lng) label = (lat, lng) => 'شارع $lat';
  final Map<String, Completer<void>> reverseGates = {};

  @override
  Future<String?> reverseGeocode(double latitude, double longitude) async {
    reverseCalls.add((latitude, longitude));
    final gate = reverseGates['$latitude,$longitude'];
    if (gate != null) await gate.future;
    if (fail) throw const PlacesException('down');
    return label(latitude, longitude);
  }
}

PlaceSuggestionModel _mosque(String city, double lat, double lng) =>
    PlaceSuggestionModel(
      description: 'جامع الروضة، $city',
      latitude: lat,
      longitude: lng,
    );

// The customer is in Damascus.
const _lat = 33.5138;
const _lng = 36.2765;

PlacesRepository _repo(GooglePlacesDataSource google) =>
    PlacesRepository(google, const RecentPlacesLocalDataSource());

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('recent places', () {
    test('a remembered place comes first and its Google duplicate is dropped', () async {
      final damascus = _mosque('دمشق', 33.52, 36.28);
      final google = _FakeGoogle([_mosque('حمص', 34.73, 36.71), damascus]);
      final repo = _repo(google);
      await repo.remember(damascus);

      final results = await repo.search('جامع الروضة', nearLatitude: _lat, nearLongitude: _lng);

      expect([for (final r in results) r.description], ['جامع الروضة، دمشق', 'جامع الروضة، حمص']);
      expect(results.first.isRecent, isTrue);
      expect(results.last.isRecent, isFalse);
    });

    test('under 3 letters asks Google nothing but still lists the matching picks', () async {
      final google = _FakeGoogle([_mosque('حمص', 34.73, 36.71)]);
      final repo = _repo(google);
      await repo.remember(_mosque('دمشق', 33.52, 36.28));

      final results = await repo.search('جا');

      expect([for (final r in results) r.description], ['جامع الروضة، دمشق']);
      expect(google.queries, isEmpty);
    });

    test('an empty query lists the last five picks, newest first', () async {
      final repo = _repo(_FakeGoogle([]));
      for (var i = 1; i <= 7; i++) {
        await repo.remember(PlaceSuggestionModel(description: 'مكان $i', latitude: 33.5, longitude: 36.3 + i / 100));
      }

      final recent = await repo.recentPlaces();

      expect([for (final r in recent) r.description], ['مكان 7', 'مكان 6', 'مكان 5', 'مكان 4', 'مكان 3']);
      expect(recent.every((r) => r.isRecent), isTrue);
    });

    test('a typed query lists at most three matching picks', () async {
      final repo = _repo(_FakeGoogle([]));
      for (var i = 1; i <= 5; i++) {
        await repo.remember(PlaceSuggestionModel(description: 'جامع $i', latitude: 33.5, longitude: 36.3 + i / 100));
      }
      await repo.remember(const PlaceSuggestionModel(description: 'مشفى', latitude: 33.6, longitude: 36.4));

      final recent = await repo.recentPlaces(query: 'جامع');

      expect([for (final r in recent) r.description], ['جامع 5', 'جامع 4', 'جامع 3']);
    });

    test('picking a place again moves it to the front, once', () async {
      final repo = _repo(_FakeGoogle([]));
      final a = _mosque('دمشق', 33.52, 36.28);
      final b = _mosque('حمص', 34.73, 36.71);
      await repo.remember(a);
      await repo.remember(b);
      await repo.remember(a);

      final recent = await repo.recentPlaces();

      expect([for (final r in recent) r.description], [a.description, b.description]);
    });

    test('only the newest ${PlacesRepository.maxRecent} picks are kept', () async {
      final repo = _repo(_FakeGoogle([]));
      for (var i = 0; i < PlacesRepository.maxRecent + 5; i++) {
        await repo.remember(PlaceSuggestionModel(description: 'مكان $i', latitude: 33.0 + i / 1000, longitude: 36.0));
      }

      final saved = await const RecentPlacesLocalDataSource().load();

      expect(saved, hasLength(PlacesRepository.maxRecent));
      expect(saved.first.description, 'مكان ${PlacesRepository.maxRecent + 4}');
    });

    test('clearRecent forgets every pick', () async {
      final repo = _repo(_FakeGoogle([]));
      await repo.remember(_mosque('دمشق', 33.52, 36.28));

      await repo.clearRecent();

      expect(await repo.recentPlaces(), isEmpty);
    });

    test('recent picks carry their distance from the customer', () async {
      final repo = _repo(_FakeGoogle([]));
      await repo.remember(_mosque('دمشق', 33.52, 36.28));

      final recent = await repo.recentPlaces(nearLatitude: _lat, nearLongitude: _lng);

      expect(recent.single.distanceMeters, isNotNull);
    });
  });

  group('search', () {
    test(
      'results nearest to the customer first, inside the same region',
      () async {
        final google = _FakeGoogle([
          _mosque('حمص', 34.73, 36.71),
          _mosque('دمشق', 33.52, 36.28),
        ]);

        final results = await _repo(
          google,
        ).search('جامع الروضة', nearLatitude: _lat, nearLongitude: _lng);

        expect(results.first.description, 'جامع الروضة، دمشق');
        expect(results.first.distanceMeters, isNotNull);
      },
    );

    test('Latakia comes before the rest of Syria', () async {
      final google = _FakeGoogle([
        _mosque('دمشق', 33.52, 36.28),
        _mosque('اللاذقية', 35.52, 35.79),
      ]);

      final results = await _repo(
        google,
      ).search('جامع الروضة', nearLatitude: _lat, nearLongitude: _lng);

      expect(results.first.description, 'جامع الروضة، اللاذقية');
    });

    test('without a position Google\'s own order is kept', () async {
      final google = _FakeGoogle([
        _mosque('دمشق', 33.52, 36.28),
        _mosque('حمص', 34.73, 36.71),
      ]);

      final results = await _repo(google).search('جامع الروضة');

      expect(
        [for (final r in results) r.description],
        ['جامع الروضة، دمشق', 'جامع الروضة، حمص'],
      );
      expect(results.first.distanceMeters, isNull);
    });

    test('Google failing is a PlacesException for the search', () async {
      final google = _FakeGoogle([])..fail = true;

      await expectLater(
        _repo(google).search('مطار'),
        throwsA(isA<PlacesException>()),
      );
    });
  });

  group('the minimum length', () {
    test('under 3 letters asks nothing and finds nothing', () async {
      final google = _FakeGoogle([_mosque('دمشق', 33.52, 36.28)]);
      final places = _repo(google);

      expect(await places.search(''), isEmpty);
      expect(await places.search('  '), isEmpty);
      expect(await places.search('مط'), isEmpty);
      // Spaces around the text do not count: this is 2 letters.
      expect(await places.search('   مط   '), isEmpty);
      expect(google.queries, isEmpty);
      expect(places.googleCallCount, 0);
    });

    test('3 letters is enough', () async {
      final google = _FakeGoogle([_mosque('دمشق', 33.52, 36.28)]);

      final results = await _repo(google).search('مطر');

      expect(results, hasLength(1));
      expect(google.queries, ['مطر']);
    });

    test('isSearchable follows the same rule', () {
      expect(PlacesRepository.isSearchable('مط'), isFalse);
      expect(PlacesRepository.isSearchable(' مطر '), isTrue);
      expect(PlacesRepository.minQueryLength, 3);
    });
  });

  group('the cache', () {
    test(
      'asking again, however it is spelled with spaces or case, costs nothing',
      () async {
        final google = _FakeGoogle([_mosque('دمشق', 33.52, 36.28)]);
        final places = _repo(google);

        await places.search('Airport Road');
        await places.search('  airport   road ');
        await places.search('AIRPORT ROAD');

        expect(google.queries, ['airport road']);
        expect(places.googleCallCount, 1);
      },
    );

    test(
      'a hit makes no request but still ranks by where the customer is now',
      () async {
        final google = _FakeGoogle([
          _mosque('حمص', 34.73, 36.71),
          _mosque('دمشق', 33.52, 36.28),
        ]);
        final places = _repo(google);

        await places.search('جامع الروضة');
        final fromHoms = await places.search(
          'جامع الروضة',
          nearLatitude: 34.73,
          nearLongitude: 36.71,
        );

        expect(google.queries, hasLength(1));
        expect(fromHoms.first.description, 'جامع الروضة، حمص');
      },
    );

    test(
      'a failed search is not remembered, so it can be tried again',
      () async {
        final google = _FakeGoogle([_mosque('دمشق', 33.52, 36.28)])
          ..fail = true;
        final places = _repo(google);

        await expectLater(
          places.search('مطار'),
          throwsA(isA<PlacesException>()),
        );
        google.fail = false;
        final results = await places.search('مطار');

        expect(results, hasLength(1));
        expect(google.queries, ['مطار', 'مطار']);
      },
    );

    test('holds about 50 queries: the oldest is forgotten first', () async {
      final google = _FakeGoogle([_mosque('دمشق', 33.52, 36.28)]);
      final places = _repo(google);

      for (var i = 0; i < 51; i++) {
        await places.search('مكان $i');
      }
      expect(google.queries, hasLength(51));

      await places.search('مكان 50'); // recent: a hit
      await places.search('مكان 1'); // still there
      expect(google.queries, hasLength(51));

      await places.search('مكان 0'); // the first one was pushed out
      expect(google.queries, hasLength(52));
    });
  });

  group('one search at a time', () {
    test('the same query while it is on its way joins it', () async {
      final google = _FakeGoogle([_mosque('دمشق', 33.52, 36.28)]);
      final gate = google.gates['مطار'] = Completer<void>();
      final places = _repo(google);

      final first = places.search('مطار');
      final second = places.search(' مطار ');
      gate.complete();

      expect(await first, hasLength(1));
      expect(await second, hasLength(1));
      expect(google.queries, ['مطار']);
    });

    test('a different query cancels the one in flight', () async {
      final google = _FakeGoogle([_mosque('دمشق', 33.52, 36.28)]);
      final slow = google.gates['مطار'] = Completer<void>();
      final places = _repo(google);

      final first = places.search('مطار');
      final second = places.search('محطة');
      slow.complete();

      expect(google.tokens.first!.isCancelled, isTrue);
      expect(google.tokens.last!.isCancelled, isFalse);
      await expectLater(first, throwsA(isA<PlacesCancelledException>()));
      expect(await second, hasLength(1));
      // The cancelled one was never answered, so it is not in the cache.
      await places.search('مطار');
      expect(google.queries, ['مطار', 'محطة', 'مطار']);
    });

    test('cancelSearch drops the search in flight', () async {
      final google = _FakeGoogle([]);
      final gate = google.gates['مطار'] = Completer<void>();
      final places = _repo(google);

      final pending = places.search('مطار');
      places.cancelSearch();
      gate.complete();

      await expectLater(pending, throwsA(isA<PlacesCancelledException>()));
    });
  });

  group('naming a pin', () {
    test('Google answers', () async {
      final google = _FakeGoogle([]);

      expect(
        await _repo(google).addressFor(_lat, _lng),
        'شارع $_lat',
      );
      expect(google.reverseCalls, hasLength(1));
    });

    test(
      'Google failing is null, not an error, and is not remembered',
      () async {
        final google = _FakeGoogle([])..fail = true;
        final places = _repo(google);

        expect(await places.addressFor(_lat, _lng), isNull);
        google.fail = false;
        expect(await places.addressFor(_lat, _lng), 'شارع $_lat');
        expect(google.reverseCalls, hasLength(2));
      },
    );

    test('a pin within 25 m of one just named takes its label', () async {
      final google = _FakeGoogle([]);
      final places = _repo(google);

      final first = await places.addressFor(35.5200, 35.7900);
      // About 11 m north, then about 22 m north-east.
      final near = await places.addressFor(35.5201, 35.7900);
      final nearer = await places.addressFor(35.52015, 35.79015);

      expect(near, first);
      expect(nearer, first);
      expect(google.reverseCalls, hasLength(1));
    });

    test('a pin beyond 25 m is named again', () async {
      final google = _FakeGoogle([]);
      final places = _repo(google);

      await places.addressFor(35.5200, 35.7900);
      // About 33 m north.
      final far = await places.addressFor(35.5203, 35.7900);

      expect(far, isNot('شارع 35.52'));
      expect(google.reverseCalls, hasLength(2));
    });

    test(
      'coming back to a spot named earlier needs no request, even if the GPS drifted',
      () async {
        final google = _FakeGoogle([]);
        final places = _repo(google);

        final home = await places.addressFor(35.5200, 35.7900);
        await places.addressFor(35.5400, 35.8100); // somewhere else
        // The fix drifted ~8 m and lands in another rounded cell.
        final back = await places.addressFor(35.52007, 35.79005);

        expect(back, home);
        expect(google.reverseCalls, hasLength(2));
      },
    );

    test('the same spot asked twice at once is one request', () async {
      final google = _FakeGoogle([]);
      final gate = google.reverseGates['35.52,35.79'] = Completer<void>();
      final places = _repo(google);

      final a = places.addressFor(35.52, 35.79);
      final b = places.addressFor(35.52, 35.79);
      gate.complete();

      expect(await a, await b);
      expect(google.reverseCalls, hasLength(1));
    });

    test('the log counter counts requests, not hits', () async {
      final google = _FakeGoogle([_mosque('دمشق', 33.52, 36.28)]);
      final places = _repo(google);

      await places.search('مطار');
      await places.search('مطار');
      await places.addressFor(35.52, 35.79);
      await places.addressFor(35.52, 35.79);
      await places.addressFor(35.52001, 35.79001);

      expect(places.googleCallCount, 2);
    });
  });

  test('distance is the straight line in meters', () {
    // One thousandth of a degree of latitude is about 111 m.
    expect(
      PlacesRepository.distanceMeters(35, 36, 35.001, 36),
      closeTo(111.2, 0.5),
    );
    expect(PlacesRepository.distanceMeters(35, 36, 35, 36), 0);
  });
}
