import 'package:intl/intl.dart';
import '../l10n/generated/app_localizations.dart';

/// A price as whole units with a thousands separator ("25,000"), so a long
/// fare is readable at a glance. Latin digits in both languages, to match
/// the rest of the app's numbers. Wrap with `l10n.priceSyp(...)` to add the
/// currency.
String formatPrice(num value) =>
    NumberFormat.decimalPattern('en').format(value.round());

final String _minusSign = String.fromCharCode(0x2212);
final String _ltrIsolateStart = String.fromCharCode(0x2066);
final String _ltrIsolateEnd = String.fromCharCode(0x2069);

/// A price with its currency and a sign: "−5,000 SYP", or "+5,000 SYP" with
/// [showPlus]. The sign is a real minus, and the whole amount is isolated
/// left-to-right so the sign stays attached to the number inside Arabic text
/// instead of drifting to the other end.
String formatSignedPrice(
  AppLocalizations l10n,
  num value, {
  bool showPlus = false,
}) {
  final sign = value < 0 ? _minusSign : (showPlus && value > 0 ? '+' : '');
  final amount = l10n.priceSyp(formatPrice(value.abs()));
  return '$_ltrIsolateStart$sign$amount$_ltrIsolateEnd';
}
