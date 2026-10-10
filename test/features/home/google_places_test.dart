import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/services/google_api_credentials_loader.dart';
import 'package:mshoar/features/home/data/datasources/google_places_data_source.dart';
import 'package:mshoar/features/home/data/datasources/places_remote_data_source.dart';
import 'package:mshoar/features/home/data/models/place_suggestion_model.dart';
import 'package:mshoar/features/home/data/repositories/places_repository.dart';

class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  int status = 200;
  Object body = {
    'places': [
      {
        'displayName': {'text': 'جامع الروضة'},
        'formattedAddress': 'X258+GH3، دمشق، سوريا',
        'location': {'latitude': 33.51, 'longitude': 36.29},
      },
      {
        'displayName': {'text': 'جامع الروضة'},
        'formattedAddress': 'X258+GH3، دمشق، سوريا',
        'location': {'latitude': 33.51, 'longitude': 36.29},
      },
      {
        'displayName': {'text': 'بلا موقع'},
        'formattedAddress': 'حمص',
      },
    ],
  };

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final text = jsonEncode(body);
    return ResponseBody.fromString(
      text,
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _FakePhoton extends PlacesRemoteDataSource {
  int calls = 0;

  @override
  Future<List<PlaceSuggestionModel>> autocomplete(
    String query, {
    double? nearLatitude,
    double? nearLongitude,
    double? withinDegrees,
    int limit = 8,
  }) async {
    calls++;
    return const [
      PlaceSuggestionModel(description: 'photon', latitude: 1, longitude: 1),
    ];
  }
}

void main() {
  late _Adapter adapter;
  late GooglePlacesDataSource google;
  var now = DateTime(2026, 10, 9, 12);

  setUp(() {
    adapter = _Adapter();
    now = DateTime(2026, 10, 9, 12);
    google = GooglePlacesDataSource(
      credentials: () async => const GoogleApiCredentials(
        apiKey: 'KEY',
        appHeaders: {'X-Android-Package': 'p'},
      ),
      dio: Dio()..httpClientAdapter = adapter,
      now: () => now,
    );
  });

  test('the address loses its plus code and ", سوريا"', () {
    expect(
      GooglePlacesDataSource.cleanAddress('X258+GH3، دمشق، سوريا'),
      'دمشق',
    );
    expect(GooglePlacesDataSource.cleanAddress('حمص، سوريا'), 'حمص');
    expect(GooglePlacesDataSource.cleanAddress('شارع الثورة'), 'شارع الثورة');
  });

  test(
    'the request puts Syria first and carries the key and app headers',
    () async {
      final places = await google.search('جامع الروضة');

      final request = adapter.requests.single;
      expect(request.headers['X-Goog-Api-Key'], 'KEY');
      expect(request.headers['X-Goog-FieldMask'], contains('places.location'));
      expect(request.headers['X-Android-Package'], 'p');
      expect(request.headers.containsKey('Authorization'), isFalse);
      final data = request.data as Map;
      expect(data['regionCode'], 'SY');
      expect(data['languageCode'], 'ar');
      final box = (data['locationBias'] as Map)['rectangle'] as Map;
      expect((box['low'] as Map)['latitude'], 35.1); // the Latakia box
      expect(places.single.description, 'جامع الروضة، دمشق');
    },
  );

  test(
    'Latakia first, then the rest of Syria, then elsewhere; order kept inside',
    () {
      const damascus = PlaceSuggestionModel(
        description: 'd',
        latitude: 33.5,
        longitude: 36.3,
      );
      const latakia1 = PlaceSuggestionModel(
        description: 'l1',
        latitude: 35.52,
        longitude: 35.79,
      );
      const abroad = PlaceSuggestionModel(
        description: 'x',
        latitude: 41.0,
        longitude: 29.0,
      );
      const latakia2 = PlaceSuggestionModel(
        description: 'l2',
        latitude: 35.55,
        longitude: 35.8,
      );

      final sorted = GooglePlacesDataSource.latakiaFirst([
        damascus,
        abroad,
        latakia1,
        latakia2,
      ]);

      expect(sorted.map((p) => p.description), ['l1', 'l2', 'd', 'x']);
    },
  );

  test(
    'a refusal (403) pauses Google for 5 minutes, then it is tried again',
    () async {
      adapter.status = 403;
      expect(await google.search('x'), isEmpty);
      expect(await google.search('x'), isEmpty);
      expect(adapter.requests, hasLength(1));

      now = now.add(const Duration(minutes: 6));
      await google.search('x');
      expect(adapter.requests, hasLength(2));
    },
  );

  test('no key means no request', () async {
    final noKey = GooglePlacesDataSource(
      credentials: () async => GoogleApiCredentials.none,
      dio: Dio()..httpClientAdapter = adapter,
    );
    expect(await noKey.search('x'), isEmpty);
    expect(adapter.requests, isEmpty);
  });

  test('Google answers: Photon is not asked', () async {
    final photon = _FakePhoton();
    final places = await PlacesRepository(photon, google).search('جامع الروضة');
    expect(places.single.description, 'جامع الروضة، دمشق');
    expect(photon.calls, 0);
  });

  test('Google gives nothing: Photon answers', () async {
    adapter.body = {'places': <dynamic>[]};
    final photon = _FakePhoton();
    final places = await PlacesRepository(photon, google).search('x');
    expect(places.single.description, 'photon');
    expect(photon.calls, 1);
  });
}
