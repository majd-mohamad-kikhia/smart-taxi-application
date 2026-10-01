import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/enums/user_role.dart';
import 'package:mshoar/core/localization/app_locales.dart';
import 'package:mshoar/core/localization/app_strings.dart';
import 'package:mshoar/core/localization/language_repository.dart';
import 'package:mshoar/core/localization/locale_cubit.dart';
import 'package:mshoar/core/localization/locale_local_data_source.dart';
import 'package:mshoar/core/session/app_user.dart';
import 'package:mshoar/core/session/session_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_language_repository.dart';

void main() {
  const dataSource = LocaleLocalDataSource();
  const driver = AppUser(
    id: 7,
    fullName: 'Test Driver',
    phone: '0990000000',
    role: UserRole.driver,
  );

  late FakeLanguageRepository repository;
  late SessionCubit session;

  LocaleCubit newCubit() => LocaleCubit(dataSource, repository, session);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = FakeLanguageRepository();
    session = SessionCubit();
  });

  tearDown(() => AppStrings.update(AppLocales.defaultLocale));

  test('defaults to Arabic when nothing was saved', () async {
    final cubit = newCubit();
    await cubit.load();

    expect(cubit.state, AppLocales.arabic);
    expect(AppStrings.current.retry, 'إعادة المحاولة');
    await cubit.close();
  });

  test('setLocale persists the choice and updates context-free strings', () async {
    final cubit = newCubit();
    await cubit.setLocale(AppLocales.english);

    expect(cubit.state, AppLocales.english);
    expect(AppStrings.current.retry, 'Retry');
    expect(await dataSource.loadLanguageCode(), 'en');
    await cubit.close();
  });

  test('a fresh cubit restores the saved language', () async {
    SharedPreferences.setMockInitialValues({'app_language_code': 'en'});

    final cubit = newCubit();
    await cubit.load();

    expect(cubit.state, AppLocales.english);
    expect(AppStrings.current.retry, 'Retry');
    await cubit.close();
  });

  test('an unsupported saved code falls back to Arabic', () async {
    SharedPreferences.setMockInitialValues({'app_language_code': 'fr'});

    final cubit = newCubit();
    await cubit.load();

    expect(cubit.state, AppLocales.arabic);
    await cubit.close();
  });

  group('changeLanguage', () {
    test('signed in: saves on the server, then switches the app', () async {
      session.setUser(driver);
      final cubit = newCubit();
      // Ignore the sign-in sync that already happened before the cubit existed.
      repository.saved.clear();

      final error = await cubit.changeLanguage(AppLocales.english);

      expect(error, isNull);
      expect(repository.saved, [(UserRole.driver, 'en')]);
      expect(cubit.state, AppLocales.english);
      expect(await dataSource.loadLanguageCode(), 'en');
      await cubit.close();
    });

    test('signed in: a failed request leaves the language unchanged', () async {
      session.setUser(driver);
      final cubit = newCubit();
      repository.failure = const LanguageException('Server unreachable');

      final error = await cubit.changeLanguage(AppLocales.english);

      expect(error, 'Server unreachable');
      expect(cubit.state, AppLocales.arabic);
      expect(await dataSource.loadLanguageCode(), isNull);
      expect(AppStrings.current.retry, 'إعادة المحاولة');
      await cubit.close();
    });

    test('signed out: switches locally without calling the server', () async {
      final cubit = newCubit();
      repository.failure = const LanguageException('should not be called');

      final error = await cubit.changeLanguage(AppLocales.english);

      expect(error, isNull);
      expect(cubit.state, AppLocales.english);
      await cubit.close();
    });

    test('pushes the current language once when an account signs in', () async {
      final cubit = newCubit();

      session.setUser(driver);
      await Future<void>.delayed(Duration.zero);
      session.setUser(driver); // e.g. a profile edit — no second push
      await Future<void>.delayed(Duration.zero);

      expect(repository.saved, [(UserRole.driver, 'ar')]);
      await cubit.close();
    });
  });
}
