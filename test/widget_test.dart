import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/injection/injection.dart';
import 'package:mshoar/core/localization/app_locales.dart';
import 'package:mshoar/core/localization/locale_cubit.dart';
import 'package:mshoar/core/localization/locale_local_data_source.dart';
import 'package:mshoar/core/routing/app_router.dart';
import 'package:mshoar/core/session/session_cubit.dart';
import 'package:mshoar/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_language_repository.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    sl.registerLazySingleton<LocaleCubit>(
      () => LocaleCubit(
        const LocaleLocalDataSource(),
        FakeLanguageRepository(),
        SessionCubit(),
      ),
    );
  });

  tearDown(() => sl.reset());

  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MshoarApp(initialRoute: AppRouter.roleSelection),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('switching language flips text and layout direction', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MshoarApp(initialRoute: AppRouter.roleSelection),
    );
    await tester.pumpAndSettle();

    Directionality directionality() =>
        tester.widget<Directionality>(find.byType(Directionality).first);

    // Arabic by default → right-to-left.
    expect(find.text('أهلاً بك في Smart Taxi'), findsOneWidget);
    expect(directionality().textDirection, TextDirection.rtl);

    await sl<LocaleCubit>().setLocale(AppLocales.english);
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Smart Taxi'), findsOneWidget);
    expect(directionality().textDirection, TextDirection.ltr);

    // …and back again.
    await sl<LocaleCubit>().setLocale(AppLocales.arabic);
    await tester.pumpAndSettle();

    expect(find.text('أهلاً بك في Smart Taxi'), findsOneWidget);
    expect(directionality().textDirection, TextDirection.rtl);
  });
}
