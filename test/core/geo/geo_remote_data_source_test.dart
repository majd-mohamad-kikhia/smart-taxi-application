import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/geo/geo_exception.dart';
import 'package:mshoar/core/geo/geo_models.dart';
import 'package:mshoar/core/geo/geo_remote_data_source.dart';
import 'package:mshoar/core/network/api_endpoints.dart';

/// Our server, in memory: records the requests, answers what the test sets.
class _Server implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  Object body = const {};
  int status = 200;
  DioExceptionType? failure;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final type = failure;
    if (type != null) throw DioException(requestOptions: options, type: type);
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

void main() {
  late _Server server;
  late GeoRemoteDataSource geo;

  setUp(() {
    server = _Server();
    geo = GeoRemoteDataSource(
      Dio(BaseOptions(baseUrl: 'http://test'))..httpClientAdapter = server,
      const ApiEndpoints(),
    );
  });

  group('the requests', () {
    test('suggest', () async {
      server.body = [
        {
          'alias_id': 12,
          'text': 'مشروع ياسين',
          'lat': 35.5,
          'lng': 35.7,
          'has_coords': true,
        },
        {
          'alias_id': 13,
          'text': 'قديم',
          'lat': null,
          'lng': null,
          'has_coords': false,
        },
      ];

      final found = await geo.suggest('ياسين');

      final request = server.requests.single;
      expect(request.method, 'GET');
      expect(request.path, '/api/v2/geo/suggest');
      expect(request.queryParameters, {'q': 'ياسين', 'region': 1});
      expect(found.first.hasCoords, isTrue);
      expect(found.last.hasCoords, isFalse);
      expect(found.last.lat, isNull);
    });

    test('resolve sends the alias id only when given', () async {
      server.body = {'status': 'not_found'};

      await geo.resolve('ياسين');
      await geo.resolve('ياسين', aliasId: 12, forceGoogle: true);

      expect(server.requests[0].data, {
        'q': 'ياسين',
        'region': 1,
        'force_google': false,
      });
      expect(server.requests[1].data, {
        'q': 'ياسين',
        'region': 1,
        'alias_id': 12,
        'force_google': true,
      });
    });

    test('resolve reads ok, did_you_mean and not_found', () async {
      server.body = {
        'status': 'ok',
        'alias_id': 12,
        'text': 'مشروع ياسين',
        'lat': 35.5,
        'lng': 35.7,
        'address': 'عنوان',
        'corrected_to': 'مشروع ياسين',
      };
      final ok = await geo.resolve('x') as GeoResolved;
      expect(
        (ok.aliasId, ok.address, ok.correctedTo),
        (12, 'عنوان', 'مشروع ياسين'),
      );

      server.body = {'status': 'did_you_mean', 'alias_id': 40, 'text': 'مشروع'};
      expect(await geo.resolve('x'), isA<GeoDidYouMean>());

      server.body = {'status': 'not_found'};
      expect(await geo.resolve('x'), isA<GeoNotFound>());
    });

    test('feedback', () async {
      server.body = {'status': 'ok', 'outcome': 'recorded'};
      await geo.sendFeedback(aliasId: 12, accepted: true);
      expect(server.requests.single.path, '/api/v2/geo/resolve/feedback');
      expect(server.requests.single.data, {'alias_id': 12, 'accepted': true});
    });

    test('a failed feedback throws nothing', () async {
      server.status = 404;
      await geo.sendFeedback(aliasId: 12, accepted: true);
    });

    test('reverse gives the label, or null', () async {
      server.body = {
        'street': 'a',
        'area': 'b',
        'label': 'شارع المتنبي، الزراعة',
      };
      expect(await geo.reverse(35.5, 35.8), 'شارع المتنبي، الزراعة');
      expect(server.requests.single.data, {'lat': 35.5, 'lng': 35.8});

      server.body = {'street': null, 'area': null, 'label': null};
      expect(await geo.reverse(35.5, 35.8), isNull);
    });

    test(
      'route-quote asks for the polyline and sends the fare shown',
      () async {
        server.body = {
          'fare': 800,
          'method': 'routes',
          'fare_method': 1,
          'needs_reconfirm': true,
          'polyline': '_p~iF~ps|U_ulLnnqC_mqNvxq`@',
        };

        final quote = await geo.routeQuote(
          fromLat: 35.52,
          fromLng: 35.79,
          toLat: 35.58,
          toLng: 35.83,
          idempotencyKey: 'abcdefgh12345678',
          vehicleTypeId: 6,
          fareEst: 770,
        );

        expect(server.requests.single.path, '/api/v2/geo/route-quote');
        expect(server.requests.single.data, {
          'origin': {'lat': 35.52, 'lng': 35.79},
          'destination': {'lat': 35.58, 'lng': 35.83},
          'idempotency_key': 'abcdefgh12345678',
          'vehicle_type_id': 6,
          'fare_est': 770,
          'include_polyline': true,
        });
        expect(quote.fare, 800);
        expect(quote.needsReconfirm, isTrue);
        expect(quote.route, hasLength(3));
      },
    );

    test('an estimate has no route line', () async {
      server.body = {
        'fare': 770,
        'method': 'estimate',
        'fare_method': 2,
        'needs_reconfirm': false,
      };
      final quote = await geo.routeQuote(
        fromLat: 1,
        fromLng: 1,
        toLat: 2,
        toLng: 2,
        idempotencyKey: 'abcdefgh12345678',
      );
      expect(quote.route, isEmpty);
    });
  });

  group('failures are typed', () {
    Future<GeoFailure> failureOf() async {
      try {
        await geo.resolve('x');
      } on GeoException catch (e) {
        return e.failure;
      }
      fail('expected a GeoException');
    }

    test('429 GOOGLE_DAILY_CAP', () async {
      server
        ..status = 429
        ..body = {'code': 'GOOGLE_DAILY_CAP'};
      expect(await failureOf(), GeoFailure.googleDailyCap);
    });

    test('429 USER_RATE_LIMIT', () async {
      server
        ..status = 429
        ..body = {'code': 'USER_RATE_LIMIT'};
      expect(await failureOf(), GeoFailure.rateLimited);
    });

    test('502 and 503 are Google being unavailable', () async {
      server
        ..status = 502
        ..body = {'code': 'GOOGLE_ERROR'};
      expect(await failureOf(), GeoFailure.googleUnavailable);
      server
        ..status = 503
        ..body = {'code': 'GOOGLE_NOT_CONFIGURED'};
      expect(await failureOf(), GeoFailure.googleUnavailable);
    });

    test('offline, timeouts, validation and unreadable answers', () async {
      server.failure = DioExceptionType.connectionError;
      expect(await failureOf(), GeoFailure.offline);
      server.failure = DioExceptionType.receiveTimeout;
      expect(await failureOf(), GeoFailure.server);
      server
        ..failure = null
        ..status = 422
        ..body = {'errors': {}};
      expect(await failureOf(), GeoFailure.server);
      server
        ..status = 200
        ..body = {'status': 'ok'};
      expect(await failureOf(), GeoFailure.server);
    });
  });
}
