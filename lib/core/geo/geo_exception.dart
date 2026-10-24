/// Why a Geo v2 call did not give an answer.
enum GeoFailure {
  /// A newer request replaced this one: not an error.
  cancelled,

  /// The phone has no connection.
  offline,

  /// 429 `GOOGLE_DAILY_CAP`: the server's daily Google budget is used up.
  googleDailyCap,

  /// 429 `USER_RATE_LIMIT`: this customer asked too much, too fast.
  rateLimited,

  /// 502 `GOOGLE_*` or 503 `GOOGLE_NOT_CONFIGURED`.
  googleUnavailable,

  /// Anything else (a timeout, a 4xx/5xx, an answer that can't be read).
  server,
}

/// A Geo v2 call failed. The callers decide what the customer sees; none of
/// them retries on its own.
class GeoException implements Exception {
  final GeoFailure failure;

  /// What the server said, for the debug log: `429 USER_RATE_LIMIT`,
  /// `404 Not found`… Null when there was no answer to read.
  final String? detail;

  const GeoException(this.failure, {this.detail});

  bool get isCancelled => failure == GeoFailure.cancelled;
  bool get isOffline => failure == GeoFailure.offline;

  @override
  String toString() =>
      'GeoException(${failure.name}${detail == null ? '' : ', $detail'})';
}
