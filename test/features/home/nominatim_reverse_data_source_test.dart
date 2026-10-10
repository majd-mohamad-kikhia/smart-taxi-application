import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/constants/app_constants.dart';
import 'package:mshoar/features/home/data/datasources/nominatim_reverse_data_source.dart';

class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  int status = 200;
  Object body = {
    'name': 'محطة بغداد',
    'display_name':
        'محطة بغداد, شارع الجمهورية, الدباغة, ناحية مركز اللاذقية, منطقة اللاذقية, محافظة اللاذقية, سوريا',
  };

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
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
  late _Adapter adapter;
  late NominatimReverseDataSource source;

  setUp(() {
    adapter = _Adapter();
    source = NominatimReverseDataSource(
      dio: Dio(
        BaseOptions(
          baseUrl: 'https://nominatim.openstreetmap.org',
          headers: {'User-Agent': AppConstants.userAgentPackage},
        ),
      )..httpClientAdapter = adapter,
    );
  });

  test('the place, its street and area; the administrative tail is cut', () async {
    final name = await source.reverseGeocode(35.5268288, 35.790428);

    expect(name, 'محطة بغداد، شارع الجمهورية، الدباغة');
    final request = adapter.requests.single;
    expect(request.queryParameters['lat'], 35.5268288);
    expect(request.queryParameters['lon'], 35.790428);
    expect(request.queryParameters['accept-language'], 'ar');
    expect(request.headers['User-Agent'], AppConstants.userAgentPackage);
    expect(request.headers.containsKey('Authorization'), isFalse);
  });

  test('a short name is kept whole', () {
    expect(NominatimReverseDataSource.shorten({'display_name': 'اللاذقية, سوريا'}), 'اللاذقية، سوريا');
  });

  test('nothing there ({"error": ...} with a 200) is null', () async {
    adapter.body = {'error': 'Unable to geocode'};

    expect(await source.reverseGeocode(0, 0), isNull);
  });

  test('a failing server is null, never an exception', () async {
    adapter.status = 429;

    expect(await source.reverseGeocode(35.5, 35.8), isNull);
  });
}
