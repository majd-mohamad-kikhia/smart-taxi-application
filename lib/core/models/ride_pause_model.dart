import 'dart:math' as math;
import 'package:equatable/equatable.dart';

/// Pauses during a trip (customer stops for a coffee) — the `pause`
/// object present on every ride payload (swagger `RidePause`).
///
/// The server measures the time and computes every fee; the apps only
/// display it. While [isPaused], [current] carries the running pause with
/// `elapsed_seconds` measured by the server when the payload was sent, so
/// the live value is counted *up* from it with the phone's own stopwatch
/// ([receivedAt]). [count] / [totalSeconds] / [totalFee] cover closed
/// pauses only (final amounts).
class RidePauseModel extends Equatable {
  final bool isPaused;
  final RunningPauseModel? current;
  final int count;
  final int totalSeconds;
  final double totalFee;

  /// Phone time the payload was parsed at — the base for the local count-up.
  final DateTime receivedAt;

  const RidePauseModel({
    required this.isPaused,
    required this.current,
    required this.count,
    required this.totalSeconds,
    required this.totalFee,
    required this.receivedAt,
  });

  factory RidePauseModel.fromJson(Map<String, dynamic> json) {
    final current = json['current'];
    return RidePauseModel(
      isPaused: json['is_paused'] as bool? ?? false,
      current: current is Map
          ? RunningPauseModel.fromJson(Map<String, dynamic>.from(current))
          : null,
      count: (json['count'] as num?)?.toInt() ?? 0,
      totalSeconds: (json['total_seconds'] as num?)?.toInt() ?? 0,
      totalFee: (json['total_fee'] as num?)?.toDouble() ?? 0,
      receivedAt: DateTime.now(),
    );
  }

  /// Parses `json['pause']`, or returns null when it is absent / null.
  static RidePauseModel? fromParent(Map<String, dynamic> json) {
    final pause = json['pause'];
    return pause is Map
        ? RidePauseModel.fromJson(Map<String, dynamic>.from(pause))
        : null;
  }

  /// The running pause as it should read at [now], or null when not paused.
  RunningPauseSnapshot? snapshotAt(DateTime now) {
    final running = current;
    if (!isPaused || running == null) return null;
    final elapsed =
        running.elapsedSeconds + now.difference(receivedAt).inSeconds;
    final includedSeconds = running.includedMinutes * 60;
    final extra = math.max(0, ((elapsed - includedSeconds) / 60).ceil());
    return RunningPauseSnapshot(
      elapsedSeconds: elapsed,
      includedSecondsLeft: math.max(0, includedSeconds - elapsed),
      extraMinutes: extra,
      fee: running.baseFee + extra * running.pricePerMinute,
    );
  }

  @override
  List<Object?> get props => [
    isPaused,
    current,
    count,
    totalSeconds,
    totalFee,
    receivedAt,
  ];
}

/// The pause that is running now — `pause.current`. Its prices were fixed
/// when the driver tapped pause.
class RunningPauseModel extends Equatable {
  final int elapsedSeconds;
  final double baseFee;
  final int includedMinutes;
  final double pricePerMinute;

  const RunningPauseModel({
    required this.elapsedSeconds,
    required this.baseFee,
    required this.includedMinutes,
    required this.pricePerMinute,
  });

  factory RunningPauseModel.fromJson(Map<String, dynamic> json) {
    return RunningPauseModel(
      elapsedSeconds: (json['elapsed_seconds'] as num?)?.toInt() ?? 0,
      baseFee: (json['base_fee'] as num?)?.toDouble() ?? 0,
      includedMinutes: (json['included_minutes'] as num?)?.toInt() ?? 0,
      pricePerMinute: (json['price_per_minute'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    elapsedSeconds,
    baseFee,
    includedMinutes,
    pricePerMinute,
  ];
}

/// A point-in-time view of a running pause, for display only.
class RunningPauseSnapshot extends Equatable {
  final int elapsedSeconds;
  final int includedSecondsLeft;
  final int extraMinutes;
  final double fee;

  const RunningPauseSnapshot({
    required this.elapsedSeconds,
    required this.includedSecondsLeft,
    required this.extraMinutes,
    required this.fee,
  });

  bool get isIncluded => includedSecondsLeft > 0;

  @override
  List<Object?> get props => [
    elapsedSeconds,
    includedSecondsLeft,
    extraMinutes,
    fee,
  ];
}

/// The current pause rules, as sent in `pause_fee` by
/// `POST /api/customer/rides/locations`.
class PauseFeeRulesModel extends Equatable {
  final double baseFee;
  final int includedMinutes;
  final double pricePerMinute;

  const PauseFeeRulesModel({
    required this.baseFee,
    required this.includedMinutes,
    required this.pricePerMinute,
  });

  factory PauseFeeRulesModel.fromJson(Map<String, dynamic> json) {
    return PauseFeeRulesModel(
      baseFee: (json['base_fee'] as num?)?.toDouble() ?? 0,
      includedMinutes: (json['included_minutes'] as num?)?.toInt() ?? 0,
      pricePerMinute: (json['price_per_minute'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Pausing is free until a fee is set.
  bool get isCharged => baseFee > 0 || pricePerMinute > 0;

  @override
  List<Object?> get props => [baseFee, includedMinutes, pricePerMinute];
}
