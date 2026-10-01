import 'dart:math' as math;
import 'package:equatable/equatable.dart';

/// Waiting-at-pickup info — the `waiting` object on every ride payload
/// (socket events, driver acks, REST ride responses; see swagger
/// `RideWaiting`). `null` on the ride means the driver never tapped
/// "arrived".
///
/// The server measures the time and computes the fee; the apps only
/// display it. While [isRunning], [elapsedSeconds] was measured by the
/// server when the payload was sent, so the live value is counted *up*
/// from it with the phone's own stopwatch ([receivedAt]) — correct even
/// with a wrong phone clock or timezone. Once the trip starts, the
/// server's final [fee] replaces any local value.
class RideWaitingModel extends Equatable {
  final int freeMinutes;
  final double pricePerMinute;
  final bool isRunning;
  final int elapsedSeconds;
  final int billableMinutes;
  final double fee;

  /// Phone time the payload was parsed at — the base for the local count-up.
  final DateTime receivedAt;

  const RideWaitingModel({
    required this.freeMinutes,
    required this.pricePerMinute,
    required this.isRunning,
    required this.elapsedSeconds,
    required this.billableMinutes,
    required this.fee,
    required this.receivedAt,
  });

  factory RideWaitingModel.fromJson(Map<String, dynamic> json) {
    return RideWaitingModel(
      freeMinutes: (json['free_minutes'] as num?)?.toInt() ?? 0,
      pricePerMinute: (json['price_per_minute'] as num?)?.toDouble() ?? 0,
      isRunning: json['is_running'] as bool? ?? false,
      elapsedSeconds: (json['elapsed_seconds'] as num?)?.toInt() ?? 0,
      billableMinutes: (json['billable_minutes'] as num?)?.toInt() ?? 0,
      fee: (json['fee'] as num?)?.toDouble() ?? 0,
      receivedAt: DateTime.now(),
    );
  }

  /// Parses `json['waiting']`, or returns null when it is absent / null.
  static RideWaitingModel? fromParent(Map<String, dynamic> json) {
    final waiting = json['waiting'];
    return waiting is Map
        ? RideWaitingModel.fromJson(Map<String, dynamic>.from(waiting))
        : null;
  }

  /// What to show at [now]. While running, counts up from the server's
  /// [elapsedSeconds]; otherwise it is the server's final numbers.
  RideWaitingSnapshot snapshotAt(DateTime now) {
    if (!isRunning) {
      return RideWaitingSnapshot(
        elapsedSeconds: elapsedSeconds,
        freeSecondsLeft: 0,
        billableMinutes: billableMinutes,
        fee: fee,
      );
    }
    final elapsed = elapsedSeconds + now.difference(receivedAt).inSeconds;
    final freeSeconds = freeMinutes * 60;
    final billable = math.max(0, ((elapsed - freeSeconds) / 60).ceil());
    return RideWaitingSnapshot(
      elapsedSeconds: elapsed,
      freeSecondsLeft: math.max(0, freeSeconds - elapsed),
      billableMinutes: billable,
      fee: billable * pricePerMinute,
    );
  }

  @override
  List<Object?> get props => [
    freeMinutes,
    pricePerMinute,
    isRunning,
    elapsedSeconds,
    billableMinutes,
    fee,
    receivedAt,
  ];
}

/// A point-in-time view of [RideWaitingModel], for display only.
class RideWaitingSnapshot extends Equatable {
  final int elapsedSeconds;
  final int freeSecondsLeft;
  final int billableMinutes;
  final double fee;

  const RideWaitingSnapshot({
    required this.elapsedSeconds,
    required this.freeSecondsLeft,
    required this.billableMinutes,
    required this.fee,
  });

  bool get isFree => freeSecondsLeft > 0;

  @override
  List<Object?> get props => [
    elapsedSeconds,
    freeSecondsLeft,
    billableMinutes,
    fee,
  ];
}

/// Free minutes + price per started minute — the current rules, as sent
/// in `waiting_fee` by `POST /api/customer/rides/locations`.
class WaitingFeeRulesModel extends Equatable {
  final int freeMinutes;
  final double pricePerMinute;

  const WaitingFeeRulesModel({
    required this.freeMinutes,
    required this.pricePerMinute,
  });

  factory WaitingFeeRulesModel.fromJson(Map<String, dynamic> json) {
    return WaitingFeeRulesModel(
      freeMinutes: (json['free_minutes'] as num?)?.toInt() ?? 0,
      pricePerMinute: (json['price_per_minute'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Waiting is free when no price has been set.
  bool get isCharged => pricePerMinute > 0;

  @override
  List<Object?> get props => [freeMinutes, pricePerMinute];
}
