import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/services/osm_routes_service.dart';
import 'package:mshoar/core/services/route_exception.dart';

class _FakeAdapter implements HttpClientAdapter {
  final int status;
  final Object body;
  RequestOptions? request;
  int calls = 0;

  _FakeAdapter(this.body, {this.status = 200});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    calls++;
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

OsmRoutesService _service(_FakeAdapter adapter) => OsmRoutesService(
  dio: Dio(BaseOptions(baseUrl: 'https://osrm.test'))
    ..httpClientAdapter = adapter,
);

void main() {
  const polyline = '_p~iF~ps|U_ulLnnqC_mqNvxq`@';

  test('asks for the road with longitude first, and parses line, distance and time', () async {
    final adapter = _FakeAdapter({
      'code': 'Ok',
      'routes': [
        {'geometry': polyline, 'distance': 4210.5, 'duration': 845.2},
      ],
    });

    final route = await _service(adapter).computeRoute(
      fromLat: 35.5,
      fromLng: 35.8,
      toLat: 35.6,
      toLng: 35.9,
    );

    expect(adapter.request!.path, '/route/v1/driving/35.8,35.5;35.9,35.6');
    expect(adapter.request!.queryParameters['geometries'], 'polyline');
    expect(adapter.request!.queryParameters['overview'], 'full');
    expect(route.points, hasLength(3));
    expect(route.distanceMeters, 4210.5);
    expect(route.durationSeconds, 845.2);
  });

  test('no route found is a RouteException', () async {
    final adapter = _FakeAdapter({'code': 'NoRoute', 'routes': []});
    await expectLater(
      _service(adapter).computeRoute(
        fromLat: 35.5, fromLng: 35.8, toLat: 35.6, toLng: 35.9,
      ),
      throwsA(isA<RouteException>()),
    );
  });

  test('a server error is a RouteException', () async {
    final adapter = _FakeAdapter({'message': 'busy'}, status: 429);
    await expectLater(
      _service(adapter).computeRoute(
        fromLat: 35.5, fromLng: 35.8, toLat: 35.6, toLng: 35.9,
      ),
      throwsA(isA<RouteException>()),
    );
  });
}
