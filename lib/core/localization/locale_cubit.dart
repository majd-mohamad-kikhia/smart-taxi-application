import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../session/session_cubit.dart';
import 'app_locales.dart';
import 'app_strings.dart';
import 'language_repository.dart';
import 'locale_local_data_source.dart';

/// Holds the app's active [Locale] and persists changes locally.
///
/// The whole app (text, and RTL/LTR direction, which Flutter derives from
/// the locale) follows this cubit's state.
///
/// For a signed-in account the backend must also know the language (it
/// picks the notification language from it): [changeLanguage] saves it on
/// the server first and only switches the app if that succeeds, and the
/// current language is pushed to the server whenever an account signs in
/// or is restored.
class LocaleCubit extends Cubit<Locale> {
  final LocaleLocalDataSource _local;
  final LanguageRepository _repository;
  final SessionCubit _session;
  late final StreamSubscription<Object?> _sessionSubscription;

  bool _isChanging = false;

  /// `role:id` of the account whose language was last pushed to the server.
  String? _syncedAccount;

  LocaleCubit(this._local, this._repository, this._session)
      : super(AppLocales.defaultLocale) {
    _sessionSubscription = _session.stream.listen((_) => _syncOnSignIn());
  }

  /// Restores the saved language. Call once before `runApp` so the first
  /// frame is already in the right language.
  Future<void> load() async {
    final locale = AppLocales.fromCode(await _local.loadLanguageCode());
    AppStrings.update(locale);
    if (locale != state) emit(locale);
  }

  Future<void> setLocale(Locale locale) async {
    if (locale == state) return;
    // Update the context-free strings first so anything reacting to the
    // emitted state already sees the new language.
    AppStrings.update(locale);
    emit(locale);
    await _local.saveLanguageCode(locale.languageCode);
  }

  /// User-initiated language switch. Returns `null` on success, or the
  /// failure message — in which case the app language is left unchanged.
  Future<String?> changeLanguage(Locale locale) async {
    if (locale == state || _isChanging) return null;
    _isChanging = true;
    try {
      final role = _session.state?.role;
      if (role != null) {
        await _repository.saveLanguage(role, locale.languageCode);
      }
      await setLocale(locale);
      return null;
    } on LanguageException catch (e) {
      return e.message;
    } finally {
      _isChanging = false;
    }
  }

  /// Pushes the current language to the server once per signed-in account
  /// (sign in or restore), so an account that never touches the language
  /// setting still gets notifications in the language it actually uses.
  Future<void> _syncOnSignIn() async {
    final user = _session.state;
    final account = user == null ? null : '${user.role.name}:${user.id}';
    if (account == _syncedAccount) return;
    _syncedAccount = account;
    if (user == null) return;

    try {
      await _repository.saveLanguage(user.role, state.languageCode);
    } on LanguageException catch (e) {
      debugPrint('LocaleCubit: failed to sync language on sign in: $e');
      // Try again on the next session change rather than never.
      if (_syncedAccount == account) _syncedAccount = null;
    }
  }

  @override
  Future<void> close() {
    _sessionSubscription.cancel();
    return super.close();
  }
}
