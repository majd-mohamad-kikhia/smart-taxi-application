import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/models/trip_eta_model.dart';

void main() {
  test('rounds to the steps of the label so unchanged labels are equal states', () {
    final a = TripEtaModel.fromRemaining(meters: 2312, seconds: 301);
    final b = TripEtaModel.fromRemaining(meters: 2338, seconds: 322);

    expect(a, const TripEtaModel(distanceMeters: 2300, minutes: 5));
    expect(b, a);
  });

  test('under a kilometer the distance goes in steps of 50 m', () {
    expect(
      TripEtaModel.fromRemaining(meters: 374, seconds: 90).distanceMeters,
      350,
    );
  });

  test('never shows less than a minute', () {
    expect(TripEtaModel.fromRemaining(meters: 10, seconds: 4).minutes, 1);
    expect(TripEtaModel.fromRemaining(meters: 0, seconds: 0).minutes, 1);
  });
}
