import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/models/ride_fare_breakdown_model.dart';
import 'package:mshoar/core/models/ride_pause_model.dart';

final _base = DateTime(2026, 1, 1, 12);

/// A running pause with the spec's example prices: 2000 covers 3 minutes,
/// then 500 per started minute.
RidePauseModel _paused({int elapsed = 0}) => RidePauseModel(
  isPaused: true,
  current: RunningPauseModel(
    elapsedSeconds: elapsed,
    baseFee: 2000,
    includedMinutes: 3,
    pricePerMinute: 500,
  ),
  count: 0,
  totalSeconds: 0,
  totalFee: 0,
  receivedAt: _base,
);

RunningPauseSnapshot _at(RidePauseModel pause, int seconds) =>
    pause.snapshotAt(_base.add(Duration(seconds: seconds)))!;

void main() {
  group('RidePauseModel.snapshotAt (server elapsed + local count-up)', () {
    test('a short pause still costs the base fee', () {
      final s = _at(_paused(), 30);
      expect(s.extraMinutes, 0);
      expect(s.fee, 2000);
      expect(s.includedSecondsLeft, 150);
    });

    test('exactly the included time costs only the base fee', () {
      final s = _at(_paused(), 180);
      expect(s.extraMinutes, 0);
      expect(s.fee, 2000);
      expect(s.isIncluded, isFalse);
    });

    test('one second over charges one started minute', () {
      final s = _at(_paused(), 181);
      expect(s.extraMinutes, 1);
      expect(s.fee, 2500);
    });

    test('5:20 charges three extra minutes', () {
      final s = _at(_paused(), 320);
      expect(s.extraMinutes, 3);
      expect(s.fee, 3500);
    });

    test('counts up from the server elapsed value, not from zero', () {
      final s = _at(_paused(elapsed: 170), 20);
      expect(s.elapsedSeconds, 190);
      expect(s.extraMinutes, 1);
    });

    test('is null when the trip is not paused', () {
      final resumed = RidePauseModel.fromJson({
        'is_paused': false,
        'current': null,
        'count': 1,
        'total_seconds': 320,
        'total_fee': 3500,
      });
      expect(resumed.snapshotAt(DateTime.now()), isNull);
      expect(resumed.totalFee, 3500);
    });
  });

  test('fromParent reads the pause object and tolerates its absence', () {
    final pause = RidePauseModel.fromParent({
      'pause': {
        'is_paused': true,
        'current': {
          'elapsed_seconds': 95,
          'base_fee': 2000,
          'included_minutes': 3,
          'price_per_minute': 500,
        },
        'count': 1,
        'total_seconds': 320,
        'total_fee': 3500,
      },
    });
    expect(pause!.isPaused, isTrue);
    expect(pause.current!.elapsedSeconds, 95);
    expect(pause.count, 1);
    expect(RidePauseModel.fromParent({}), isNull);
    expect(RidePauseModel.fromParent({'pause': null}), isNull);
  });

  test('the bill carries the pause fee, count and time from fare.pauses', () {
    final fare = RideFareBreakdownModel.fromJson({
      'distance_fare': 100000,
      'waiting_fee': 0,
      'pause_fee_total': 10000,
      'pauses': {
        'count': 3,
        'total_seconds': 580,
        'total_fee': 10000,
        'items': [],
      },
      'final_price': 110000,
    });
    expect(fare.pauseFeeTotal, 10000);
    expect(fare.pauseCount, 3);
    expect(fare.pauseTotalSeconds, 580);
    expect(fare.finalPrice, 110000);
  });
}
