import 'package:equatable/equatable.dart';
import '../models/account_block_model.dart';

/// Server text to show the customer once, in a dialog: the warning after a
/// counted cancel, or why ordering is blocked.
class AccountBlockNotice extends Equatable {
  final String message;
  final bool blocked;

  const AccountBlockNotice({required this.message, required this.blocked});

  @override
  List<Object?> get props => [message, blocked];
}

class AccountBlockState extends Equatable {
  final AccountBlockModel block;

  /// The latest notice; [noticeCount] goes up by one for each new one, so
  /// the same text twice still shows twice.
  final AccountBlockNotice? notice;
  final int noticeCount;

  const AccountBlockState({
    this.block = AccountBlockModel.none,
    this.notice,
    this.noticeCount = 0,
  });

  bool get isBlocked => block.isBlocked;

  AccountBlockState copyWith({AccountBlockModel? block, AccountBlockNotice? notice}) {
    return AccountBlockState(
      block: block ?? this.block,
      notice: notice ?? this.notice,
      noticeCount: notice == null ? noticeCount : noticeCount + 1,
    );
  }

  @override
  List<Object?> get props => [block, notice, noticeCount];
}
