import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/utils/polyline_decoder.dart';

void main() {
  test('decodes the example from the encoded polyline specification', () {
    final points = PolylineDecoder.decode('_p~iF~ps|U_ulLnnqC_mqNvxq`@');

    expect(points.map((p) => (p.lat, p.lng)).toList(), [
      (38.5, -120.2),
      (40.7, -120.95),
      (43.252, -126.453),
    ]);
  });

  test('an empty string is an empty line', () {
    expect(PolylineDecoder.decode(''), isEmpty);
  });

  test('a truncated string drops the half point instead of throwing', () {
    final points = PolylineDecoder.decode('_p~iF~ps|U_ulL');

    expect(points, hasLength(1));
  });
}
