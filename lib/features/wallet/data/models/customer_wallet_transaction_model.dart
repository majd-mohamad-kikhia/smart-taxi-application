import 'package:equatable/equatable.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/utils/parse_utc_date.dart';

/// Why the customer's wallet moved (`type` of a row of
/// `GET /api/customer/wallet`).
enum CustomerWalletTransactionType {
  /// The driver had no change and left it in the wallet (+).
  driverChange,

  /// The wallet paid part of a ride (−).
  ridePayment,

  /// A correction by the manager (±), explained in the row's note.
  adjustment,

  /// A type this app version does not know yet.
  unknown;

  static CustomerWalletTransactionType fromApi(Object? value) =>
      switch (value) {
        'driver_change' => CustomerWalletTransactionType.driverChange,
        'ride_payment' => CustomerWalletTransactionType.ridePayment,
        'adjustment' => CustomerWalletTransactionType.adjustment,
        _ => CustomerWalletTransactionType.unknown,
      };

  /// The row's title; [rideId] is the ride it belongs to, when it has one.
  String label(AppLocalizations l10n, int? rideId) => switch (this) {
    CustomerWalletTransactionType.driverChange =>
      rideId == null
          ? l10n.walletTxDriverChangeNoRide
          : l10n.walletTxDriverChange(rideId),
    CustomerWalletTransactionType.ridePayment =>
      rideId == null
          ? l10n.walletTxRidePaymentNoRide
          : l10n.walletTxRidePayment(rideId),
    CustomerWalletTransactionType.adjustment => l10n.walletTxAdjustment,
    CustomerWalletTransactionType.unknown => l10n.walletTxOther,
  };
}

/// One row of the customer's wallet history.
class CustomerWalletTransactionModel extends Equatable {
  final int id;
  final CustomerWalletTransactionType type;

  /// Signed: positive adds to the wallet, negative takes from it.
  final double amount;
  final double balanceAfter;
  final int? rideId;

  /// The manager's explanation of an adjustment; null for other rows.
  final String? note;
  final DateTime? createdAt;

  const CustomerWalletTransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    this.rideId,
    this.note,
    this.createdAt,
  });

  factory CustomerWalletTransactionModel.fromJson(Map<String, dynamic> json) {
    final note = json['note'];
    final createdAt = json['created_at'];
    return CustomerWalletTransactionModel(
      id: (json['id'] as num).toInt(),
      type: CustomerWalletTransactionType.fromApi(json['type']),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      balanceAfter: (json['balance_after'] as num?)?.toDouble() ?? 0,
      rideId: (json['ride_id'] as num?)?.toInt(),
      note: note is String && note.trim().isNotEmpty ? note.trim() : null,
      createdAt: createdAt is String ? parseUtcDateTime(createdAt) : null,
    );
  }

  @override
  List<Object?> get props => [
    id,
    type,
    amount,
    balanceAfter,
    rideId,
    note,
    createdAt,
  ];
}
