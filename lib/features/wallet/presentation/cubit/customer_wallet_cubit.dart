import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/repositories/customer_wallet_repository.dart';
import 'customer_wallet_state.dart';

class CustomerWalletCubit extends Cubit<CustomerWalletState> {
  final CustomerWalletRepository _repository;

  CustomerWalletCubit(this._repository) : super(CustomerWalletState.initial());

  /// Loads the first page (balance and newest rows), replacing whatever is
  /// shown.
  Future<void> initialize() async {
    if (isClosed) return;
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final page = await _repository.getPage(1);
      if (isClosed) return;
      emit(
        state.copyWith(
          balance: page.balance,
          transactions: page.transactions,
          page: page.page,
          hasMore: page.hasMore,
          isLoading: false,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(isLoading: false, errorMessage: _messageOf(e)));
    }
  }

  /// Reloads the first page without clearing the screen: the rows stay while
  /// it loads (the pull-to-refresh spinner is the only sign), and a failure
  /// with rows on screen is reported once in
  /// [CustomerWalletState.refreshErrorMessage]. Also run when the wallet tab
  /// is opened, so a ride that changed the balance shows at once.
  Future<void> refresh() async {
    if (isClosed || state.isLoading || state.isLoadingMore) return;
    emit(state.copyWith(clearError: true, clearRefreshError: true));
    try {
      final page = await _repository.getPage(1);
      if (isClosed) return;
      emit(
        state.copyWith(
          balance: page.balance,
          transactions: page.transactions,
          page: page.page,
          hasMore: page.hasMore,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      final message = _messageOf(e);
      emit(
        state.transactions.isEmpty
            ? state.copyWith(errorMessage: message)
            : state.copyWith(refreshErrorMessage: message),
      );
    }
  }

  /// Appends the next page. A failure keeps the list and stays retryable.
  Future<void> loadMore() async {
    if (isClosed || state.isLoading || state.isLoadingMore || !state.hasMore) {
      return;
    }
    emit(state.copyWith(isLoadingMore: true, clearError: true));
    try {
      final next = await _repository.getPage(state.page + 1);
      if (isClosed) return;
      emit(
        state.copyWith(
          balance: next.balance,
          transactions: [...state.transactions, ...next.transactions],
          page: next.page,
          hasMore: next.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(isLoadingMore: false, errorMessage: _messageOf(e)));
    }
  }

  String _messageOf(Object error) =>
      error is ApiException ? error.message : AppStrings.current.errUnexpected;
}
