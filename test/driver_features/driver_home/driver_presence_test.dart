import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mshoar/core/network/api_client.dart';
import 'package:mshoar/driver_features/driver_home/data/datasources/driver_socket_service.dart';
import 'package:mshoar/driver_features/driver_home/data/driver_presence_store.dart';
import 'package:mshoar/driver_features/driver_home/data/location_ticker.dart';
import 'package:mshoar/driver_features/driver_home/presentation/cubit/driver_presence_cubit.dart';
import 'package:mshoar/driver_features/driver_home/presentation/cubit/driver_presence_state.dart';

class _FakeSocket extends Fake implements DriverSocketService {
  int connects = 0;
  bool live = false;
  void Function()? onConnect;
  void Function()? onDisconnect;
  void Function(dynamic)? onError;

  @override
  bool get isConnected => live;

  @override
  void connect({
    required String accessToken,
    required void Function() onConnect,
    required void Function() onDisconnect,
    required void Function(dynamic error) onConnectError,
  }) {
    connects++;
    this.onConnect = onConnect;
    this.onDisconnect = onDisconnect;
    onError = onConnectError;
  }

  @override
  void disconnect() => live = false;

  void serverUp() {
    live = true;
    onConnect!();
  }

  void serverDown() {
    live = false;
    onDisconnect!();
  }
}

class _FakeTicker extends Fake implements LocationTicker {
  @override
  Future<void> start(void Function(Position position) onPosition) async {}

  @override
  Future<void> stop() async {}

  @override
  void resend() {}
}

class _MemoryStore extends DriverPresenceStore {
  bool wants = false;

  @override
  Future<bool> wantsOnline() async => wants;

  @override
  Future<void> setWantsOnline(bool value) async => wants = value;
}

void main() {
  late _FakeSocket socket;
  late _MemoryStore store;
  late DriverPresenceCubit cubit;

  setUp(() {
    ApiClient.authToken = 'token';
    socket = _FakeSocket();
    store = _MemoryStore();
    cubit = DriverPresenceCubit(socket, _FakeTicker(), store);
  });

  tearDown(() async {
    ApiClient.authToken = null;
    await cubit.close();
  });

  test(
    'app start with the driver meant to be online connects by itself',
    () async {
      store.wants = true;
      await cubit.resumeIfWasOnline();

      expect(socket.connects, 1);
      expect(cubit.state.status, DriverPresenceStatus.connecting);
      socket.serverUp();
      expect(cubit.state.status, DriverPresenceStatus.online);
    },
  );

  test('a driver who was offline stays offline on app start', () async {
    await cubit.resumeIfWasOnline();
    expect(socket.connects, 0);
    expect(cubit.state.status, DriverPresenceStatus.offline);
  });

  test('going online is remembered, going offline forgets it', () async {
    await cubit.goOnline();
    expect(store.wants, isTrue);
    await cubit.goOffline();
    expect(store.wants, isFalse);
    expect(cubit.state.status, DriverPresenceStatus.offline);
  });

  test(
    '"online" with a dead socket reconnects on resume and shows Connecting',
    () async {
      await cubit.goOnline();
      socket.serverUp();
      socket.live = false; // died silently while the app was away

      await cubit.resumeIfWasOnline();

      expect(cubit.state.status, DriverPresenceStatus.connecting);
      expect(socket.connects, 2);
    },
  );

  testWidgets(
    'after a server restart it keeps retrying far past 3 attempts and comes back',
    (tester) async {
      await cubit.goOnline();
      socket.serverUp();

      socket.serverDown();
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(seconds: 9));
      }
      expect(cubit.state.status, DriverPresenceStatus.connecting);
      expect(socket.connects, greaterThan(4));

      socket.serverUp();
      expect(cubit.state.status, DriverPresenceStatus.online);
    },
  );

  test(
    'a connect error after being online is "Connecting…", not a dead end',
    () async {
      await cubit.goOnline();
      socket.serverUp();
      socket.onError!('boom');
      expect(cubit.state.status, DriverPresenceStatus.connecting);
    },
  );
}
