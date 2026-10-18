import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/enums/user_role.dart';
import 'package:mshoar/core/l10n/generated/app_localizations.dart';
import 'package:mshoar/core/session/remembered_login.dart';
import 'package:mshoar/core/session/remembered_login_store.dart';
import 'package:mshoar/core/session/session_cubit.dart';
import 'package:mshoar/core/theme/app_palette.dart';
import 'package:mshoar/core/widgets/remember_me_checkbox_widget.dart';
import 'package:mshoar/driver_features/driver_auth/data/models/driver_status.dart';
import 'package:mshoar/driver_features/driver_auth/data/models/driver_user_model.dart';
import 'package:mshoar/driver_features/driver_auth/data/repositories/driver_repository.dart';
import 'package:mshoar/driver_features/driver_auth/presentation/cubit/driver_auth_cubit.dart';
import 'package:mshoar/features/auth/data/models/auth_user_model.dart';
import 'package:mshoar/features/auth/data/repositories/auth_repository.dart';
import 'package:mshoar/features/auth/presentation/cubit/auth_cubit.dart';

import '../helpers/fake_remembered_login_store.dart';

const _customer = AuthUserModel(
  id: 1,
  fullName: 'Sara Ali',
  phone: '0911111111',
  role: UserRole.customer,
  accessToken: 'a',
  refreshToken: 'r',
);

class _FakeAuthRepository extends Fake implements AuthRepository {
  bool fail = false;

  @override
  Future<AuthUserModel> login({
    required String phone,
    required String password,
    required UserRole role,
  }) async {
    if (fail) throw const AuthException('wrong password');
    return _customer;
  }
}

class _FakeDriverRepository extends Fake implements DriverRepository {
  bool fail = false;

  @override
  Future<DriverUserModel> login({
    required String phone,
    required String password,
  }) async {
    if (fail) throw const DriverAuthException('wrong password');
    return const DriverUserModel(
      id: 2,
      fullName: 'Ali Omar',
      phone: '0922222222',
      status: DriverStatus.active,
      walletBalance: 1000,
      isOnline: false,
      accessToken: 'a',
      refreshToken: 'r',
    );
  }
}

void main() {
  group('RememberedLoginStore', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    test('keeps a customer and a driver apart', () async {
      const store = RememberedLoginStore();
      await store.save(UserRole.customer, phone: '0911', password: 'c-pass');
      await store.save(UserRole.driver, phone: '0922', password: 'd-pass');

      expect(
        await store.load(UserRole.customer),
        const RememberedLogin(phone: '0911', password: 'c-pass'),
      );
      expect(
        await store.load(UserRole.driver),
        const RememberedLogin(phone: '0922', password: 'd-pass'),
      );
    });

    test('nothing saved reads as null, and clear forgets', () async {
      const store = RememberedLoginStore();
      expect(await store.load(UserRole.customer), isNull);

      await store.save(UserRole.customer, phone: '0911', password: 'x');
      await store.clear(UserRole.customer);
      expect(await store.load(UserRole.customer), isNull);
    });
  });

  group('customer sign in', () {
    late _FakeAuthRepository repository;
    late FakeRememberedLoginStore store;
    late AuthCubit cubit;

    setUp(() {
      repository = _FakeAuthRepository();
      store = FakeRememberedLoginStore();
      cubit = AuthCubit(repository, SessionCubit(), store)
        ..selectRole(UserRole.customer);
    });

    tearDown(() => cubit.close());

    test('with "remember me" the phone and password are kept', () async {
      await cubit.signIn(phone: '0911', password: 'secret', rememberMe: true);

      expect(
        await cubit.rememberedLogin(),
        const RememberedLogin(phone: '0911', password: 'secret'),
      );
    });

    test('without it, an earlier saved login is forgotten', () async {
      await cubit.signIn(phone: '0911', password: 'secret', rememberMe: true);
      await cubit.signIn(phone: '0911', password: 'secret');

      expect(await cubit.rememberedLogin(), isNull);
    });

    test('wrong details are never kept', () async {
      repository.fail = true;

      await cubit.signIn(phone: '0911', password: 'bad', rememberMe: true);

      expect(await cubit.rememberedLogin(), isNull);
      expect(cubit.state.errorMessage, 'wrong password');
    });

    test('a failed sign in leaves an earlier saved login alone', () async {
      await cubit.signIn(phone: '0911', password: 'secret', rememberMe: true);
      repository.fail = true;

      await cubit.signIn(phone: '0911', password: 'typo', rememberMe: true);

      expect(
        await cubit.rememberedLogin(),
        const RememberedLogin(phone: '0911', password: 'secret'),
      );
    });
  });

  group('driver sign in', () {
    late _FakeDriverRepository repository;
    late FakeRememberedLoginStore store;
    late DriverAuthCubit cubit;

    setUp(() {
      repository = _FakeDriverRepository();
      store = FakeRememberedLoginStore();
      cubit = DriverAuthCubit(repository, SessionCubit(), store);
    });

    tearDown(() => cubit.close());

    test('with "remember me" the phone and password are kept', () async {
      await cubit.signIn(phone: '0922', password: 'secret', rememberMe: true);

      expect(
        await cubit.rememberedLogin(),
        const RememberedLogin(phone: '0922', password: 'secret'),
      );
      // The customer's slot is separate.
      expect(await store.load(UserRole.customer), isNull);
    });

    test('without it nothing is kept', () async {
      await cubit.signIn(phone: '0922', password: 'secret');
      expect(await cubit.rememberedLogin(), isNull);
    });

    test('wrong details are never kept', () async {
      repository.fail = true;
      await cubit.signIn(phone: '0922', password: 'bad', rememberMe: true);
      expect(await cubit.rememberedLogin(), isNull);
    });
  });

  group('RememberMeCheckboxWidget', () {
    Widget app(Locale locale, Widget child) => MaterialApp(
      locale: locale,
      theme: ThemeData(extensions: [AppPalette.light]),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

    testWidgets('tapping the row toggles it, in both languages', (
      tester,
    ) async {
      for (final locale in const [Locale('en'), Locale('ar')]) {
        var value = true;
        await tester.pumpWidget(
          app(
            locale,
            StatefulBuilder(
              builder: (context, setState) => RememberMeCheckboxWidget(
                value: value,
                onChanged: (v) => setState(() => value = v),
              ),
            ),
          ),
        );
        await tester.tap(find.byType(InkWell).first);
        await tester.pump();
        expect(value, isFalse, reason: locale.languageCode);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('does nothing while sign in is submitting', (tester) async {
      await tester.pumpWidget(
        app(
          const Locale('en'),
          const RememberMeCheckboxWidget(value: true, onChanged: null),
        ),
      );
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).onChanged, isNull);
    });
  });
}
