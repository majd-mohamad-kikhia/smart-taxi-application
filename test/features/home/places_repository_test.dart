import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/features/home/data/datasources/places_remote_data_source.dart';
import 'package:mshoar/features/home/data/models/place_suggestion_model.dart';
import 'package:mshoar/features/home/data/repositories/places_repository.dart';

typedef _Call = ({double? withinDegrees, int limit, double? near});

class _FakeSource extends Fake implements PlacesRemoteDataSource {
  final List<List<PlaceSuggestionModel>> answers;
  final List<_Call> calls = [];

  /// Answer number (0-based) that fails instead.
  int? failOn;

  _FakeSource(this.answers);

  @override
  Future<List<PlaceSuggestionModel>> autocomplete(
    String query, {
    double? nearLatitude,
    double? nearLongitude,
    double? withinDegrees,
    int limit = 8,
  }) async {
    final index = calls.length;
    calls.add((withinDegrees: withinDegrees, limit: limit, near: nearLatitude));
    if (failOn == index) throw DioException(requestOptions: RequestOptions());
    return answers[index];
  }
}

PlaceSuggestionModel _mosque(String city, double lat, double lng) =>
    PlaceSuggestionModel(description: 'جامع الروضة، $city', latitude: lat, longitude: lng);

// The customer is in Damascus.
const _lat = 33.5138;
const _lng = 36.2765;

Future<List<String>> _search(_FakeSource source) async {
  final results = await PlacesRepository(source).search(
    'جامع الروضة',
    nearLatitude: _lat,
    nearLongitude: _lng,
  );
  return [for (final r in results) r.description];
}

void main() {
  final near = [for (var i = 0; i < 5; i++) _mosque('حي $i', 33.52 + i * 0.01, 36.28)];

  test('enough matches nearby: one request, only around the customer', () async {
    final source = _FakeSource([near]);

    final result = await _search(source);

    expect(source.calls, [(withinDegrees: 0.5, limit: 20, near: _lat)]);
    expect(result.first, 'جامع الروضة، حي 0');
  });

  test('too few matches nearby: a second, unrestricted request adds the far ones', () async {
    final far = _mosque('حلب', 36.2, 37.1);
    final source = _FakeSource([
      [_mosque('دمشق', 33.52, 36.28)],
      [far, _mosque('دمشق', 33.52, 36.28)],
    ]);

    final result = await _search(source);

    expect(source.calls.last, (withinDegrees: null, limit: 10, near: _lat));
    expect(result, ['جامع الروضة، دمشق', 'جامع الروضة، حلب']);
  });

  test('nearby results that do not match what was typed do not count as an answer', () async {
    final source = _FakeSource([
      [for (var i = 0; i < 6; i++) PlaceSuggestionModel(description: 'جامع النور $i', latitude: 33.52, longitude: 36.28 + i * 0.001)],
      [_mosque('حلب', 36.2, 37.1)],
    ]);

    final result = await _search(source);

    expect(source.calls, hasLength(2));
    expect(result.first, 'جامع الروضة، حلب');
  });

  test('the wider request failing keeps the nearby answer', () async {
    final source = _FakeSource([
      [_mosque('دمشق', 33.52, 36.28)],
      [],
    ])..failOn = 1;

    expect(await _search(source), ['جامع الروضة، دمشق']);
  });

  test('nothing nearby and the wider request failing is an error', () async {
    final source = _FakeSource([[], []])..failOn = 1;

    await expectLater(_search(source), throwsA(isA<PlacesException>()));
  });

  test('without a position it is a single plain request, in the service order', () async {
    final source = _FakeSource([
      [_mosque('حلب', 36.2, 37.1), _mosque('دمشق', 33.52, 36.28)],
    ]);

    final results = await PlacesRepository(source).search('جامع الروضة');

    expect(source.calls, [(withinDegrees: null, limit: 8, near: null)]);
    expect(results.first.description, 'جامع الروضة، حلب');
    expect(results.first.distanceMeters, isNull);
  });

  test('a blank query asks nothing', () async {
    final source = _FakeSource([]);

    expect(await PlacesRepository(source).search('  ', nearLatitude: _lat, nearLongitude: _lng), isEmpty);
    expect(source.calls, isEmpty);
  });
}
