import 'package:equatable/equatable.dart';
import '../utils/parse_utc_date.dart';

/// `cancel_penalty` in a cancelled ride (REST cancel or the socket cancel
/// ack): the customer cancelled after a driver accepted, so it counted.
/// Null in the ride when the cancel didn't count.
class CancelPenaltyModel extends Equatable {
  final int cancelStrikes;
  final int strikeLimit;
  final int remaining;

  /// This cancel blocked ordering until [blockedUntil].
  final bool blocked;

  /// UTC.
  final DateTime? blockedUntil;

  /// Damascus time, ready to show.
  final String? blockedUntilLocal;
  final int blockHours;

  /// The warning or block text in the customer's language, ready to show.
  final String message;

  const CancelPenaltyModel({
    required this.cancelStrikes,
    required this.strikeLimit,
    required this.remaining,
    required this.blocked,
    required this.message,
    this.blockedUntil,
    this.blockedUntilLocal,
    this.blockHours = 0,
  });

  /// Reads `cancel_penalty` from a ride payload; null when absent, null or
  /// not counted.
  static CancelPenaltyModel? fromRide(Object? ride) {
    if (ride is! Map) return null;
    final json = ride['cancel_penalty'];
    if (json is! Map || json['counted'] != true) return null;
    final until = json['blocked_until'];
    final local = json['blocked_until_local'];
    return CancelPenaltyModel(
      cancelStrikes: (json['cancel_strikes'] as num?)?.toInt() ?? 0,
      strikeLimit: (json['strike_limit'] as num?)?.toInt() ?? 0,
      remaining: (json['remaining'] as num?)?.toInt() ?? 0,
      blocked: json['blocked'] == true,
      blockedUntil: until is String ? parseUtcDateTime(until) : null,
      blockedUntilLocal: local is String && local.trim().isNotEmpty ? local.trim() : null,
      blockHours: (json['block_hours'] as num?)?.toInt() ?? 0,
      message: (json['message'] as String?)?.trim() ?? '',
    );
  }

  @override
  List<Object?> get props => [
    cancelStrikes,
    strikeLimit,
    remaining,
    blocked,
    blockedUntil,
    blockedUntilLocal,
    blockHours,
    message,
  ];
}
