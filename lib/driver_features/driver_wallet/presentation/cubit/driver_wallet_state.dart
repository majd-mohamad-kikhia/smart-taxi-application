import 'package:equatable/equatable.dart';
import '../../data/models/wallet_transaction_model.dart';

/// Immutable state for the driver wallet screen. [transactions] holds the
/// full accumulated list loaded so far, appended to as the user scrolls.
class DriverWalletState extends Equatable {
  final double walletBalance;
  final List<WalletTransactionModel> transactions;
  final int page;
  final int totalPages;
  final int total;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;

  const DriverWalletState({
    this.walletBalance = 0,
    this.transactions = const [],
    this.page = 1,
    this.totalPages = 1,
    this.total = 0,
    this.isLoading = true,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  bool get hasMore => page < totalPages;

  DriverWalletState copyWith({
    double? walletBalance,
    List<WalletTransactionModel>? transactions,
    int? page,
    int? totalPages,
    int? total,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DriverWalletState(
      walletBalance: walletBalance ?? this.walletBalance,
      transactions: transactions ?? this.transactions,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        walletBalance,
        transactions,
        page,
        totalPages,
        total,
        isLoading,
        isLoadingMore,
        errorMessage,
      ];
}
