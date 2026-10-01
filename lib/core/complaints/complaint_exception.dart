class ComplaintException implements Exception {
  final String message;

  const ComplaintException(this.message);

  @override
  String toString() => message;
}
