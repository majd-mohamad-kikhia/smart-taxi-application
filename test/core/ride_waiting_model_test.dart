import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/models/ride_waiting_model.dart';

RideWaitingModel _running({required int elapsed, DateTime? at}) =>
    RideWaitingModel(
      freeMinutes: 3,
      pricePerMinute: 500,
      isRunning: true,
      elapsedSeconds: elapsed,
      billableMinutes: 0,
      fee: 0,
      receivedAt: at ?? DateTime(2026, 1, 1, 12),
    );

void main() {
  final base = DateTime(2026, 1, 1, 12);

  group('RideWaitingModel.snapshotAt (server elapsed + local count-up)', () {
    test('inside the free period costs nothing', () {
      final s = _running(
        elapsed: 0,
      ).snapshotAt(base.add(const Duration(seconds: 160)));
      expect(s.billableMinutes, 0);
      expect(s.fee, 0);
      expect(s.freeSecondsLeft, 20);
    });

    test('exactly the free period costs nothing', () {
      final s = _running(
        elapsed: 0,
      ).snapshotAt(base.add(const Duration(seconds: 180)));
      expect(s.billableMinutes, 0);
      expect(s.freeSecondsLeft, 0);
    });

    test('one second over charges one started minute', () {
      final s = _running(
        elapsed: 0,
      ).snapshotAt(base.add(const Duration(seconds: 181)));
      expect(s.billableMinutes, 1);
      expect(s.fee, 500);
    });

    test('5:10 charges three minutes', () {
      final s = _running(
        elapsed: 0,
      ).snapshotAt(base.add(const Duration(seconds: 310)));
      expect(s.billableMinutes, 3);
      expect(s.fee, 1500);
    });

    test('counts up from the server elapsed value, not from zero', () {
      final s = _running(
        elapsed: 140,
      ).snapshotAt(base.add(const Duration(seconds: 50)));
      expect(s.elapsedSeconds, 190);
      expect(s.billableMinutes, 1);
    });

    test('a stopped timer returns the server final numbers', () {
      final stopped = RideWaitingModel.fromJson({
        'is_running': false,
        'elapsed_seconds': 310,
        'free_minutes': 3,
        'price_per_minute': 500,
        'billable_minutes': 3,
        'fee': 1500,
      });
      final s = stopped.snapshotAt(
        DateTime.now().add(const Duration(hours: 1)),
      );
      expect(s.elapsedSeconds, 310);
      expect(s.fee, 1500);
    });
  });

  test('fromParent returns null when waiting is null or missing', () {
    expect(RideWaitingModel.fromParent({'waiting': null}), isNull);
    expect(RideWaitingModel.fromParent({}), isNull);
  });
}
