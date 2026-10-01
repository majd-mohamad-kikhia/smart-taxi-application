import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/enums/user_role.dart';
import 'package:mshoar/core/l10n/generated/app_localizations.dart';
import 'package:mshoar/core/localization/app_strings.dart';
import 'package:mshoar/core/network/api_endpoints.dart';
import 'package:mshoar/core/network/api_exception.dart';
import 'package:mshoar/core/session/app_user.dart';
import 'package:mshoar/core/session/session_cubit.dart';
import 'package:mshoar/features/settings/data/datasources/profile_remote_data_source.dart';
import 'package:mshoar/features/settings/data/repositories/profile_repository.dart';
import 'package:mshoar/features/settings/presentation/cubit/delete_account_cubit.dart';
import 'package:mshoar/features/settings/presentation/cubit/delete_account_state.dart';
import 'package:mshoar/features/settings/presentation/widgets/delete_account_dialog_widget.dart';

class _FakeRemote extends ProfileRemoteDataSource {
  _FakeRemote() : super(Dio(), const ApiEndpoints());

  final passwords = <String>[];
  ApiException? failure;
  Completer<void>? hold;

  @override
  Future<void> deleteAccount(String password) async {
    passwords.add(password);
    await hold?.future;
    final error = failure;
    if (error != null) {
      throw DioException(requestOptions: RequestOptions(), error: error);
    }
  }
}

/// The shared dialog has an icon that pulses forever, so `pumpAndSettle`
/// would never finish: run the frames by hand, long enough for its 380 ms
/// open / close transition.
Future<void> _pumpDialog(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  late _FakeRemote remote;
  late SessionCubit session;
  var logouts = 0;
  late DeleteAccountCubit cubit;

  setUp(() {
    remote = _FakeRemote();
    logouts = 0;
    session = SessionCubit()
      ..registerLogoutHandler(UserRole.customer, () async => logouts++)
      ..setUser(
        const AppUser(
          id: 1,
          fullName: 'Test User',
          phone: '0999',
          role: UserRole.customer,
        ),
      );
    cubit = DeleteAccountCubit(ProfileRepository(remote), session);
  });

  tearDown(() async {
    await cubit.close();
    await session.close();
  });

  group('DeleteAccountCubit', () {
    test('sends the password, then signs this device out', () async {
      await cubit.submit('MyPassw0rd');
      expect(remote.passwords, ['MyPassw0rd']);
      expect(logouts, 1);
      expect(cubit.state.status, DeleteAccountStatus.success);
    });

    test(
      'a wrong password (401) shows the incorrect-password message and keeps the session',
      () async {
        remote.failure = const ApiException('raw', statusCode: 401);
        await cubit.submit('nope');
        expect(cubit.state.status, DeleteAccountStatus.failure);
        expect(
          cubit.state.errorMessage,
          AppStrings.current.errIncorrectPassword,
        );
        expect(logouts, 0);
      },
    );

    test(
      'an active ride (409) shows the finish-your-ride message and keeps the session',
      () async {
        remote.failure = const ApiException('raw', statusCode: 409);
        await cubit.submit('MyPassw0rd');
        expect(
          cubit.state.errorMessage,
          AppStrings.current.errDeleteActiveRide,
        );
        expect(logouts, 0);
      },
    );

    test('any other failure shows the server-side message', () async {
      remote.failure = const ApiException('No internet connection');
      await cubit.submit('MyPassw0rd');
      expect(cubit.state.errorMessage, 'No internet connection');
      expect(logouts, 0);
    });

    test('a second tap while the request is running is ignored', () async {
      remote.hold = Completer<void>();
      final first = cubit.submit('MyPassw0rd');
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.isSubmitting, isTrue);

      await cubit.submit('MyPassw0rd');
      remote.hold!.complete();
      await first;
      expect(remote.passwords, hasLength(1));
    });

    test('can try again after a failure', () async {
      remote.failure = const ApiException('raw', statusCode: 401);
      await cubit.submit('wrong');
      remote.failure = null;
      await cubit.submit('right');
      expect(cubit.state.status, DeleteAccountStatus.success);
      expect(remote.passwords, ['wrong', 'right']);
    });
  });

  group('delete account dialog', () {
    var deleted = 0;

    Future<void> openDialog(WidgetTester tester) async {
      deleted = 0;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showDeleteAccountDialog(
                    context,
                    createCubit: () => cubit,
                    onDeleted: () => deleted++,
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await _pumpDialog(tester);
    }

    testWidgets('an empty password is not sent', (tester) async {
      await openDialog(tester);
      expect(find.text('Delete your account?'), findsOneWidget);

      await tester.tap(find.text('Delete permanently'));
      await tester.pump();
      expect(remote.passwords, isEmpty);
      expect(find.text(AppStrings.current.valPasswordRequired), findsOneWidget);
    });

    testWidgets(
      'a correct password deletes the account and closes the dialog',
      (tester) async {
        await openDialog(tester);
        await tester.enterText(find.byType(TextFormField), 'MyPassw0rd');
        await tester.tap(find.text('Delete permanently'));
        await _pumpDialog(tester);

        expect(remote.passwords, ['MyPassw0rd']);
        expect(deleted, 1);
        expect(find.text('Delete your account?'), findsNothing);
      },
    );

    testWidgets('a wrong password shows the error and keeps the dialog open', (
      tester,
    ) async {
      remote.failure = const ApiException('raw', statusCode: 401);
      await openDialog(tester);
      await tester.enterText(find.byType(TextFormField), 'nope');
      await tester.tap(find.text('Delete permanently'));
      await _pumpDialog(tester);

      expect(
        find.text(AppStrings.current.errIncorrectPassword),
        findsOneWidget,
      );
      expect(deleted, 0);
      expect(find.text('Delete your account?'), findsOneWidget);
    });

    testWidgets('Cancel closes the dialog without deleting', (tester) async {
      await openDialog(tester);
      await tester.tap(find.text('Cancel'));
      await _pumpDialog(tester);
      expect(find.text('Delete your account?'), findsNothing);
      expect(remote.passwords, isEmpty);
    });
  });
}
