import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/app_version/data/models/app_version_model.dart';
import 'package:mshoar/core/app_version/data/repositories/app_version_repository.dart';
import 'package:mshoar/core/app_version/presentation/cubit/app_version_cubit.dart';
import 'package:mshoar/core/app_version/presentation/cubit/app_version_state.dart';
import 'package:mshoar/core/enums/user_role.dart';
import 'package:mshoar/core/localization/locale_cubit.dart';
import 'package:mshoar/core/network/api_exception.dart';
import 'package:mshoar/core/session/app_user.dart';
import 'package:mshoar/core/session/session_cubit.dart';

class _FakeLocaleCubit extends Cubit<Locale> implements LocaleCubit {
  _FakeLocaleCubit() : super(const Locale('en'));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRepository implements AppVersionRepository {
  final List<Object> answers = [];
  final List<AppVersionApp> askedApps = [];
  final Map<AppVersionApp, String> skipped = {};

  @override
  Future<AppVersionModel> check({
    required AppVersionApp app,
    required String lang,
  }) async {
    askedApps.add(app);
    final next = answers.removeAt(0);
    if (next is AppVersionModel) return next;
    throw next;
  }

  @override
  Future<bool> isSkipped(AppVersionApp app, String latestVersion) async =>
      skipped[app] == latestVersion;

  @override
  Future<void> skip(AppVersionApp app, String latestVersion) async =>
      skipped[app] = latestVersion;
}

AppVersionModel _info(AppVersionStatus status, {String latest = '1.3.0'}) =>
    AppVersionModel(
      status: status,
      canContinue:
          status == AppVersionStatus.ok ||
          status == AppVersionStatus.optionalUpdate,
      currentVersion: '1.0.0+1',
      latestVersion: latest,
      minVersion: '1.0.0',
    );

void main() {
  late _FakeRepository repository;
  late SessionCubit session;
  late AppVersionCubit cubit;

  setUp(() {
    repository = _FakeRepository();
    session = SessionCubit();
    cubit = AppVersionCubit(repository, _FakeLocaleCubit(), session);
  });

  tearDown(() async {
    await cubit.close();
    await session.close();
  });

  group('AppVersionModel.fromJson', () {
    test('maps every status and treats an unknown one as ok', () {
      AppVersionStatus parse(String raw) =>
          AppVersionModel.fromJson({'status': raw}).status;

      expect(parse('maintenance'), AppVersionStatus.maintenance);
      expect(parse('force_update'), AppVersionStatus.forceUpdate);
      expect(parse('optional_update'), AppVersionStatus.optionalUpdate);
      expect(parse('ok'), AppVersionStatus.ok);
      expect(parse('something_new'), AppVersionStatus.ok);
    });

    test('reads the maintenance end time and tolerates missing fields', () {
      final model = AppVersionModel.fromJson({
        'status': 'maintenance',
        'maintenance': {'ends_at': '2026-10-01 18:00:00'},
      });
      expect(model.maintenanceEndsAt, '2026-10-01 18:00:00');
      expect(model.canContinue, isTrue);
      expect(model.title, isNull);
    });
  });

  group('AppVersionCubit.check', () {
    test('emits the blocking state the server asked for', () async {
      repository.answers.add(_info(AppVersionStatus.maintenance));
      await cubit.check();
      expect(cubit.state, isA<AppVersionMaintenance>());

      repository.answers.add(_info(AppVersionStatus.forceUpdate));
      await cubit.check();
      expect(cubit.state, isA<AppVersionForceUpdate>());

      repository.answers.add(_info(AppVersionStatus.ok));
      await cubit.check();
      expect(cubit.state, const AppVersionAllowed());
    });

    test('fails open when the very first check errors', () async {
      repository.answers.add(const ApiException('offline'));
      await runZonedGuarded(() => cubit.check(), (_, _) {});
      expect(cubit.state, const AppVersionAllowed());
    });

    test('keeps a blocking screen when a retry errors', () async {
      repository.answers.add(_info(AppVersionStatus.maintenance));
      await cubit.check();

      repository.answers.add(const ApiException('offline'));
      await runZonedGuarded(() => cubit.check(), (_, _) {});
      expect(cubit.state, isA<AppVersionMaintenance>());
    });

    test('does not re-ask within five minutes when not forced', () async {
      repository.answers
        ..add(_info(AppVersionStatus.ok))
        ..add(_info(AppVersionStatus.forceUpdate));
      await cubit.check();
      await cubit.check(force: false);

      expect(repository.askedApps, hasLength(1));
      expect(cubit.state, const AppVersionAllowed());
    });

    test(
      '"Later" hides the optional dialog until a newer latest_version',
      () async {
        final optional = _info(AppVersionStatus.optionalUpdate);
        repository.answers.add(optional);
        await cubit.check();
        expect(cubit.state, AppVersionAllowed(optional: optional));

        await cubit.skipOptional(optional);
        expect(cubit.state, const AppVersionAllowed());

        repository.answers.add(optional);
        await cubit.check();
        expect(cubit.state, const AppVersionAllowed());

        final newer = _info(AppVersionStatus.optionalUpdate, latest: '1.4.0');
        repository.answers.add(newer);
        await cubit.check();
        expect(cubit.state, AppVersionAllowed(optional: newer));
      },
    );

    test(
      'skipOptional never overwrites a force update that arrived meanwhile',
      () async {
        final optional = _info(AppVersionStatus.optionalUpdate);
        repository.answers.add(optional);
        await cubit.check();

        repository.answers.add(_info(AppVersionStatus.forceUpdate));
        await cubit.check();
        await cubit.skipOptional(optional);

        expect(cubit.state, isA<AppVersionForceUpdate>());
      },
    );

    test('asks for the driver app once the driver role is chosen', () async {
      repository.answers
        ..add(_info(AppVersionStatus.ok))
        ..add(_info(AppVersionStatus.forceUpdate));
      await cubit.check();

      cubit.onRoleChosen(UserRole.driver);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(repository.askedApps, [
        AppVersionApp.customer,
        AppVersionApp.driver,
      ]);
      expect(cubit.state, isA<AppVersionForceUpdate>());
    });

    test('choosing the rider role does not ask again', () async {
      repository.answers.add(_info(AppVersionStatus.ok));
      await cubit.check();

      cubit.onRoleChosen(UserRole.rider);
      await Future<void>.delayed(Duration.zero);

      expect(repository.askedApps, hasLength(1));
    });

    test('asks for the driver app once a driver signs in', () async {
      repository.answers
        ..add(_info(AppVersionStatus.ok))
        ..add(_info(AppVersionStatus.maintenance));
      await cubit.check();
      expect(repository.askedApps, [AppVersionApp.customer]);

      session.setUser(
        const AppUser(
          id: 1,
          fullName: 'Driver',
          phone: '0',
          role: UserRole.driver,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(repository.askedApps, [
        AppVersionApp.customer,
        AppVersionApp.driver,
      ]);
      expect(cubit.state, isA<AppVersionMaintenance>());
    });
  });
}
