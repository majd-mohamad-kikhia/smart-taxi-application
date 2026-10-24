import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/geo/geo_exception.dart';
import 'package:mshoar/features/home/data/pin_label_resolver.dart';

void main() {
  late int calls;
  late PinLabelResolver resolver;

  // One degree of latitude is about 111.2 km: 0.00009 is 10 m, 0.0018 is 200 m.
  const lat = 35.5;
  const lng = 35.8;

  setUp(() {
    calls = 0;
    resolver = PinLabelResolver(
      (lat, lng) async => 'label ${++calls}',
      minGap: Duration.zero,
    );
  });

  test('the first label sends one request', () async {
    expect(await resolver.resolve(lat, lng), 'label 1');
    expect(calls, 1);
    expect(resolver.requestCount, 1);
  });

  test('a 10 m move reuses the label and sends no request', () async {
    await resolver.resolve(lat, lng);
    expect(await resolver.resolve(lat + 0.00009, lng), 'label 1');
    expect(calls, 1);
  });

  test('a 200 m move sends one request', () async {
    await resolver.resolve(lat, lng);
    expect(await resolver.resolve(lat + 0.0018, lng), 'label 2');
    expect(calls, 2);
  });

  test('two asks for one spot at once send one request', () async {
    final both = await Future.wait([
      resolver.resolve(lat, lng),
      resolver.resolve(lat, lng),
    ]);
    expect(both, ['label 1', 'label 1']);
    expect(calls, 1);
  });

  test('a failure gives no label and is not remembered', () async {
    var fail = true;
    final failing = PinLabelResolver((lat, lng) async {
      if (fail) throw const GeoException(GeoFailure.rateLimited);
      return 'ok';
    }, minGap: Duration.zero);

    expect(await failing.resolve(lat, lng), isNull);
    fail = false;
    expect(await failing.resolve(lat, lng), 'ok');
  });

  test('no label from the server is not remembered either', () async {
    String? answer;
    final empty = PinLabelResolver(
      (lat, lng) async => answer,
      minGap: Duration.zero,
    );

    expect(await empty.resolve(lat, lng), isNull);
    answer = 'later';
    expect(await empty.resolve(lat, lng), 'later');
  });

  test(
    'two labels asked at once are spaced, so the server never refuses one',
    () async {
      final times = <DateTime>[];
      final spaced = PinLabelResolver((lat, lng) async {
        times.add(DateTime.now());
        return 'x';
      }, minGap: const Duration(milliseconds: 120));

      await Future.wait([
        spaced.resolve(lat, lng),
        spaced.resolve(lat + 0.01, lng),
      ]);

      expect(times, hasLength(2));
      expect(
        times[1].difference(times[0]).inMilliseconds,
        greaterThanOrEqualTo(100),
      );
    },
  );

  test('the distance is haversine, in meters', () {
    final d = PinLabelResolver.distanceMeters(lat, lng, lat + 0.00009, lng);
    expect(d, closeTo(10, 0.5));
  });
}
