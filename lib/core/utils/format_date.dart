import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../localization/l10n_context_extension.dart';

/// A server time as a person would say it: "Today, 1:00 PM", "Yesterday,
/// 1:00 PM", otherwise "27 Sep 2026, 1:00 PM", in the active language.
///
/// The server sends its own local time as `YYYY-MM-DD HH:mm:ss`, shown as it
/// is (no zone conversion). A missing value is "—", and anything that does
/// not parse is shown unchanged.
String formatDateTime(BuildContext context, String? raw) {
  if (raw == null || raw.isEmpty) return '—';
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  return formatDateTimeValue(context, parsed);
}

/// Same as [formatDateTime] for a value that is already a [DateTime].
String formatDateTimeValue(BuildContext context, DateTime value) {
  final l10n = context.l10n;
  final locale = Localizations.localeOf(context).toString();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(value.year, value.month, value.day);
  final daysAgo = today.difference(day).inDays;

  if (daysAgo == 0) return l10n.dateToday(DateFormat.jm(locale).format(value));
  if (daysAgo == 1) {
    return l10n.dateYesterday(DateFormat.jm(locale).format(value));
  }
  return DateFormat.yMMMd(locale).add_jm().format(value);
}
