import 'package:equatable/equatable.dart';
import '../../data/models/customer_wallet_transaction_model.dart';

class CustomerWalletState extends Equatable {
  /// Null until the first page has loaded.
  final double? balance;
  final List<CustomerWalletTransactionModel> transactions;
  final int page;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;

  /// Why the last pull-to-refresh failed while rows were on screen; shown
  /// once, and the rows stay. Kept apart from [errorMessage], which the list
  /// would show as a "load more failed" footer.
  final String? refreshErrorMessage;

  const CustomerWalletState({
    this.balance,
    required this.transactions,
    required this.page,
    required this.hasMore,
    required this.isLoading,
    required this.isLoadingMore,
    this.errorMessage,
    this.refreshErrorMessage,
  });

  factory CustomerWalletState.initial() {
    return const CustomerWalletState(
      transactions: [],
      page: 0,
      hasMore: false,
      isLoading: true,
      isLoadingMore: false,
    );
  }

  CustomerWalletState copyWith({
    double? balance,
    List<CustomerWalletTransactionModel>? transactions,
    int? page,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
    String? refreshErrorMessage,
    bool clearRefreshError = false,
  }) {
    return CustomerWalletState(
      balance: balance ?? this.balance,
      transactions: transactions ?? this.transactions,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      refreshErrorMessage: clearRefreshError
          ? null
          : (refreshErrorMessage ?? this.refreshErrorMessage),
    );
  }

  @override
  List<Object?> get props => [
    balance,
    transactions,
    page,
    hasMore,
    isLoading,
    isLoadingMore,
    errorMessage,
    refreshErrorMessage,
  ];
}
