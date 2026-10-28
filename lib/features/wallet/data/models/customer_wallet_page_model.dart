import 'package:equatable/equatable.dart';
import 'customer_wallet_transaction_model.dart';

/// One page of `GET /api/customer/wallet`: the balance and a page of the
/// history, newest first.
class CustomerWalletPageModel extends Equatable {
  final double balance;
  final List<CustomerWalletTransactionModel> transactions;
  final int page;
  final int totalPages;

  const CustomerWalletPageModel({
    required this.balance,
    required this.transactions,
    required this.page,
    required this.totalPages,
  });

  bool get hasMore => page < totalPages;

  factory CustomerWalletPageModel.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'];
    final paging = pagination is Map ? pagination : const {};
    return CustomerWalletPageModel(
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      transactions: (json['transactions'] as List? ?? const [])
          .map(
            (t) => CustomerWalletTransactionModel.fromJson(
              Map<String, dynamic>.from(t as Map),
            ),
          )
          .toList(),
      page: (paging['page'] as num?)?.toInt() ?? 1,
      totalPages: (paging['total_pages'] as num?)?.toInt() ?? 1,
    );
  }

  @override
  List<Object?> get props => [balance, transactions, page, totalPages];
}
