import 'package:flutter/widgets.dart';
import '../l10n/generated/app_localizations.dart';
import 'app_locales.dart';

/// Context-free access to the current [AppLocalizations].
///
/// Widgets must keep using `context.l10n` so they rebuild when the
/// language changes. This holder exists only for code that has no
/// `BuildContext` — repositories, cubits, network error mapping,
/// background notifications — and produces a message at the moment
/// something happens. [LocaleCubit] is its only writer.
class AppStrings {
  AppStrings._();

  static AppLocalizations _current = lookupAppLocalizations(
    AppLocales.defaultLocale,
  );

  static AppLocalizations get current => _current;

  static void update(Locale locale) {
    _current = lookupAppLocalizations(locale);
  }
}
