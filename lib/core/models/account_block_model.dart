import 'package:equatable/equatable.dart';

/// A customer's or driver's manager-imposed ride block, as pushed by the
/// `customer:block_status` / `driver:block_status` socket events (identical
/// payload for both roles).
class AccountBlockModel extends Equatable {
  final bool isBlocked;

  /// When the block ends. Server time as sent (`2026-10-02 10:19:00`, no
  /// zone) — shown as-is, like the app's other server timestamps.
  final DateTime? blockedUntil;
  final String? reason;
  final int cancelStrikes;
  final int strikeLimit;

  const AccountBlockModel({
    required this.isBlocked,
    this.blockedUntil,
    this.reason,
    this.cancelStrikes = 0,
    this.strikeLimit = 0,
  });

  /// The "nothing blocked" value used before the first snapshot arrives.
  static const none = AccountBlockModel(isBlocked: false);

  factory AccountBlockModel.fromJson(Map<String, dynamic> json) {
    final until = json['blocked_until'] as String?;
    final reason = (json['reason'] as String?)?.trim();
    return AccountBlockModel(
      isBlocked: json['is_blocked'] == true,
      blockedUntil: until == null ? null : DateTime.tryParse(until),
      reason: reason == null || reason.isEmpty ? null : reason,
      cancelStrikes: (json['cancel_strikes'] as num?)?.toInt() ?? 0,
      strikeLimit: (json['strike_limit'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    isBlocked,
    blockedUntil,
    reason,
    cancelStrikes,
    strikeLimit,
  ];
}
