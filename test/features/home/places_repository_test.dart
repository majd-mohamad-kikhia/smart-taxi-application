import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/features/home/data/datasources/google_places_data_source.dart';
import 'package:mshoar/features/home/data/datasources/recent_places_local_data_source.dart';
import 'package:mshoar/features/home/data/models/place_suggestion_model.dart';
import 'package:mshoar/features/home/data/repositories/places_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeGoogle extends Fake implements GooglePlacesDataSource {
  final List<PlaceSuggestionModel> answer;
  final List<String> queries = [];
  bool fail = false;

  _FakeGoogle(this.answer);

  @override
  Future<List<PlaceSuggestionModel>> search(String query, {int limit = 8}) async {
    queries.add(query);
    if (fail) throw const PlacesException('down');
    return answer;
  }

  int reverseCalls = 0;

  @override
  Future<String?> reverseGeocode(double latitude, double longitude) async {
    reverseCalls++;
    if (fail) throw const PlacesException('down');
    return 'شارع الثورة';
  }
}

PlaceSuggestionModel _mosque(String city, double lat, double lng) =>
    PlaceSuggestionModel(description: 'جامع الروضة، $city', latitude: lat, longitude: lng);

// The customer is in Damascus.
const _lat = 33.5138;
const _lng = 36.2765;

PlacesRepository _repo(GooglePlacesDataSource google) =>
    PlacesRepository(google, const RecentPlacesLocalDataSource());

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

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
    final google = _FakeGoogle([]);
    final repo = _repo(google);
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

  test('results nearest to the customer first, inside the same region', () async {
    final google = _FakeGoogle([
      _mosque('حمص', 34.73, 36.71),
      _mosque('دمشق', 33.52, 36.28),
    ]);

    final results = await _repo(google).search(
      'جامع الروضة',
      nearLatitude: _lat,
      nearLongitude: _lng,
    );

    expect(results.first.description, 'جامع الروضة، دمشق');
    expect(results.first.distanceMeters, isNotNull);
  });

  test('Latakia comes before the rest of Syria', () async {
    final google = _FakeGoogle([
      _mosque('دمشق', 33.52, 36.28),
      _mosque('اللاذقية', 35.52, 35.79),
    ]);

    final results = await _repo(google).search(
      'جامع الروضة',
      nearLatitude: _lat,
      nearLongitude: _lng,
    );

    expect(results.first.description, 'جامع الروضة، اللاذقية');
  });

  test('without a position Google\'s own order is kept', () async {
    final google = _FakeGoogle([
      _mosque('دمشق', 33.52, 36.28),
      _mosque('حمص', 34.73, 36.71),
    ]);

    final results = await _repo(google).search('جامع الروضة');

    expect([for (final r in results) r.description], ['جامع الروضة، دمشق', 'جامع الروضة، حمص']);
    expect(results.first.distanceMeters, isNull);
  });

  test('a blank query asks nothing', () async {
    final google = _FakeGoogle([]);

    expect(await _repo(google).search('  ', nearLatitude: _lat, nearLongitude: _lng), isEmpty);
    expect(google.queries, isEmpty);
  });

  test('Google failing is a PlacesException for the search', () async {
    final google = _FakeGoogle([])..fail = true;

    await expectLater(_repo(google).search('x'), throwsA(isA<PlacesException>()));
  });

  test('naming a pin: Google answers', () async {
    final google = _FakeGoogle([]);

    expect(await _repo(google).addressFor(_lat, _lng), 'شارع الثورة');
    expect(google.reverseCalls, 1);
  });

  test('naming a pin: Google failing is null, not an error', () async {
    final google = _FakeGoogle([])..fail = true;

    expect(await _repo(google).addressFor(_lat, _lng), isNull);
  });
}
