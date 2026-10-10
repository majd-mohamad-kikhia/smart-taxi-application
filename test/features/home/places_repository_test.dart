import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/features/home/data/datasources/google_places_data_source.dart';
import 'package:mshoar/features/home/data/datasources/nominatim_reverse_data_source.dart';
import 'package:mshoar/features/home/data/models/place_suggestion_model.dart';
import 'package:mshoar/features/home/data/repositories/places_repository.dart';

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

class _FakeNominatim extends Fake implements NominatimReverseDataSource {
  String? name;

  @override
  Future<String?> reverseGeocode(double latitude, double longitude) async => name;
}

PlaceSuggestionModel _mosque(String city, double lat, double lng) =>
    PlaceSuggestionModel(description: 'جامع الروضة، $city', latitude: lat, longitude: lng);

// The customer is in Damascus.
const _lat = 33.5138;
const _lng = 36.2765;

void main() {
  test('results nearest to the customer first, inside the same region', () async {
    final google = _FakeGoogle([
      _mosque('حمص', 34.73, 36.71),
      _mosque('دمشق', 33.52, 36.28),
    ]);

    final results = await PlacesRepository(google, _FakeNominatim()).search(
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

    final results = await PlacesRepository(google, _FakeNominatim()).search(
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

    final results = await PlacesRepository(google, _FakeNominatim()).search('جامع الروضة');

    expect([for (final r in results) r.description], ['جامع الروضة، دمشق', 'جامع الروضة، حمص']);
    expect(results.first.distanceMeters, isNull);
  });

  test('a blank query asks nothing', () async {
    final google = _FakeGoogle([]);

    expect(await PlacesRepository(google, _FakeNominatim()).search('  ', nearLatitude: _lat, nearLongitude: _lng), isEmpty);
    expect(google.queries, isEmpty);
  });

  test('Google failing is a PlacesException for the search', () async {
    final google = _FakeGoogle([])..fail = true;

    await expectLater(PlacesRepository(google, _FakeNominatim()).search('x'), throwsA(isA<PlacesException>()));
  });

  test('naming a pin: Nominatim\'s full name first, Google is not asked', () async {
    final google = _FakeGoogle([]);
    final nominatim = _FakeNominatim()..name = 'محطة بغداد، شارع الجمهورية، الدباغة';
    final repository = PlacesRepository(google, nominatim);

    expect(await repository.addressFor(_lat, _lng), 'محطة بغداد، شارع الجمهورية، الدباغة');
    expect(google.reverseCalls, 0);
  });

  test('naming a pin: Nominatim has nothing, so Google answers', () async {
    final google = _FakeGoogle([]);
    final repository = PlacesRepository(google, _FakeNominatim());

    expect(await repository.addressFor(_lat, _lng), 'شارع الثورة');
    expect(google.reverseCalls, 1);
  });

  test('naming a pin: both failing is null, not an error', () async {
    final google = _FakeGoogle([])..fail = true;
    final repository = PlacesRepository(google, _FakeNominatim());

    expect(await repository.addressFor(_lat, _lng), isNull);
  });
}
