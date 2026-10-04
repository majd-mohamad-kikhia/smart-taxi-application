/// Reads a UTC server time (`YYYY-MM-DD HH:mm:ss`) that carries no zone
/// suffix. A value that already has one is read as it is.
DateTime? parseUtcDateTime(String raw) {
  final hasZone = raw.endsWith('Z') || RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(raw);
  return DateTime.tryParse(hasZone ? raw : '${raw.replaceFirst(' ', 'T')}Z');
}
