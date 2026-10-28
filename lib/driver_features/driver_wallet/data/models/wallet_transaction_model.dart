import 'package:equatable/equatable.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/utils/parse_utc_date.dart';

/// Kind of wallet movement — mirrors `WalletTransaction.transaction_type`
/// in swagger.json.
enum WalletTransactionType {
  topup,
  commissionDeduction,
  penalty,
  compensation,
  reward,

  /// The customer's wallet paid part of a fare, so the driver collected less
  /// cash: the company gives that part back to the driver's wallet.
  customerWalletPayment,

  /// The driver kept the customer's change as credit in the customer's
  /// wallet: that cash comes off the driver's wallet.
  customerChange,

  /// A type this app version does not know yet; shown with a generic label
  /// and the sign of its amount.
  unknown;

  static WalletTransactionType fromApi(String value) => switch (value) {
    'topup' => WalletTransactionType.topup,
    'commission_deduction' => WalletTransactionType.commissionDeduction,
    'penalty' => WalletTransactionType.penalty,
    'compensation' => WalletTransactionType.compensation,
    'reward' => WalletTransactionType.reward,
    'customer_wallet_payment' => WalletTransactionType.customerWalletPayment,
    'customer_change' => WalletTransactionType.customerChange,
    _ => WalletTransactionType.unknown,
  };

  String get toApi => switch (this) {
    WalletTransactionType.topup => 'topup',
    WalletTransactionType.commissionDeduction => 'commission_deduction',
    WalletTransactionType.penalty => 'penalty',
    WalletTransactionType.compensation => 'compensation',
    WalletTransactionType.reward => 'reward',
    WalletTransactionType.customerWalletPayment => 'customer_wallet_payment',
    WalletTransactionType.customerChange => 'customer_change',
    WalletTransactionType.unknown => 'unknown',
  };

  String label(AppLocalizations l10n) => switch (this) {
    WalletTransactionType.topup => l10n.txTopup,
    WalletTransactionType.commissionDeduction => l10n.txCommission,
    WalletTransactionType.penalty => l10n.txPenalty,
    WalletTransactionType.compensation => l10n.txCompensation,
    WalletTransactionType.reward => l10n.txReward,
    WalletTransactionType.customerWalletPayment => l10n.txCustomerWalletPayment,
    WalletTransactionType.customerChange => l10n.txCustomerChange,
    WalletTransactionType.unknown => l10n.txOther,
  };

  /// Whether this kind of movement takes money out of the wallet. Decided by
  /// the type, not by the amount's sign, so it reads right whichever way the
  /// server stores a deduction. An [unknown] type has no say: use
  /// [WalletTransactionModel.isDebit], which falls back on the amount's sign.
  bool get isDebit =>
      this == WalletTransactionType.commissionDeduction ||
      this == WalletTransactionType.penalty ||
      this == WalletTransactionType.customerChange;
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

  /// Money out of the wallet. By the type when it is known; for a type this
  /// app does not know, by the sign of the amount.
  bool get isDebit =>
      type == WalletTransactionType.unknown ? amount < 0 : type.isDebit;

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: json['id'] as int,
      type: WalletTransactionType.fromApi(json['transaction_type'] as String),
      amount: (json['amount'] as num).toDouble(),
      balanceAfter: (json['balance_after'] as num).toDouble(),
      description: json['description'] as String?,
      createdAt: parseUtcDateTime(json['created_at'] as String)!,
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
