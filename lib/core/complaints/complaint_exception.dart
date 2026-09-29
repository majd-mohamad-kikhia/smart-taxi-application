/// Structured failure thrown by any complaint repository, so the shared
/// [ComplaintCubit] never has to interpret a raw exception.
class ComplaintException implements Exception {
  final String message;

  const ComplaintException(this.message);

  @override
  String toString() => message;
}
