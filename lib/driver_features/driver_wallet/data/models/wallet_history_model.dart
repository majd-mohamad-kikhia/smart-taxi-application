import 'package:equatable/equatable.dart';
import 'wallet_transaction_model.dart';

/// One page of the driver's wallet history — mirrors `WalletHistoryData`
/// in swagger.json.
class WalletHistoryModel extends Equatable {
  final double walletBalance;
  final List<WalletTransactionModel> transactions;
  final int page;
  final int totalPages;
  final int total;

  const WalletHistoryModel({
    required this.walletBalance,
    required this.transactions,
    required this.page,
    required this.totalPages,
    required this.total,
  });

  factory WalletHistoryModel.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'] as Map<String, dynamic>;
    return WalletHistoryModel(
      walletBalance: (json['wallet_balance'] as num).toDouble(),
      transactions: (json['transactions'] as List)
          .map((e) => WalletTransactionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: pagination['page'] as int,
      totalPages: pagination['total_pages'] as int,
      total: pagination['total'] as int,
    );
  }

  @override
  List<Object?> get props => [walletBalance, transactions, page, totalPages, total];
}
