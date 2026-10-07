import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/features/home/data/datasources/places_remote_data_source.dart';

class _CapturingAdapter implements HttpClientAdapter {
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      jsonEncode({
        'features': [
          {
            'geometry': {'coordinates': [36.28, 33.52]},
            'properties': {'name': 'جامع الروضة', 'city': 'دمشق'},
          },
        ],
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _CapturingAdapter adapter;
  late PlacesRemoteDataSource source;

  setUp(() {
    adapter = _CapturingAdapter();
    source = PlacesRemoteDataSource(
      dio: Dio(BaseOptions(baseUrl: 'https://photon.komoot.io'))..httpClientAdapter = adapter,
    );
  });

  test('a nearby search sends the bias point and a west,south,east,north box', () async {
    final results = await source.autocomplete(
      'جامع الروضة',
      nearLatitude: 33.5,
      nearLongitude: 36.25,
      withinDegrees: 0.5,
      limit: 20,
    );

    final query = adapter.request!.queryParameters;
    expect(query['q'], 'جامع الروضة');
    expect(query['limit'], 20);
    expect(query['lat'], 33.5);
    expect(query['lon'], 36.25);
    expect(query['bbox'], '35.75,33.0,36.75,34.0');
    expect(results.single.latitude, 33.52);
  });

  test('without a box there is no bbox, and the old defaults hold', () async {
    await source.autocomplete('جامع', nearLatitude: 33.5, nearLongitude: 36.25);

    final query = adapter.request!.queryParameters;
    expect(query.containsKey('bbox'), isFalse);
    expect(query['limit'], 8);
  });

  test('a box needs a position to be around', () async {
    await source.autocomplete('جامع', withinDegrees: 0.5);

    expect(adapter.request!.queryParameters.containsKey('bbox'), isFalse);
  });
}
