import 'package:intl/intl.dart';
import '../l10n/generated/app_localizations.dart';

/// Prices from the API are in new Syrian pounds; one new pound is this many
/// old ones.
const int oldPoundsPerNewPound = 100;

/// A price as whole units with a thousands separator ("25,000"), so a long
/// fare is readable at a glance. Latin digits in both languages, to match
/// the rest of the app's numbers. Use [formatSyp] to show it with its
/// currency.
String formatPrice(num value) =>
    NumberFormat.decimalPattern('en').format(value.round());

/// An API price (new pounds) with the same price in old pounds after it:
/// "300 new SYP (30,000 old)".
String formatSyp(AppLocalizations l10n, num value) => l10n.priceSypNewOld(
      formatPrice(value),
      formatPrice(value * oldPoundsPerNewPound),
    );

/// An API price in new pounds only, with its currency: "300 new SYP".
String formatNewSyp(AppLocalizations l10n, num value) =>
    l10n.priceSypNew(_signedNumber(value));

/// An API price (new pounds) in old pounds only, with its currency and a
/// minus when negative: "30,000 old SYP".
String formatOldSyp(AppLocalizations l10n, num value) =>
    l10n.priceSypOld(_signedNumber(value * oldPoundsPerNewPound));

/// A price with its currency and a sign: "−5,000 new SYP (−500,000 old)",
/// or with "+" when [showPlus].
String formatSignedPrice(
  AppLocalizations l10n,
  num value, {
  bool showPlus = false,
}) => l10n.priceSypNewOld(
      _signedNumber(value, showPlus: showPlus),
      _signedNumber(value * oldPoundsPerNewPound, showPlus: showPlus),
    );

final String _minusSign = String.fromCharCode(0x2212);
final String _ltrIsolateStart = String.fromCharCode(0x2066);
final String _ltrIsolateEnd = String.fromCharCode(0x2069);

/// The sign is a real minus, and the signed number is isolated
/// left-to-right so the sign stays attached to it inside Arabic text
/// instead of drifting to the other end.
String _signedNumber(num value, {bool showPlus = false}) {
  final sign = value < 0 ? _minusSign : (showPlus && value > 0 ? '+' : '');
  if (sign.isEmpty) return formatPrice(value);
  return '$_ltrIsolateStart$sign${formatPrice(value.abs())}$_ltrIsolateEnd';
}
