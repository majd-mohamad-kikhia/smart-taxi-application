/// Structured error model returned by the data layer.
///
/// Every failure that reaches a Bloc/Cubit is an [ApiException] — never a
/// raw `DioException` — so the UI always has a user-presentable message
/// and, for 409/422 responses, the per-field reasons from swagger's
/// `ErrorResponse.errors` object.
class ApiException implements Exception {
  /// The `errors` key of the refusal a driver with too little in the wallet
  /// gets wherever an order is accepted (403).
  static const String walletBalanceField = 'wallet_balance';

  final String message;
  final int? statusCode;

  /// Per-field validation messages, e.g. `{"phone_number": "..."}`, as
  /// documented in swagger.json's `ErrorResponse.errors`. Only present
  /// for validation (422) and conflict (409) responses.
  final Map<String, String>? fieldErrors;

  /// The same `errors` object as the API sent it, untranslated. Some values
  /// are codes the app branches on (`availability: taken`) — never shown.
  /// The exception is an ordering block's `message`, which the server
  /// already wrote in the customer's language.
  final Map<String, String>? rawErrors;

  const ApiException(
    this.message, {
    this.statusCode,
    this.fieldErrors,
    this.rawErrors,
  });

  /// The server refused because the driver's wallet is too low. Recognised
  /// by the `errors.wallet_balance` key, never by the message (which is in
  /// the driver's language, and the limit behind it can change).
  bool get isWalletTooLow => rawErrors?.containsKey(walletBalanceField) ?? false;

  @override
  String toString() => message;
}
