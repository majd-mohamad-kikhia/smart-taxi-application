import 'package:equatable/equatable.dart';
import '../../../../core/models/pickup_eta_model.dart';
import '../../../../core/network/api_exception.dart';

/// The server's answer to `driver:order_accept`.
///
/// Read loosely on purpose: the answer arrives from a socket callback that
/// swallows any exception thrown inside it, which would leave the accept
/// spinner on forever — so an unexpected shape becomes a plain failure
/// instead of an error.
class OrderAcceptResult extends Equatable {
  final bool ok;

  /// On a refusal, the server's text for it (already in the driver's
  /// language), or null when it gave none.
  final String? message;

  /// The refusal is "wallet too low" (`errors.wallet_balance`): nothing was
  /// accepted, the offer is still open, and the driver has to top up first.
  final bool walletTooLow;

  /// The server's time to the pickup for the position sent with the accept;
  /// null when none was sent or the server couldn't work it out.
  final PickupEtaModel? eta;

  const OrderAcceptResult({
    required this.ok,
    this.message,
    this.walletTooLow = false,
    this.eta,
  });

  /// [ack] is the decoded ack: `{ok: true}`, or a refusal as
  /// `{ok: false, error: "text"}` or in the API's error shape
  /// (`{success: false, message, errors: {wallet_balance: "text"}}`, the
  /// `errors` possibly inside `error`).
  factory OrderAcceptResult.fromAck(Object? ack) {
    if (ack is! Map) return const OrderAcceptResult(ok: false);
    if (ack['ok'] == true || ack['success'] == true) {
      return OrderAcceptResult(ok: true, eta: _etaOf(ack));
    }

    final error = ack['error'];
    final errors = ack['errors'] is Map
        ? ack['errors'] as Map
        : (error is Map && error['errors'] is Map ? error['errors'] as Map : null);
    final walletTooLow = errors?.containsKey(ApiException.walletBalanceField) ?? false;
    final walletReason = errors?[ApiException.walletBalanceField];

    return OrderAcceptResult(
      ok: false,
      walletTooLow: walletTooLow,
      message: _text(error) ??
          _text(ack['message']) ??
          (error is Map ? _text(error['message']) : null) ??
          _text(walletReason),
    );
  }

  /// `eta` sits in the accepted ride (`ride.eta`, or `data.eta`); read
  /// loosely, like the rest of the ack.
  static PickupEtaModel? _etaOf(Map ack) {
    for (final holder in [ack['ride'], ack['data'], ack]) {
      if (holder is Map && holder['eta'] != null) {
        return PickupEtaModel.tryParse(holder['eta']);
      }
    }
    return null;
  }

  static String? _text(Object? value) =>
      value is String && value.trim().isNotEmpty ? value : null;

  @override
  List<Object?> get props => [ok, message, walletTooLow, eta];
}
