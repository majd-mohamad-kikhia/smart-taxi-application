import 'package:flutter_bloc/flutter_bloc.dart';
import '../enums/user_role.dart';
import '../models/account_block_model.dart';
import '../network/api_client.dart';
import 'account_block_socket_service.dart';
import 'account_block_state.dart';

/// App-wide "is the signed-in account blocked from rides" state, fed by
/// [AccountBlockSocketService]. Singleton (see injection.dart): started when
/// a rider/driver session begins and stopped on logout, so any screen can
/// read it without owning a connection.
class AccountBlockCubit extends Cubit<AccountBlockState> {
  final AccountBlockSocketService _socketService;
  UserRole? _role;

  AccountBlockCubit(this._socketService) : super(const AccountBlockState());

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
  }

  /// Disconnects and forgets the previous account's block (logout).
  void stop() {
    _role = null;
    _socketService.disconnect();
    if (state.block != AccountBlockModel.none) {
      emit(const AccountBlockState());
    }
  }

  void _onBlockStatus(Map<String, dynamic> data) {
    if (isClosed) return;
    final next = AccountBlockState(block: AccountBlockModel.fromJson(data));
    if (next != state) emit(next);
  }

  @override
  Future<void> close() {
    _socketService.disconnect();
    return super.close();
  }
}
