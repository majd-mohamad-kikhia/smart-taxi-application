import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/enums/user_role.dart';
import 'package:mshoar/core/injection/injection.dart';
import 'package:mshoar/core/l10n/generated/app_localizations.dart';
import 'package:mshoar/core/localization/locale_cubit.dart';
import 'package:mshoar/core/localization/locale_local_data_source.dart';
import 'package:mshoar/core/session/remembered_login.dart';
import 'package:mshoar/core/session/session_cubit.dart';
import 'package:mshoar/core/theme/app_palette.dart';
import 'package:mshoar/driver_features/driver_auth/data/repositories/driver_repository.dart';
import 'package:mshoar/driver_features/driver_auth/presentation/cubit/driver_auth_cubit.dart';
import 'package:mshoar/driver_features/driver_auth/presentation/screens/driver_sign_in_screen.dart';

import '../../helpers/fake_language_repository.dart';
import '../../helpers/fake_remembered_login_store.dart';

class _FakeDriverRepository extends Fake implements DriverRepository {}

void main() {
  late FakeRememberedLoginStore store;

  setUp(() async {
    await sl.reset();
    store = FakeRememberedLoginStore();
    sl.registerSingleton<DriverAuthCubit>(
      DriverAuthCubit(_FakeDriverRepository(), SessionCubit(), store),
    );
  });

  tearDown(() => sl.reset());

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        theme: ThemeData(extensions: [AppPalette.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<LocaleCubit>(
          create: (_) => LocaleCubit(
            const LocaleLocalDataSource(),
            FakeLanguageRepository(),
            SessionCubit(),
          ),
          child: const DriverSignInScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a remembered login fills the form and "remember me" is on', (
    tester,
  ) async {
    store.saved[UserRole.driver] = const RememberedLogin(
      phone: '0922222222',
      password: 'secret123',
    );

    await open(tester);

    final fields = tester.widgetList<EditableText>(find.byType(EditableText));
    expect(fields.map((f) => f.controller.text), ['0922222222', 'secret123']);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
  });

  testWidgets('with nothing remembered the form is empty', (tester) async {
    await open(tester);

    final fields = tester.widgetList<EditableText>(find.byType(EditableText));
    expect(fields.every((f) => f.controller.text.isEmpty), isTrue);
    expect(find.text('Remember me'), findsOneWidget);
  });
}
