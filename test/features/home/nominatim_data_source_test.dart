import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/features/home/data/datasources/nominatim_data_source.dart';
import 'package:mshoar/features/home/data/places_exception.dart';

class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  int status = 200;
  Object body = <dynamic>[];

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

Map<String, dynamic> _place({
  String? name,
  Map<String, dynamic>? address,
  String? displayName,
  Object lat = '35.4011',
  Object lon = '35.9487',
}) => {
  'lat': lat,
  'lon': lon,
  'name': ?name,
  'address': ?address,
  'display_name': ?displayName,
};

void main() {
  late _Adapter adapter;
  late DateTime now;
  late List<Duration> waits;
  late NominatimDataSource osm;

  setUp(() {
    adapter = _Adapter();
    now = DateTime(2026, 10, 20, 12);
    waits = [];
    osm = NominatimDataSource(
      dio: Dio(BaseOptions(baseUrl: 'https://nominatim.openstreetmap.org'))
        ..httpClientAdapter = adapter,
      now: () => now,
      // Time only moves when the source waits for it.
      delay: (duration) async {
        waits.add(duration);
        final arrival = now.add(duration);
        // Time passes while the source waits, not before it starts to.
        await Future<void>.delayed(Duration.zero);
        if (arrival.isAfter(now)) now = arrival;
      },
    );
  });

  group('the search request', () {
    test(
      'asks Nominatim in Arabic for Syria, leaning to Latakia, and says who is asking',
      () async {
        await osm.search('مطار');

        final request = adapter.requests.single;
        expect(request.uri.host, 'nominatim.openstreetmap.org');
        expect(request.uri.path, '/search');
        final query = request.queryParameters;
        expect(query['q'], 'مطار');
        expect(query['format'], 'jsonv2');
        expect(query['addressdetails'], 1);
        expect(query['limit'], 8);
        expect(query['accept-language'], 'ar');
        expect(query['countrycodes'], 'sy');
        // west,north,east,south — a lean, not a limit.
        expect(query['viewbox'], '35.7,35.95,36.3,35.1');
        expect(query['bounded'], 0);
        expect(request.headers['User-Agent'], contains('com.mshoar.app'));
        expect(request.headers.containsKey('Authorization'), isFalse);
      },
    );

    test('naming a pin asks for a street or a building, in Arabic', () async {
      adapter.body = {
        'address': {'road': 'شارع بغداد'},
      };

      await osm.reverseGeocode(35.52, 35.79);

      final request = adapter.requests.single;
      expect(request.uri.path, '/reverse');
      expect(request.queryParameters['lat'], 35.52);
      expect(request.queryParameters['lon'], 35.79);
      expect(request.queryParameters['zoom'], 18);
      expect(request.queryParameters['accept-language'], 'ar');
      expect(request.headers['User-Agent'], contains('com.mshoar.app'));
    });
  });

  group('the places of a search', () {
    test(
      'the name, then the street, the area and the city, each said once',
      () {
        final places = NominatimDataSource.parseSearch([
          _place(
            name: 'مطار باسل الأسد الدولي',
            address: {
              'road': 'طريق المطار',
              'suburb': 'الحفة',
              'city': 'اللاذقية',
              'country': 'سوريا',
            },
          ),
          // The name is also the city: said once.
          _place(
            name: 'اللاذقية',
            address: {'city': 'اللاذقية'},
            lat: 35.52,
            lon: 35.79,
          ),
        ]);

        expect(places.map((p) => p.description), [
          'مطار باسل الأسد الدولي، طريق المطار، الحفة، اللاذقية',
          'اللاذقية',
        ]);
        expect(places.first.latitude, 35.4011);
        expect(places.first.longitude, 35.9487);
      },
    );

    test('coordinates come as text or as numbers', () {
      final places = NominatimDataSource.parseSearch([
        _place(name: 'أ', lat: 35.1, lon: 36.2),
        _place(name: 'ب', lat: '35.3', lon: '36.4'),
      ]);

      expect(places.map((p) => (p.latitude, p.longitude)), [
        (35.1, 36.2),
        (35.3, 36.4),
      ]);
    });

    test(
      'no address parts: the display name stands in, without the country',
      () {
        final places = NominatimDataSource.parseSearch([
          _place(displayName: 'سوق الجمعة, الدعتور, اللاذقية, سوريا'),
          _place(
            displayName: 'Market, Latakia, Syria',
            lat: '35.6',
            lon: '35.8',
          ),
        ]);

        expect(places.map((p) => p.description), [
          'سوق الجمعة، الدعتور، اللاذقية',
          'Market، Latakia',
        ]);
      },
    );

    test('a place with no location or nothing to call it by is skipped', () {
      final places = NominatimDataSource.parseSearch([
        _place(name: 'بلا موقع', lat: 'x', lon: 'y'),
        _place(),
        'text',
        _place(name: 'جيد'),
      ]);

      expect(places.map((p) => p.description), ['جيد']);
    });

    test('duplicates are dropped and at most the limit is kept', () {
      final places = NominatimDataSource.parseSearch([
        _place(name: 'أ'),
        _place(name: 'أ'),
        for (var i = 0; i < 12; i++) _place(name: 'مكان $i'),
      ], limit: 5);

      expect(places, hasLength(5));
      expect(places.first.description, 'أ');
    });

    test('nothing found is an empty list, not an error', () async {
      adapter.body = <dynamic>[];
      expect(await osm.search('مكان غير موجود'), isEmpty);
    });

    test('a reply that is not a list is a PlacesException', () async {
      adapter.body = {'error': 'x'};
      await expectLater(osm.search('مطار'), throwsA(isA<PlacesException>()));
    });
  });

  group('the address of a pin', () {
    test('street, area and city', () {
      expect(
        NominatimDataSource.parseReverse({
          'address': {
            'road': 'شارع بغداد',
            'neighbourhood': 'الدعتور',
            'city': 'اللاذقية',
          },
        }),
        'شارع بغداد، الدعتور، اللاذقية',
      );
    });

    test('a village or a town counts as the city', () {
      expect(
        NominatimDataSource.parseReverse({
          'address': {'village': 'كسب'},
        }),
        'كسب',
      );
    });

    test('"Unable to geocode" and nonsense are null, never a crash', () {
      expect(
        NominatimDataSource.parseReverse({'error': 'Unable to geocode'}),
        isNull,
      );
      expect(NominatimDataSource.parseReverse(<dynamic>[]), isNull);
      expect(NominatimDataSource.parseReverse({'address': 'text'}), isNull);
      expect(
        NominatimDataSource.parseReverse({'address': <String, dynamic>{}}),
        isNull,
      );
    });

    test('the display name stands in when there are no address parts', () {
      expect(
        NominatimDataSource.parseReverse({
          'display_name': 'شارع الثورة, اللاذقية, سوريا',
        }),
        'شارع الثورة، اللاذقية',
      );
    });
  });

  group('failures', () {
    for (final status in const [429, 500]) {
      test('HTTP $status is a PlacesException', () async {
        adapter.status = status;
        await expectLater(osm.search('مطار'), throwsA(isA<PlacesException>()));
        await expectLater(
          osm.reverseGeocode(1, 2),
          throwsA(isA<PlacesException>()),
        );
      });
    }

    test('a search cancelled before it is sent never goes out', () async {
      final token = CancelToken()..cancel('replaced');

      await expectLater(
        osm.search('مطار', cancelToken: token),
        throwsA(isA<PlacesCancelledException>()),
      );
      expect(adapter.requests, isEmpty);
    });
  });

  group('the usage policy: a request a second', () {
    test('requests are spaced a second apart, none dropped', () async {
      await osm.search('مطار');
      await osm.reverseGeocode(1, 2);
      await osm.search('محطة');

      expect(adapter.requests, hasLength(3));
      // The first goes at once; the next two wait their turn.
      expect(waits, [
        NominatimDataSource.minRequestInterval,
        NominatimDataSource.minRequestInterval,
      ]);
    });

    test(
      'requests asked at the same moment each get their own second',
      () async {
        await Future.wait([
          osm.search('أول'),
          osm.search('ثاني'),
          osm.search('ثالث'),
        ]);

        expect(waits.map((d) => d.inSeconds).toList()..sort(), [1, 2]);
        expect(adapter.requests, hasLength(3));
      },
    );

    test('after a quiet moment the next request goes at once', () async {
      await osm.search('مطار');
      now = now.add(const Duration(seconds: 5));
      await osm.search('محطة');

      expect(waits, isEmpty);
    });

    test('a search cancelled while it waits is never sent', () async {
      await osm.search('مطار');
      final token = CancelToken();
      final waiting = osm.search('محطة', cancelToken: token);
      token.cancel('replaced');

      await expectLater(waiting, throwsA(isA<PlacesCancelledException>()));
      expect(adapter.requests, hasLength(1));
    });
  });
}
