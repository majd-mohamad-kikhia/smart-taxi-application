/// Reads a UTC server time (`YYYY-MM-DD HH:mm:ss`) that carries no zone
/// suffix. A value that already has one is read as it is.
DateTime? parseUtcDateTime(String raw) {
  final hasZone = raw.endsWith('Z') || RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(raw);
  return DateTime.tryParse(hasZone ? raw : '${raw.replaceFirst(' ', 'T')}Z');
}

/// The wall-clock time in Syria (UTC+3 all year, no daylight saving) for a
/// moment in time, whatever zone the phone is set to. The result is a plain
/// (zone-less) [DateTime] meant to be displayed exactly as it is.
DateTime toDamascusTime(DateTime value) {
  final damascus = value.toUtc().add(const Duration(hours: 3));
  return DateTime(
    damascus.year,
    damascus.month,
    damascus.day,
    damascus.hour,
    damascus.minute,
    damascus.second,
  );
}
