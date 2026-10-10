class RouteException implements Exception {
  final String message;

  const RouteException(this.message);

  @override
  String toString() => message;
}
