import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/injection/injection.dart';
import 'package:mshoar/core/l10n/generated/app_localizations.dart';
import 'package:mshoar/driver_features/driver_gps_guard/data/datasources/gps_status_service.dart';
import 'package:mshoar/driver_features/driver_gps_guard/presentation/cubit/gps_status_cubit.dart';
import 'package:mshoar/driver_features/driver_gps_guard/presentation/widgets/driver_gps_guard_widget.dart';

class _FakeGpsService extends GpsStatusService {
  bool enabled = true;
  bool failChecks = false;
  int listens = 0;
  int settingsOpened = 0;
  final events = StreamController<bool>.broadcast();

  @override
  Future<bool> isEnabled() async {
    if (failChecks) throw StateError('no answer');
    return enabled;
  }

  @override
  Stream<bool> statusStream() {
    listens++;
    return events.stream;
  }

  @override
  Future<bool> openSettings() async {
    settingsOpened++;
    return true;
  }
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late _FakeGpsService service;

  setUp(() => service = _FakeGpsService());
  tearDown(() => service.events.close());

  group('GpsStatusCubit', () {
    test('does not block before the first answer', () async {
      final cubit = GpsStatusCubit(service);
      expect(cubit.state.isEnabled, isNull);
      expect(cubit.state.isDisabled, isFalse);
      await cubit.close();
    });

    test('start reads the current status', () async {
      service.enabled = false;
      final cubit = GpsStatusCubit(service);
      await cubit.start();
      expect(cubit.state.isDisabled, isTrue);
      await cubit.close();
    });

    test('follows the system turning GPS off and on', () async {
      final cubit = GpsStatusCubit(service);
      await cubit.start();
      expect(cubit.state.isEnabled, isTrue);

      service.events.add(false);
      await _settle();
      expect(cubit.state.isDisabled, isTrue);

      service.events.add(true);
      await _settle();
      expect(cubit.state.isDisabled, isFalse);
      expect(cubit.state.isEnabled, isTrue);
      await cubit.close();
    });

    test('start only subscribes once', () async {
      final cubit = GpsStatusCubit(service);
      await cubit.start();
      await cubit.start();
      expect(service.listens, 1);
      await cubit.close();
    });

    test('recheck catches a change that fired no event', () async {
      final cubit = GpsStatusCubit(service);
      await cubit.start();
      service.enabled = false;
      await cubit.recheck();
      expect(cubit.state.isDisabled, isTrue);
      await cubit.close();
    });

    test('a failed check never blocks the driver', () async {
      service.failChecks = true;
      final cubit = GpsStatusCubit(service);
      await cubit.start();
      expect(cubit.state.isDisabled, isFalse);
      await cubit.close();
    });
  });

  group('DriverGpsGuardWidget', () {
    late GpsStatusCubit cubit;
    var taps = 0;

    setUp(() async {
      taps = 0;
      await sl.reset();
      cubit = GpsStatusCubit(service);
      sl.registerSingleton<GpsStatusCubit>(cubit);
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
          home: DriverGpsGuardWidget(
            child: Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => taps++,
                  child: const Text('do something'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('GPS on: no dialog and the screen works', (tester) async {
      await pump(tester);
      expect(find.text('Turn on location (GPS)'), findsNothing);
      await tester.tap(find.text('do something'));
      expect(taps, 1);
    });

    testWidgets('GPS off: the dialog shows and the screen is blocked', (
      tester,
    ) async {
      service.enabled = false;
      await pump(tester);

      expect(find.text('Turn on location (GPS)'), findsOneWidget);
      await tester.tap(find.text('do something'), warnIfMissed: false);
      expect(taps, 0);
    });

    testWidgets(
      'the dialog goes away when GPS is turned on and returns when it is turned off again',
      (tester) async {
        service.enabled = false;
        await pump(tester);
        expect(find.text('Turn on location (GPS)'), findsOneWidget);

        service.events.add(true);
        await tester.pumpAndSettle();
        expect(find.text('Turn on location (GPS)'), findsNothing);
        await tester.tap(find.text('do something'));
        expect(taps, 1);

        service.events.add(false);
        await tester.pumpAndSettle();
        expect(find.text('Turn on location (GPS)'), findsOneWidget);
      },
    );

    testWidgets('the button opens the location settings', (tester) async {
      service.enabled = false;
      await pump(tester);
      await tester.tap(find.text('Open location settings'));
      expect(service.settingsOpened, 1);
    });

    testWidgets('coming back to the app re-checks the switch', (tester) async {
      await pump(tester);
      service.enabled = false; // switched off without an event
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('Turn on location (GPS)'), findsOneWidget);
    });
  });
}
