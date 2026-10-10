class PlacesException implements Exception {
  final String message;

  const PlacesException(this.message);

  @override
  String toString() => message;
}
