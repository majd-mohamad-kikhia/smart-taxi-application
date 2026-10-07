import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/injection/injection.dart';
import 'package:mshoar/core/l10n/generated/app_localizations.dart';
import 'package:mshoar/core/session/session_cubit.dart';
import 'package:mshoar/driver_features/driver_auth/data/models/driver_status.dart';
import 'package:mshoar/driver_features/driver_auth/data/models/driver_user_model.dart';
import 'package:mshoar/driver_features/driver_auth/data/repositories/driver_repository.dart';
import 'package:mshoar/driver_features/driver_auth/presentation/cubit/driver_auth_cubit.dart';
import 'package:mshoar/driver_features/driver_auth/presentation/cubit/driver_auth_state.dart';
import 'package:mshoar/driver_features/driver_home/presentation/widgets/driver_low_wallet_notice_widget.dart';

DriverUserModel _driver({double wallet = 5000}) => DriverUserModel(
      id: 1,
      fullName: 'Ali Omar',
      phone: '0911111111',
      status: DriverStatus.active,
      walletBalance: wallet,
      isOnline: false,
      accessToken: 'a',
      refreshToken: 'r',
    );

class _FakeRepository extends Fake implements DriverRepository {
  DriverUserModel loginDriver = _driver();
  double? balance = 5000;
  bool failBalance = false;
  int balanceCalls = 0;

  @override
  Future<DriverUserModel> login({required String phone, required String password}) async =>
      loginDriver;

  @override
  Future<double> walletBalance() async {
    balanceCalls++;
    if (failBalance) throw const DriverAuthException('offline');
    return balance!;
  }
}

void main() {
  group('DriverAuthState.isWalletLow', () {
    test('at or below 200 is low, above it is not, unknown is not', () {
      expect(const DriverAuthState(walletBalance: 200).isWalletLow, isTrue);
      expect(const DriverAuthState(walletBalance: 199.99).isWalletLow, isTrue);
      expect(const DriverAuthState(walletBalance: 0).isWalletLow, isTrue);
      expect(const DriverAuthState(walletBalance: -50).isWalletLow, isTrue);
      expect(const DriverAuthState(walletBalance: 200.01).isWalletLow, isFalse);
      expect(const DriverAuthState().isWalletLow, isFalse);
    });
  });

  group('DriverAuthCubit wallet balance', () {
    late _FakeRepository repository;
    late DriverAuthCubit cubit;

    setUp(() {
      repository = _FakeRepository();
      cubit = DriverAuthCubit(repository, SessionCubit());
    });

    tearDown(() => cubit.close());

    test('signing in starts from the balance the login just returned', () async {
      repository.loginDriver = _driver(wallet: 150);

      await cubit.signIn(phone: '0911111111', password: 'x');

      expect(cubit.state.walletBalance, 150);
      expect(cubit.state.isWalletLow, isTrue);
    });

    test('a restored session does not trust its days-old saved balance', () {
      cubit.hydrate(_driver(wallet: 50));

      expect(cubit.state.walletBalance, isNull);
      expect(cubit.state.isWalletLow, isFalse);
    });

    test('refreshing asks the server and follows a top-up', () async {
      cubit.hydrate(_driver());
      repository.balance = 120;
      await cubit.refreshWalletBalance();
      expect(cubit.state.isWalletLow, isTrue);

      repository.balance = 5000;
      await cubit.refreshWalletBalance();
      expect(cubit.state.walletBalance, 5000);
      expect(cubit.state.isWalletLow, isFalse);
    });

    test('a failed refresh keeps what was known and does not throw', () async {
      cubit.hydrate(_driver());
      repository.balance = 120;
      await cubit.refreshWalletBalance();

      repository.failBalance = true;
      await cubit.refreshWalletBalance();

      expect(cubit.state.walletBalance, 120);
    });

    test('nobody signed in: nothing to ask', () async {
      await cubit.refreshWalletBalance();

      expect(repository.balanceCalls, 0);
    });
  });

  group('DriverLowWalletNoticeWidget', () {
    late _FakeRepository repository;
    late DriverAuthCubit cubit;

    setUp(() async {
      await sl.reset();
      repository = _FakeRepository();
      cubit = DriverAuthCubit(repository, SessionCubit())..hydrate(_driver());
      sl.registerSingleton<DriverAuthCubit>(cubit);
    });

    tearDown(() async {
      await cubit.close();
      await sl.reset();
    });

    Future<void> pump(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: DriverLowWalletNoticeWidget()),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a low wallet shows the notice with the balance', (tester) async {
      repository.balance = 150;
      await pump(tester);

      expect(find.textContaining('Your wallet balance is low'), findsOneWidget);
      expect(find.textContaining('150'), findsOneWidget);
    });

    testWidgets('exactly at the limit still shows it', (tester) async {
      repository.balance = 200;
      await pump(tester);

      expect(find.textContaining('Your wallet balance is low'), findsOneWidget);
    });

    testWidgets('a wallet above the limit shows nothing', (tester) async {
      repository.balance = 5000;
      await pump(tester);

      expect(find.byType(Text), findsNothing);
    });

    testWidgets('it asks the server when it appears, not only at sign in', (tester) async {
      await pump(tester);

      expect(repository.balanceCalls, 1);
    });

    testWidgets('coming back to the app notices a top-up made meanwhile', (tester) async {
      repository.balance = 150;
      await pump(tester);
      expect(find.textContaining('Your wallet balance is low'), findsOneWidget);

      repository.balance = 5000; // topped up outside the app
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(repository.balanceCalls, 2);
      expect(find.textContaining('Your wallet balance is low'), findsNothing);
    });

    testWidgets('and one spent meanwhile', (tester) async {
      repository.balance = 5000;
      await pump(tester);
      expect(find.byType(Text), findsNothing);

      repository.balance = 100;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(find.textContaining('Your wallet balance is low'), findsOneWidget);
    });
  });
}
