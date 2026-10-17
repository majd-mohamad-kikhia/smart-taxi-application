/// A number field of a report reply; a missing or null one counts as 0.
double reportNum(Object? value) => (value as num?)?.toDouble() ?? 0;

/// A text field of a report reply; empty or missing text is null.
String? reportText(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
