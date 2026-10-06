import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/constants/app_constants.dart';
import 'package:mshoar/core/services/google_routes_service.dart';
import 'package:mshoar/core/services/route_service.dart';

class _FakeAdapter implements HttpClientAdapter {
  final int status;
  final Object body;
  RequestOptions? request;

  _FakeAdapter(this.body, {this.status = 200});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
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

GoogleRoutesService _service(_FakeAdapter adapter, {String apiKey = 'test-key'}) {
  final dio = Dio(BaseOptions(
    baseUrl: AppConstants.googleRoutesBaseUrl,
    contentType: Headers.jsonContentType,
  ))
    ..httpClientAdapter = adapter;
  return GoogleRoutesService(apiKey: apiKey, dio: dio);
}

Future<void> _compute(GoogleRoutesService service) => service.computeRoute(
      fromLat: 35.5,
      fromLng: 35.8,
      toLat: 35.6,
      toLng: 35.9,
    );

void main() {
  const polyline = '_p~iF~ps|U_ulLnnqC_mqNvxq`@';

  test('asks only for distance, duration and line, and parses them', () async {
    final adapter = _FakeAdapter({
      'routes': [
        {
          'distanceMeters': 4210,
          'duration': '845s',
          'polyline': {'encodedPolyline': polyline},
        },
      ],
    });

    final route = await _service(adapter).computeRoute(
      fromLat: 35.5,
      fromLng: 35.8,
      toLat: 35.6,
      toLng: 35.9,
    );

    expect(route.distanceMeters, 4210);
    expect(route.durationSeconds, 845);
    expect(route.points, hasLength(3));

    final request = adapter.request!;
    expect(request.uri.toString(), 'https://routes.googleapis.com/directions/v2:computeRoutes');
    expect(request.headers['X-Goog-Api-Key'], 'test-key');
    expect(
      request.headers['X-Goog-FieldMask'],
      'routes.distanceMeters,routes.duration,routes.polyline.encodedPolyline',
    );
    final body = request.data as Map;
    expect(body['travelMode'], 'DRIVE');
    expect(body['origin'], {
      'location': {
        'latLng': {'latitude': 35.5, 'longitude': 35.8},
      },
    });
  });

  test('a zero distance is omitted by the API and reads as 0', () async {
    final adapter = _FakeAdapter({
      'routes': [
        {
          'polyline': {'encodedPolyline': polyline},
        },
      ],
    });

    final route = await _service(adapter).computeRoute(
      fromLat: 35.5,
      fromLng: 35.8,
      toLat: 35.5,
      toLng: 35.8,
    );

    expect(route.distanceMeters, 0);
    expect(route.durationSeconds, 0);
  });

  test('no key: fails without sending anything', () async {
    final adapter = _FakeAdapter(const {});

    await expectLater(_compute(_service(adapter, apiKey: '')), throwsA(isA<RouteException>()));
    expect(adapter.request, isNull);
  });

  test('a rejected key (403) is a RouteException', () async {
    final adapter = _FakeAdapter({
      'error': {'code': 403, 'message': 'Routes API has not been used in project'},
    }, status: 403);

    await expectLater(_compute(_service(adapter)), throwsA(isA<RouteException>()));
  });

  test('no route found is a RouteException', () async {
    await expectLater(_compute(_service(_FakeAdapter(const {}))), throwsA(isA<RouteException>()));
    await expectLater(
      _compute(_service(_FakeAdapter({'routes': <Object>[]}))),
      throwsA(isA<RouteException>()),
    );
  });
}
