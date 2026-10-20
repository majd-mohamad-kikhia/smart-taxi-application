class PlacesException implements Exception {
  final String message;

  /// Google's own status when it refused or failed the request
  /// (`OVER_QUERY_LIMIT`, `REQUEST_DENIED`…); null for a failure on this side.
  final String? status;

  /// The cause will not go away by trying again soon — a refused or
  /// over-quota key, a missing key — as opposed to a dropped connection or a
  /// slow answer. The fallback uses it to stop asking a source that keeps
  /// refusing.
  final bool persistent;

  const PlacesException(this.message, {this.status, this.persistent = false});

  @override
  String toString() => message;
}

/// The search was cancelled because a newer one replaced it. Not a failure:
/// the screen that asked has moved on to the newer search and ignores this.
class PlacesCancelledException extends PlacesException {
  const PlacesCancelledException() : super('');
}
