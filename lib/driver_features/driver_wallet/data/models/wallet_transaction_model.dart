import 'package:equatable/equatable.dart';
import '../../../../core/l10n/generated/app_localizations.dart';

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

  String label(AppLocalizations l10n) => switch (this) {
    WalletTransactionType.topup => l10n.txTopup,
    WalletTransactionType.commissionDeduction => l10n.txCommission,
    WalletTransactionType.penalty => l10n.txPenalty,
    WalletTransactionType.compensation => l10n.txCompensation,
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
