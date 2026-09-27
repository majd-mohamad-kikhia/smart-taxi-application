import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/wallet_transaction_model.dart';
import '../../data/repositories/driver_wallet_repository.dart';
import 'driver_wallet_state.dart';

/// Drives a driver wallet transaction list: infinite-scroll history,
/// optionally filtered to a single [transactionType] (e.g. only fines).
class DriverWalletCubit extends Cubit<DriverWalletState> {
  final DriverWalletRepository _repository;
  final WalletTransactionType? transactionType;

  DriverWalletCubit(this._repository, {this.transactionType})
      : super(const DriverWalletState());

  Future<void> initialize() => _load(1, replace: true);

  /// Re-fetches from page 1 — used by pull-to-refresh.
  Future<void> refresh() => _load(1, replace: true);

  /// Fetches the next page and appends it — used by infinite scroll.
  Future<void> loadMore() {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) {
      return Future.value();
    }
    return _load(state.page + 1, replace: false);
  }

  Future<void> _load(int page, {required bool replace}) async {
    if (isClosed) return;
    emit(
      state.copyWith(
        isLoading: replace && state.transactions.isEmpty,
        isLoadingMore: !replace,
        clearError: true,
      ),
    );
    try {
      final history = await _repository.getWalletHistory(
        page: page,
        transactionType: transactionType,
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          walletBalance: history.walletBalance,
          transactions: replace
              ? history.transactions
              : [...state.transactions, ...history.transactions],
          page: history.page,
          totalPages: history.totalPages,
          total: history.total,
          isLoading: false,
          isLoadingMore: false,
        ),
      );
    } on DriverWalletException catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(isLoading: false, isLoadingMore: false, errorMessage: e.message),
      );
    }
  }
}
