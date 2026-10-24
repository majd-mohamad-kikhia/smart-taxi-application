import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/screen_takeover/data/screen_takeover_platform.dart';
import 'package:mshoar/core/screen_takeover/data/screen_takeover_store.dart';
import 'package:mshoar/core/screen_takeover/presentation/cubit/screen_takeover_cubit.dart';

class _FakePlatform extends Fake implements ScreenTakeoverPlatform {
  /// What is still not allowed; a request allows all of it, unless
  /// [refuse] is set.
  List<TakeoverPermission> missingNow = [];
  bool refuse = false;
  int requests = 0;

  @override
  bool get isSupported => true;

  @override
  Future<List<TakeoverPermission>> missing() async => missingNow;

  @override
  Future<bool> requestMissing() async {
    requests++;
    if (!refuse) missingNow = [];
    return missingNow.isEmpty;
  }
}

class _FakeStore extends Fake implements ScreenTakeoverStore {
  bool enabled = true;
  String? version;

  @override
  Future<bool> isEnabled() async => enabled;

  @override
  Future<void> setEnabled(bool value) async => enabled = value;

  @override
  Future<String?> checkedVersion() async => version;

  @override
  Future<void> setCheckedVersion(String value) async => version = value;
}

void main() {
  late _FakePlatform platform;
  late _FakeStore store;
  var appVersion = '1.0.0+1';
  late ScreenTakeoverCubit cubit;

  setUp(() {
    platform = _FakePlatform();
    store = _FakeStore();
    appVersion = '1.0.0+1';
    cubit = ScreenTakeoverCubit(platform, store, () async => appVersion);
  });

  tearDown(() => cubit.close());

  group('load', () {
    test('is on when saved on and every permission is allowed', () async {
      await cubit.load();
      expect(cubit.state.enabled, isTrue);
    });

    test('shows off, without forgetting the choice, when a permission was '
        'taken back', () async {
      platform.missingNow = [TakeoverPermission.overlay];
      await cubit.load();

      expect(cubit.state.enabled, isFalse);
      expect(store.enabled, isTrue);
    });
  });

  group('setEnabled', () {
    test('turning on asks for what is missing and stays on when allowed', () async {
      store.enabled = false;
      platform.missingNow = [TakeoverPermission.notifications];

      await cubit.setEnabled(true);

      expect(platform.requests, 1);
      expect(cubit.state.enabled, isTrue);
      expect(store.enabled, isTrue);
      expect(cubit.state.permissionDeniedCount, 0);
    });

    test('a refused permission leaves it off and says so once', () async {
      store.enabled = false;
      platform.missingNow = [TakeoverPermission.fullScreenIntent];
      platform.refuse = true;

      await cubit.setEnabled(true);

      expect(cubit.state.enabled, isFalse);
      expect(store.enabled, isFalse);
      expect(cubit.state.permissionDeniedCount, 1);
    });

    test('turning off is saved and asks for nothing', () async {
      await cubit.load();
      await cubit.setEnabled(false);

      expect(cubit.state.enabled, isFalse);
      expect(store.enabled, isFalse);
      expect(platform.requests, 0);
    });
  });

  group('checkAfterUpdate', () {
    test('asks for the missing permissions on the first launch of a version',
        () async {
      platform.missingNow = [
        TakeoverPermission.notifications,
        TakeoverPermission.overlay,
      ];

      await cubit.checkAfterUpdate();

      expect(platform.requests, 1);
      expect(cubit.state.enabled, isTrue);
      expect(store.version, '1.0.0+1');
    });

    test('does not ask again for the same version', () async {
      platform.missingNow = [TakeoverPermission.overlay];
      await cubit.checkAfterUpdate();
      platform.missingNow = [TakeoverPermission.overlay];
      await cubit.checkAfterUpdate();

      expect(platform.requests, 1);
    });

    test('asks again after an update', () async {
      platform.missingNow = [TakeoverPermission.overlay];
      await cubit.checkAfterUpdate();
      appVersion = '1.1.0+2';
      platform.missingNow = [TakeoverPermission.overlay];
      await cubit.checkAfterUpdate();

      expect(platform.requests, 2);
    });

    test('asks nothing when everything is already allowed', () async {
      await cubit.checkAfterUpdate();

      expect(platform.requests, 0);
      expect(cubit.state.enabled, isTrue);
    });

    test('asks nothing when the driver turned the switch off', () async {
      store.enabled = false;
      platform.missingNow = [TakeoverPermission.overlay];

      await cubit.checkAfterUpdate();

      expect(platform.requests, 0);
    });

    test('a refusal turns the switch off quietly', () async {
      platform.missingNow = [TakeoverPermission.overlay];
      platform.refuse = true;

      await cubit.checkAfterUpdate();

      expect(cubit.state.enabled, isFalse);
      expect(store.enabled, isFalse);
      expect(cubit.state.permissionDeniedCount, 0);
    });
  });
}
