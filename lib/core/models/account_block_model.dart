import 'package:equatable/equatable.dart';
import '../utils/parse_utc_date.dart';

/// Whether the signed-in customer or driver may take rides, as sent by the
/// `customer:block_status` / `driver:block_status` socket events and, for a
/// customer, `GET /api/customer/profile/block` (swagger `AccountBlockInfo`).
///
/// A customer is blocked by the manager (`reason_code: manager`) or
/// automatically for 24 hours at the 3rd cancel after a driver accepted
/// (`cancel_strikes`). [cancelStrikes] counts those cancels since the last
/// block.
class AccountBlockModel extends Equatable {
  static const reasonCancelStrikes = 'cancel_strikes';

  final bool isBlocked;

  /// When the block ends (UTC) — the countdown runs to it.
  final DateTime? blockedUntil;

  /// The same end time in Damascus time, ready to show.
  final String? blockedUntilLocal;
  final String? reason;

  /// `cancel_strikes` or `manager`.
  final String? reasonCode;

  /// The server's explanation in the customer's language, ready to show.
  /// Only `GET /profile/block`, a cancel and a refused order carry it.
  final String? message;
  final int cancelStrikes;
  final int strikeLimit;

  /// How long the automatic block lasts.
  final int blockHours;

  const AccountBlockModel({
    required this.isBlocked,
    this.blockedUntil,
    this.blockedUntilLocal,
    this.reason,
    this.reasonCode,
    this.message,
    this.cancelStrikes = 0,
    this.strikeLimit = 0,
    this.blockHours = 0,
  });

  /// The "nothing blocked" value used before the first snapshot arrives.
  static const none = AccountBlockModel(isBlocked: false);

  factory AccountBlockModel.fromJson(Map<String, dynamic> json) {
    return AccountBlockModel(
      isBlocked: json['is_blocked'] == true,
      blockedUntil: _utcOrNull(json['blocked_until']),
      blockedUntilLocal: _textOrNull(json['blocked_until_local']),
      reason: _textOrNull(json['reason']),
      reasonCode: _textOrNull(json['reason_code']),
      message: _textOrNull(json['message']),
      cancelStrikes: (json['cancel_strikes'] as num?)?.toInt() ?? 0,
      strikeLimit: (json['strike_limit'] as num?)?.toInt() ?? 0,
      blockHours: (json['block_hours'] as num?)?.toInt() ?? 0,
    );
  }

  /// The `errors` of a `403` refusing a new order while blocked.
  factory AccountBlockModel.fromOrderRefusal(Map<String, String> errors) {
    return AccountBlockModel(
      isBlocked: true,
      blockedUntil: _utcOrNull(errors['blocked_until']),
      blockedUntilLocal: _textOrNull(errors['blocked_until_local']),
      reason: _textOrNull(errors['block_reason']),
      reasonCode: _textOrNull(errors['reason_code']),
      message: _textOrNull(errors['message']),
    );
  }

  /// One more counted cancel blocks ordering.
  bool get nextCancelBlocks => strikeLimit > 0 && cancelStrikes >= strikeLimit - 1;

  AccountBlockModel copyWith({
    int? cancelStrikes,
    int? strikeLimit,
    int? blockHours,
    String? message,
    bool clearMessage = false,
  }) {
    return AccountBlockModel(
      isBlocked: isBlocked,
      blockedUntil: blockedUntil,
      blockedUntilLocal: blockedUntilLocal,
      reason: reason,
      reasonCode: reasonCode,
      message: clearMessage ? null : (message ?? this.message),
      cancelStrikes: cancelStrikes ?? this.cancelStrikes,
      strikeLimit: strikeLimit ?? this.strikeLimit,
      blockHours: blockHours ?? this.blockHours,
    );
  }

  static DateTime? _utcOrNull(Object? value) =>
      value is String && value.trim().isNotEmpty ? parseUtcDateTime(value.trim()) : null;

  static String? _textOrNull(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  List<Object?> get props => [
    isBlocked,
    blockedUntil,
    blockedUntilLocal,
    reason,
    reasonCode,
    message,
    cancelStrikes,
    strikeLimit,
    blockHours,
  ];
}
