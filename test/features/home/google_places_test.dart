import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/services/google_api_credentials_loader.dart';
import 'package:mshoar/features/home/data/datasources/google_places_data_source.dart';
import 'package:mshoar/features/home/data/models/place_suggestion_model.dart';
import 'package:mshoar/features/home/data/places_exception.dart';
import 'package:mshoar/features/home/data/syria_region.dart';

Map<String, dynamic> _result({
  required String address,
  required List<Map<String, dynamic>> components,
  double lat = 33.51,
  double lng = 36.29,
  bool withGeometry = true,
}) => {
  'formatted_address': address,
  'address_components': components,
  if (withGeometry)
    'geometry': {
      'location': {'lat': lat, 'lng': lng},
    },
};

Map<String, dynamic> _part(String name, List<String> types) => {
  'long_name': name,
  'short_name': name,
  'types': types,
};

class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  int status = 200;
  Object body = {
    'status': 'OK',
    'results': [
      _result(
        address: 'X258+GH3، دمشق، سوريا',
        components: [
          _part('جامع الروضة', ['establishment', 'point_of_interest']),
          _part('دمشق', ['locality', 'political']),
        ],
      ),
      // The same place twice: only one is kept.
      _result(
        address: 'X258+GH3، دمشق، سوريا',
        components: [
          _part('جامع الروضة', ['establishment', 'point_of_interest']),
          _part('دمشق', ['locality', 'political']),
        ],
      ),
      // No location: skipped.
      _result(
        address: 'حمص، سوريا',
        components: [
          _part('حمص', ['locality']),
        ],
        withGeometry: false,
      ),
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
    'the search asks the Geocoding API for Syria, Latakia first, with the key and app headers',
    () async {
      final places = await google.search('جامع الروضة');

      final request = adapter.requests.single;
      expect(request.uri.host, 'maps.googleapis.com');
      expect(request.uri.path, '/maps/api/geocode/json');
      final query = request.queryParameters;
      expect(query['address'], 'جامع الروضة');
      expect(query['language'], 'ar');
      expect(query['region'], 'sy');
      expect(query['components'], 'country:SY');
      // South-west | north-east corner of the Latakia box.
      expect(query['bounds'], '35.1,35.7|35.95,36.3');
      expect(query['key'], 'KEY');
      expect(request.headers['X-Android-Package'], 'p');
      expect(request.headers.containsKey('Authorization'), isFalse);
      expect(request.headers.containsKey('X-Goog-Api-Key'), isFalse);
      expect(request.headers.containsKey('X-Goog-FieldMask'), isFalse);
      // The place name, then its address without the plus code and ", سوريا".
      expect(places.single.description, 'جامع الروضة، دمشق');
      expect(places.single.latitude, 33.51);
      expect(places.single.longitude, 36.29);
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

      final sorted = SyriaRegion.latakiaFirst([
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

  group('the answer of a search', () {
    test('ZERO_RESULTS is an empty list, not an error', () async {
      adapter.body = {'status': 'ZERO_RESULTS', 'results': <dynamic>[]};
      expect(await google.search('مكان غير موجود'), isEmpty);
    });

    for (final status in const [
      'OVER_QUERY_LIMIT',
      'REQUEST_DENIED',
      'INVALID_REQUEST',
      'UNKNOWN_ERROR',
    ]) {
      test('$status is a PlacesException carrying the status', () async {
        adapter.body = {'status': status, 'error_message': 'nope'};
        await expectLater(
          google.search('مطار'),
          throwsA(
            isA<PlacesException>().having((e) => e.status, 'status', status),
          ),
        );
      });
    }

    test('a debug build says what Google answered', () async {
      adapter.body = {
        'status': 'REQUEST_DENIED',
        'error_message': 'not enabled',
      };
      await expectLater(
        google.search('مطار'),
        throwsA(
          isA<PlacesException>().having(
            (e) => e.message,
            'message',
            contains('REQUEST_DENIED'),
          ),
        ),
      );

      adapter.status = 403;
      await expectLater(
        google.search('مطار'),
        throwsA(
          isA<PlacesException>().having(
            (e) => e.message,
            'message',
            contains('HTTP 403'),
          ),
        ),
      );
    });

    test(
      'a reply that is not a Geocoding answer is a PlacesException',
      () async {
        adapter.body = <dynamic>[];
        await expectLater(
          google.search('مطار'),
          throwsA(isA<PlacesException>()),
        );
      },
    );

    test(
      'the title is the most specific component, found by type not position',
      () {
        final places = GooglePlacesDataSource.parseSearch({
          'status': 'OK',
          'results': [
            // A street: the components come in the "wrong" order on purpose.
            _result(
              address: 'شارع بغداد، اللاذقية، سوريا',
              components: [
                _part('اللاذقية', ['locality', 'political']),
                _part('سوريا', ['country', 'political']),
                _part('شارع بغداد', ['route']),
              ],
            ),
            // A building name beats the street it is on.
            _result(
              address: 'طريق المطار، اللاذقية، سوريا',
              components: [
                _part('طريق المطار', ['route']),
                _part('مطار باسل الأسد', [
                  'establishment',
                  'point_of_interest',
                ]),
              ],
              lat: 35.4,
              lng: 35.95,
            ),
            // Only a neighborhood and a city: the neighborhood leads.
            _result(
              address: 'الدعتور، اللاذقية، سوريا',
              components: [
                _part('اللاذقية', ['locality']),
                _part('الدعتور', ['neighborhood', 'political']),
              ],
              lat: 35.52,
              lng: 35.8,
            ),
          ],
        });

        expect(places.map((p) => p.description), [
          // The street's name already starts the address: not repeated.
          'شارع بغداد، اللاذقية',
          // The building's name, then the address it is at.
          'مطار باسل الأسد، طريق المطار، اللاذقية',
          'الدعتور، اللاذقية',
        ]);
      },
    );

    test('missing components fall back to the address alone', () {
      final places = GooglePlacesDataSource.parseSearch({
        'status': 'OK',
        'results': [
          _result(address: 'سوريا', components: const []),
          {
            'formatted_address': 'حماة، سوريا',
            'geometry': {
              'location': {'lat': 35.13, 'lng': 36.75},
            },
            // No address_components at all.
          },
          {
            'formatted_address': 'حمص، سوريا',
            'address_components': 'not a list',
            'geometry': {
              'location': {'lat': 34.73, 'lng': 36.71},
            },
          },
        ],
      });

      expect(places.map((p) => p.description), ['سوريا', 'حماة', 'حمص']);
    });

    test('at most 8 places are kept', () {
      final places = GooglePlacesDataSource.parseSearch({
        'status': 'OK',
        'results': [
          for (var i = 0; i < 12; i++)
            _result(
              address: 'مكان $i، اللاذقية، سوريا',
              components: [
                _part('مكان $i', ['premise']),
              ],
              lat: 35.5 + i / 1000,
            ),
        ],
      });

      expect(places, hasLength(8));
      expect(places.first.description, 'مكان 0، اللاذقية');
    });
  });

  test(
    'a cancelled search is PlacesCancelledException, not a failure',
    () async {
      final token = CancelToken()..cancel('replaced');
      await expectLater(
        google.search('مطار', cancelToken: token),
        throwsA(isA<PlacesCancelledException>()),
      );
    },
  );

  test('a failure is logged without the key or the request address', () async {
    final logged = <String>[];
    final original = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) => logged.add('$message');
    addTearDown(() => debugPrint = original);

    adapter.status = 403;
    await expectLater(google.search('مطار'), throwsA(isA<PlacesException>()));
    adapter.status = 200;
    adapter.body = {'status': 'REQUEST_DENIED', 'error_message': 'denied'};
    await expectLater(google.search('مطار'), throwsA(isA<PlacesException>()));
    await expectLater(
      google.reverseGeocode(1, 2),
      throwsA(isA<PlacesException>()),
    );

    expect(logged, isNotEmpty);
    for (final line in logged) {
      expect(line, isNot(contains('KEY')));
      expect(line, isNot(contains('maps.googleapis.com')));
    }
  });

  test('no key means no request, and a PlacesException', () async {
    final noKey = GooglePlacesDataSource(
      credentials: () async => GoogleApiCredentials.none,
      dio: Dio()..httpClientAdapter = adapter,
    );
    await expectLater(noKey.search('x'), throwsA(isA<PlacesException>()));
    await expectLater(
      noKey.reverseGeocode(1, 2),
      throwsA(isA<PlacesException>()),
    );
    expect(adapter.requests, isEmpty);
  });

  test(
    'naming a pin asks the Geocoding API in Arabic with the key and app headers',
    () async {
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
    },
  );

  test(
    'naming a pin on an unnamed station: the street and neighborhood, not just the city',
    () {
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

      expect(
        GooglePlacesDataSource.parseGeocode(answer),
        'الجمهورية، السابع من نيسان، اللاذقية',
      );
    },
  );

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

  test(
    'naming a pin: nothing there is null, a refused key is a PlacesException',
    () async {
      adapter.body = {'status': 'ZERO_RESULTS', 'results': <dynamic>[]};
      expect(await google.reverseGeocode(0, 0), isNull);

      adapter.body = {
        'status': 'REQUEST_DENIED',
        'error_message': 'API not enabled',
      };
      await expectLater(
        google.reverseGeocode(0, 0),
        throwsA(isA<PlacesException>()),
      );
    },
  );

  group('naming a pin from the address components', () {
    Map<String, dynamic> answer(List<Map<String, dynamic>> results) => {
      'status': 'OK',
      'results': results,
    };

    test(
      'street, then neighborhood, then city — whatever order they come in',
      () {
        final label = GooglePlacesDataSource.parseGeocode(
          answer([
            {
              'types': ['street_address'],
              'formatted_address': 'شارع بغداد، الدعتور، اللاذقية، سوريا',
              'address_components': [
                _part('اللاذقية', ['locality', 'political']),
                _part('سوريا', ['country', 'political']),
                _part('الدعتور', ['neighborhood', 'political']),
                _part('شارع بغداد', ['route']),
                _part('12', ['street_number']),
              ],
            },
          ]),
        );

        expect(label, 'شارع بغداد، الدعتور، اللاذقية');
      },
    );

    test('a sub-locality stands in for a missing neighborhood', () {
      final label = GooglePlacesDataSource.parseGeocode(
        answer([
          {
            'types': ['route'],
            'formatted_address': 'x',
            'address_components': [
              _part('الجمهورية', ['route']),
              _part('وسط المدينة', [
                'sublocality',
                'sublocality_level_1',
                'political',
              ]),
              _part('اللاذقية', ['locality']),
            ],
          },
        ]),
      );

      expect(label, 'الجمهورية، وسط المدينة، اللاذقية');
    });

    test('a street alone, a name repeated and a missing city are all fine', () {
      expect(
        GooglePlacesDataSource.parseGeocode(
          answer([
            {
              'formatted_address': 'x',
              'address_components': [
                _part('الجمهورية', ['route']),
              ],
            },
          ]),
        ),
        'الجمهورية',
      );
      expect(
        GooglePlacesDataSource.parseGeocode(
          answer([
            {
              'formatted_address': 'x',
              'address_components': [
                _part('اللاذقية', ['neighborhood']),
                _part('اللاذقية', ['locality']),
              ],
            },
          ]),
        ),
        'اللاذقية',
      );
    });

    test('a plus-code result is not the one; the next result is named', () {
      final label = GooglePlacesDataSource.parseGeocode(
        answer([
          {
            'types': ['plus_code'],
            'formatted_address': 'GQGR+P5 اللاذقية، سوريا',
            'address_components': [
              _part('اللاذقية', ['locality']),
            ],
          },
          {
            'types': ['route'],
            'formatted_address': 'الجمهورية، اللاذقية، سوريا',
            'address_components': [
              _part('الجمهورية', ['route']),
              _part('اللاذقية', ['locality']),
            ],
          },
        ]),
      );

      expect(label, 'الجمهورية، اللاذقية');
    });

    test(
      'no street or area in the components falls back to formatted_address',
      () {
        expect(
          GooglePlacesDataSource.parseGeocode(
            answer([
              {
                'types': ['locality'],
                'formatted_address': 'اللاذقية، سوريا',
                'address_components': [
                  _part('اللاذقية', ['locality']),
                ],
              },
            ]),
          ),
          'اللاذقية',
        );
      },
    );

    test('garbled components never crash the naming', () {
      expect(
        GooglePlacesDataSource.parseGeocode(
          answer([
            {
              'types': ['route'],
              'formatted_address': 'الجمهورية، اللاذقية، سوريا',
              'address_components': [
                'text',
                {'types': 'route', 'long_name': 'x'},
                {
                  'types': ['route'],
                  'long_name': null,
                },
              ],
            },
          ]),
        ),
        'الجمهورية، اللاذقية',
      );
    });
  });

  group(
    'which failures are persistent (so OpenStreetMap takes over for a while)',
    () {
      Matcher persistent(bool expected) => throwsA(
        isA<PlacesException>().having(
          (e) => e.persistent,
          'persistent',
          expected,
        ),
      );

      for (final entry in const {
        'REQUEST_DENIED': true,
        'OVER_QUERY_LIMIT': true,
        'UNKNOWN_ERROR': false,
        'INVALID_REQUEST': false,
      }.entries) {
        test(
          '${entry.key} is ${entry.value ? '' : 'not '}persistent',
          () async {
            adapter.body = {'status': entry.key};
            await expectLater(google.search('مطار'), persistent(entry.value));
            await expectLater(
              google.reverseGeocode(1, 2),
              persistent(entry.value),
            );
          },
        );
      }

      for (final entry in const {
        401: true,
        403: true,
        429: true,
        500: false,
        503: false,
      }.entries) {
        test(
          'HTTP ${entry.key} is ${entry.value ? '' : 'not '}persistent',
          () async {
            adapter.status = entry.key;
            await expectLater(google.search('مطار'), persistent(entry.value));
            await expectLater(
              google.reverseGeocode(1, 2),
              persistent(entry.value),
            );
          },
        );
      }

      test('a missing key is persistent', () async {
        final noKey = GooglePlacesDataSource(
          credentials: () async => GoogleApiCredentials.none,
          dio: Dio()..httpClientAdapter = adapter,
        );
        await expectLater(noKey.search('مطار'), persistent(true));
      });

      test('a connection that fails is not persistent', () async {
        final broken = GooglePlacesDataSource(
          credentials: () async => const GoogleApiCredentials(apiKey: 'KEY'),
          dio: Dio()..httpClientAdapter = _FailingAdapter(),
        );
        await expectLater(broken.search('مطار'), persistent(false));
      });
    },
  );
}

class _FailingAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async => throw DioException.connectionError(
    requestOptions: options,
    reason: 'offline',
  );

  @override
  void close({bool force = false}) {}
}
