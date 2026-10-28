import 'package:equatable/equatable.dart';

/// The server's note about the customer's wallet on a ride
/// (`wallet_note`: `{ "ar": "...", "en": "..." }`), in both languages.
class WalletNoteModel extends Equatable {
  final String ar;
  final String en;

  const WalletNoteModel({required this.ar, required this.en});

  /// Null when the server sent no usable text.
  static WalletNoteModel? tryParse(Object? json) {
    if (json is! Map) return null;
    final ar = json['ar'];
    final en = json['en'];
    final arText = ar is String ? ar.trim() : '';
    final enText = en is String ? en.trim() : '';
    if (arText.isEmpty && enText.isEmpty) return null;
    return WalletNoteModel(
      ar: arText.isEmpty ? enText : arText,
      en: enText.isEmpty ? arText : enText,
    );
  }

  /// The note in the app's language ([languageCode] is `ar` or `en`).
  String textFor(String languageCode) => languageCode == 'ar' ? ar : en;

  @override
  List<Object?> get props => [ar, en];
}

/// How a ride's price splits between the customer's wallet and cash:
/// `amount_due = price - wallet_used`. The fare, the commission and the
/// driver's earning always follow the full price — only the cash to collect
/// shrinks.
class RideWalletModel extends Equatable {
  /// Taken from the customer's wallet when the trip finished; 0 before then.
  final double walletUsed;

  /// The cash the customer pays the driver.
  final double amountDue;
  final WalletNoteModel? note;

  const RideWalletModel({
    this.walletUsed = 0,
    required this.amountDue,
    this.note,
  });

  /// Part of the price was covered by the wallet.
  bool get isWalletUsed => walletUsed > 0;

  /// Reads `wallet_used`, `amount_due` and `wallet_note` from [json]. An
  /// old server sends none of them: the whole [fallbackPrice] is then due.
  /// Null only when there is neither an `amount_due` nor a price to fall
  /// back on.
  static RideWalletModel? tryParse(
    Map<String, dynamic> json, {
    double? fallbackPrice,
  }) {
    final walletUsed = (json['wallet_used'] as num?)?.toDouble() ?? 0;
    final dueFromServer = (json['amount_due'] as num?)?.toDouble();
    final due =
        dueFromServer ??
        (fallbackPrice == null
            ? null
            : (fallbackPrice - walletUsed).clamp(0, double.infinity));
    if (due == null) return null;
    return RideWalletModel(
      walletUsed: walletUsed,
      amountDue: due.toDouble(),
      note: WalletNoteModel.tryParse(json['wallet_note']),
    );
  }

  @override
  List<Object?> get props => [walletUsed, amountDue, note];
}
