import 'package:equatable/equatable.dart';

/// Kind of wallet movement — mirrors `WalletTransaction.transaction_type`
/// in swagger.json.
enum WalletTransactionType {
  topup,
  commissionDeduction,
  penalty,
  compensation;

  static WalletTransactionType fromApi(String value) => switch (value) {
    'topup' => WalletTransactionType.topup,
    'commission_deduction' => WalletTransactionType.commissionDeduction,
    'penalty' => WalletTransactionType.penalty,
    'compensation' => WalletTransactionType.compensation,
    _ => WalletTransactionType.topup,
  };

  String get toApi => switch (this) {
    WalletTransactionType.topup => 'topup',
    WalletTransactionType.commissionDeduction => 'commission_deduction',
    WalletTransactionType.penalty => 'penalty',
    WalletTransactionType.compensation => 'compensation',
  };

  String get label => switch (this) {
    WalletTransactionType.topup => 'شحن رصيد',
    WalletTransactionType.commissionDeduction => 'عمولة',
    WalletTransactionType.penalty => 'غرامة',
    WalletTransactionType.compensation => 'تعويض',
  };
}

/// A single row from `/api/driver/wallet` — mirrors `WalletTransaction`
/// in swagger.json.
class WalletTransactionModel extends Equatable {
  final int id;
  final WalletTransactionType type;
  final double amount;
  final double balanceAfter;
  final String? description;
  final DateTime createdAt;

  const WalletTransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    this.description,
    required this.createdAt,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: json['id'] as int,
      type: WalletTransactionType.fromApi(json['transaction_type'] as String),
      amount: (json['amount'] as num).toDouble(),
      balanceAfter: (json['balance_after'] as num).toDouble(),
      description: json['description'] as String?,
      createdAt: DateTime.parse(
        (json['created_at'] as String).replaceFirst(' ', 'T'),
      ),
    );
  }

  @override
  List<Object?> get props => [
    id,
    type,
    amount,
    balanceAfter,
    description,
    createdAt,
  ];
}
