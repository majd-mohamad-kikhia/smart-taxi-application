import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../enums/user_role.dart';
import '../models/account_block_model.dart';
import '../models/cancel_penalty_model.dart';
import '../network/api_client.dart';
import 'account_block_push.dart';
import 'account_block_repository.dart';
import 'account_block_socket_service.dart';
import 'account_block_state.dart';

/// App-wide "may the signed-in account take rides" state. Singleton (see
/// injection.dart): started when a customer/driver session begins and
/// stopped on logout, so any screen can read it without owning a connection.
///
/// Fed by the always-on block socket for both roles. For a customer it is
/// also loaded from `GET /api/customer/profile/block` — on start, on resume,
/// after a block push or socket event, and when the block should have
/// ended — and updated at once by a counted cancel or a refused order.
class AccountBlockCubit extends Cubit<AccountBlockState> {
  static const _expiryGrace = Duration(seconds: 2);
  static const _expiryRetry = Duration(seconds: 30);

  final AccountBlockSocketService _socketService;
  final AccountBlockRepository _repository;
  late final StreamSubscription<AccountBlockPush> _pushSubscription;
  UserRole? _role;
  Timer? _expiryTimer;
  bool _refreshing = false;
  bool _refreshAgain = false;
  bool _notifyAfterRefresh = false;

  AccountBlockCubit(
    this._socketService,
    this._repository,
    Stream<AccountBlockPush> pushes,
  ) : super(const AccountBlockState()) {
    _pushSubscription = pushes.listen(
      (push) => refresh(notifyIfBlocked: push.opened),
    );
  }

  bool get _isCustomer => _role == UserRole.customer;

  /// Connects for [role]. No-op if already running for that role or there is
  /// no auth token yet. [onAppVersionChanged] is forwarded for the
  /// `app:version_changed` event that rides on the same connection.
  void start(UserRole role, {required void Function() onAppVersionChanged}) {
    if (_role == role) return;
    final token = ApiClient.authToken;
    if (token == null || token.isEmpty) return;

    _role = role;
    _socketService.connect(
      accessToken: token,
      role: role,
      onBlockStatus: _onBlockStatus,
      onAppVersionChanged: onAppVersionChanged,
    );
    refresh();
  }

  /// Disconnects and forgets the previous account's block (logout).
  void stop() {
    _role = null;
    _expiryTimer?.cancel();
    _socketService.disconnect();
    if (state != const AccountBlockState()) {
      emit(const AccountBlockState());
    }
  }

  /// Loads the customer's block from the server. With [notifyIfBlocked]
  /// (a block push was tapped) the block text is also shown in a dialog.
  /// Calls made while one is running are folded into one more load.
  Future<void> refresh({bool notifyIfBlocked = false}) async {
    if (!_isCustomer || isClosed) return;
    _notifyAfterRefresh |= notifyIfBlocked;
    if (_refreshing) {
      _refreshAgain = true;
      return;
    }
    _refreshing = true;
    try {
      final block = await _repository.fetchCustomerBlock();
      if (!_isCustomer || isClosed) return;
      final notify = _notifyAfterRefresh;
      _notifyAfterRefresh = false;
      final message = block.message;
      _apply(
        block,
        notice: notify && block.isBlocked && message != null
            ? AccountBlockNotice(message: message, blocked: true)
            : null,
      );
    } on AccountBlockException catch (e) {
      // The last known state stays; the next start / resume / event retries.
      debugPrint('AccountBlockCubit: block status not loaded: $e');
    } finally {
      _refreshing = false;
      if (_refreshAgain) {
        _refreshAgain = false;
        unawaited(refresh());
      }
    }
  }

  /// A cancel after a driver accepted: shows the server's warning, and
  /// blocks ordering at once when this was the last allowed one.
  void applyCancelPenalty(CancelPenaltyModel penalty) {
    if (isClosed) return;
    final current = state.block;
    final block = penalty.blocked
        ? AccountBlockModel(
            isBlocked: true,
            blockedUntil: penalty.blockedUntil,
            blockedUntilLocal: penalty.blockedUntilLocal,
            reasonCode: AccountBlockModel.reasonCancelStrikes,
            message: penalty.message.isEmpty ? null : penalty.message,
            strikeLimit: penalty.strikeLimit,
            blockHours: penalty.blockHours,
          )
        : current.copyWith(
            cancelStrikes: penalty.cancelStrikes,
            strikeLimit: penalty.strikeLimit,
            blockHours: penalty.blockHours,
          );
    _apply(
      block,
      notice: penalty.message.isEmpty
          ? null
          : AccountBlockNotice(message: penalty.message, blocked: penalty.blocked),
    );
  }

  /// The server refused a new order because ordering is blocked.
  void applyOrderRefusal(AccountBlockModel refusal) {
    if (isClosed) return;
    final message = refusal.message;
    _apply(
      refusal.copyWith(
        cancelStrikes: state.block.cancelStrikes,
        strikeLimit: state.block.strikeLimit,
        blockHours: state.block.blockHours,
      ),
      notice: message == null ? null : AccountBlockNotice(message: message, blocked: true),
    );
    refresh();
  }

  void _onBlockStatus(Map<String, dynamic> data) {
    if (isClosed) return;
    final current = state.block;
    final pushed = AccountBlockModel.fromJson(data);
    // `snapshot` has no strike count, and no event carries the block text.
    final sameBlock = pushed.isBlocked &&
        current.isBlocked &&
        pushed.blockedUntil == current.blockedUntil;
    final next = pushed.copyWith(
      cancelStrikes: data.containsKey('cancel_strikes') ? null : current.cancelStrikes,
      strikeLimit: data.containsKey('strike_limit') ? null : current.strikeLimit,
      blockHours: current.blockHours,
      message: sameBlock ? current.message : null,
    );
    final changed = next != current;
    _apply(next);
    if (changed || data['action'] != 'snapshot') refresh();
  }

  void _apply(AccountBlockModel block, {AccountBlockNotice? notice}) {
    final next = state.copyWith(block: block, notice: notice);
    if (next != state) emit(next);
    _scheduleExpiryCheck();
  }

  /// Asks the server again once the block should be over, in case the
  /// socket's `expired` doesn't arrive (offline, app was asleep).
  void _scheduleExpiryCheck() {
    _expiryTimer?.cancel();
    final until = state.block.blockedUntil;
    if (!_isCustomer || !state.isBlocked || until == null) return;
    final left = until.difference(DateTime.now().toUtc());
    _expiryTimer = Timer(
      left.isNegative ? _expiryRetry : left + _expiryGrace,
      refresh,
    );
  }

  @override
  Future<void> close() {
    _expiryTimer?.cancel();
    _pushSubscription.cancel();
    _socketService.disconnect();
    return super.close();
  }
}
