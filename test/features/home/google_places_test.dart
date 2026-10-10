import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/services/google_api_credentials_loader.dart';
import 'package:mshoar/features/home/data/datasources/google_places_data_source.dart';
import 'package:mshoar/features/home/data/models/place_suggestion_model.dart';
import 'package:mshoar/features/home/data/places_exception.dart';

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

void main() {
  late _Adapter adapter;
  late GooglePlacesDataSource google;

  setUp(() {
    adapter = _Adapter();
    google = GooglePlacesDataSource(
      credentials: () async => const GoogleApiCredentials(
        apiKey: 'KEY',
        appHeaders: {'X-Android-Package': 'p'},
      ),
      dio: Dio()..httpClientAdapter = adapter,
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

  test('a refusal (403) is a PlacesException', () async {
    adapter.status = 403;
    await expectLater(google.search('x'), throwsA(isA<PlacesException>()));
  });

  test('no key means no request, and a PlacesException', () async {
    final noKey = GooglePlacesDataSource(
      credentials: () async => GoogleApiCredentials.none,
      dio: Dio()..httpClientAdapter = adapter,
    );
    await expectLater(noKey.search('x'), throwsA(isA<PlacesException>()));
    await expectLater(noKey.reverseGeocode(1, 2), throwsA(isA<PlacesException>()));
    expect(adapter.requests, isEmpty);
  });

  test('naming a pin asks the Geocoding API in Arabic with the key and app headers', () async {
    adapter.body = {
      'status': 'OK',
      'results': [
        {
          'types': ['plus_code'],
          'formatted_address': 'X258+GH3، اللاذقية، سوريا',
        },
        {
          'types': ['route'],
          'formatted_address': 'شارع بغداد، اللاذقية، سوريا',
        },
      ],
    };

    final address = await google.reverseGeocode(35.52, 35.79);

    final request = adapter.requests.single;
    expect(request.uri.host, 'maps.googleapis.com');
    expect(request.queryParameters['latlng'], '35.52,35.79');
    expect(request.queryParameters['language'], 'ar');
    expect(request.queryParameters['key'], 'KEY');
    expect(request.headers['X-Android-Package'], 'p');
    expect(request.headers.containsKey('Authorization'), isFalse);
    // The plus code result is skipped.
    expect(address, 'شارع بغداد، اللاذقية');
  });

  test('naming a pin on an unnamed station: the street and neighborhood, not just the city', () {
    // What Google answered for محطة بغداد: results led by plus codes first.
    final answer = {
      'status': 'OK',
      'results': [
        {
          'types': ['establishment', 'gas_station', 'point_of_interest'],
          'formatted_address': 'GQGR+P5M، اللاذقية، سوريا',
        },
        {
          'types': ['premise', 'street_address'],
          'formatted_address': 'GQGR+P5G، اللاذقية، سوريا',
        },
        {
          'types': ['plus_code'],
          'formatted_address': 'GQGR+P5 اللاذقية، سوريا',
        },
        {
          'types': ['route'],
          'formatted_address': 'الجمهورية، اللاذقية، سوريا',
        },
        {
          'types': ['neighborhood', 'political'],
          'formatted_address': 'السابع من نيسان، اللاذقية، سوريا',
        },
        {
          'types': ['locality', 'political'],
          'formatted_address': 'اللاذقية، سوريا',
        },
      ],
    };

    expect(GooglePlacesDataSource.parseGeocode(answer), 'الجمهورية، السابع من نيسان، اللاذقية');
  });

  test('naming a pin: only a city is still better than nothing', () {
    final answer = {
      'status': 'OK',
      'results': [
        {
          'types': ['locality', 'political'],
          'formatted_address': 'اللاذقية، سوريا',
        },
      ],
    };

    expect(GooglePlacesDataSource.parseGeocode(answer), 'اللاذقية');
  });

  test('naming a pin: nothing there is null, a refused key is a PlacesException', () async {
    adapter.body = {'status': 'ZERO_RESULTS', 'results': <dynamic>[]};
    expect(await google.reverseGeocode(0, 0), isNull);

    adapter.body = {'status': 'REQUEST_DENIED', 'error_message': 'API not enabled'};
    await expectLater(google.reverseGeocode(0, 0), throwsA(isA<PlacesException>()));
  });
}
