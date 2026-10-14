import 'dart:ui';

/// The languages the app ships translations for.
///
/// Add a new [Locale] here (plus its `app_<code>.arb` in `core/l10n/`)
/// to make it selectable everywhere — the language dropdown and
/// [MaterialApp.supportedLocales] both read from this list.
class AppLocales {
  AppLocales._();

  static const Locale arabic = Locale('ar');
  static const Locale english = Locale('en');

  /// What the app speaks until the user picks a language: Arabic when the
  /// phone itself is set to Arabic, English for every other phone language.
  static Locale get defaultLocale =>
      PlatformDispatcher.instance.locale.languageCode == arabic.languageCode
      ? arabic
      : english;

  static const List<Locale> supported = [arabic, english];

  /// A language's own name, shown untranslated in the language picker so
  /// it stays recognizable whichever language is currently active.
  static String nativeName(Locale locale) => switch (locale.languageCode) {
    'ar' => 'العربية',
    'en' => 'English',
    _ => locale.languageCode,
  };

  /// Resolves a persisted language code, falling back to [defaultLocale]
  /// for `null` or a language that is no longer supported.
  static Locale fromCode(String? code) {
    for (final locale in supported) {
      if (locale.languageCode == code) return locale;
    }
    return defaultLocale;
  }
}
