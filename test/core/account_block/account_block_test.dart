import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/account_block/account_block_cubit.dart';
import 'package:mshoar/core/account_block/account_block_push.dart';
import 'package:mshoar/core/account_block/account_block_repository.dart';
import 'package:mshoar/core/account_block/account_block_socket_service.dart';
import 'package:mshoar/core/account_block/account_block_state.dart';
import 'package:mshoar/core/enums/user_role.dart';
import 'package:mshoar/core/models/account_block_model.dart';
import 'package:mshoar/core/models/cancel_penalty_model.dart';
import 'package:mshoar/core/models/picked_location_model.dart';
import 'package:mshoar/core/models/ride_model.dart';
import 'package:mshoar/core/network/api_client.dart';
import 'package:mshoar/core/network/api_exception.dart';
import 'package:mshoar/features/home/data/datasources/ride_request_remote_data_source.dart';
import 'package:mshoar/features/home/data/models/ride_booking_options_model.dart';
import 'package:mshoar/features/home/data/repositories/ride_request_repository.dart';

const _blockText = 'تم إيقاف طلب الرحلات من حسابك لمدة 24 ساعة';

Map<String, dynamic> _blockedJson() => {
  'is_blocked': true,
  'blocked_until': '2026-10-04 15:42:10',
  'blocked_until_local': '04/10/2026, 18:42',
  'reason': '3 cancellations after a driver accepted',
  'reason_code': 'cancel_strikes',
  'cancel_strikes': 0,
  'strike_limit': 3,
  'block_hours': 24,
  'message': _blockText,
};

Map<String, dynamic> _penaltyRide({required int strikes, required bool blocked}) => {
  'id': 121,
  'status_id': 6,
  'status': 'cancelled',
  'cancel_penalty': {
    'counted': true,
    'cancel_strikes': strikes,
    'strike_limit': 3,
    'remaining': 3 - strikes,
    'blocked': blocked,
    'blocked_until': blocked ? '2026-10-04 15:42:10' : null,
    'blocked_until_local': blocked ? '04/10/2026, 18:42' : null,
    'block_hours': 24,
    'message': blocked ? _blockText : 'warning $strikes',
  },
};

class _FakeSocket extends Fake implements AccountBlockSocketService {
  void Function(Map<String, dynamic> data)? onBlockStatus;

  @override
  void connect({
    required String accessToken,
    required UserRole role,
    required void Function(Map<String, dynamic> data) onBlockStatus,
    required void Function() onAppVersionChanged,
  }) {
    this.onBlockStatus = onBlockStatus;
  }

  @override
  void disconnect() {}
}

class _FakeBlockRepository extends Fake implements AccountBlockRepository {
  AccountBlockModel next = AccountBlockModel.none;
  int calls = 0;

  @override
  Future<AccountBlockModel> fetchCustomerBlock() async {
    calls++;
    return next;
  }
}

class _RefusingDataSource extends Fake implements RideRequestRemoteDataSource {
  @override
  Future<RideModel> chooseVehicle({
    required RideBookingOptionsModel options,
    required PickedLocationModel pickup,
    required PickedLocationModel dropoff,
  }) async {
    final options = RequestOptions(path: '/api/customer/rides/choose-vehicle');
    throw DioException(
      requestOptions: options,
      error: const ApiException(
        'Not allowed',
        statusCode: 403,
        rawErrors: {
          'reason_code': 'cancel_strikes',
          'blocked_until': '2026-10-04 15:42:10',
          'blocked_until_local': '04/10/2026, 18:42',
          'block_reason': '3 cancellations after a driver accepted',
          'message': _blockText,
        },
      ),
    );
  }
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('models', () {
    test('block status reads UTC end, local text and server message', () {
      final block = AccountBlockModel.fromJson(_blockedJson());
      expect(block.isBlocked, isTrue);
      expect(block.blockedUntil, DateTime.utc(2026, 10, 4, 15, 42, 10));
      expect(block.blockedUntilLocal, '04/10/2026, 18:42');
      expect(block.reasonCode, AccountBlockModel.reasonCancelStrikes);
      expect(block.message, _blockText);
      expect(block.blockHours, 24);
    });

    test('nextCancelBlocks at limit - 1', () {
      expect(const AccountBlockModel(isBlocked: false, cancelStrikes: 1, strikeLimit: 3).nextCancelBlocks, isFalse);
      expect(const AccountBlockModel(isBlocked: false, cancelStrikes: 2, strikeLimit: 3).nextCancelBlocks, isTrue);
      expect(const AccountBlockModel(isBlocked: false).nextCancelBlocks, isFalse);
    });

    test('cancel penalty: null or not counted gives nothing', () {
      expect(CancelPenaltyModel.fromRide({'id': 1, 'cancel_penalty': null}), isNull);
      expect(CancelPenaltyModel.fromRide({'id': 1}), isNull);
      expect(CancelPenaltyModel.fromRide({'cancel_penalty': {'counted': false}}), isNull);
    });

    test('cancel penalty and the REST ride read it', () {
      final penalty = CancelPenaltyModel.fromRide(_penaltyRide(strikes: 3, blocked: true))!;
      expect(penalty.blocked, isTrue);
      expect(penalty.blockedUntil, DateTime.utc(2026, 10, 4, 15, 42, 10));
      expect(penalty.message, _blockText);
      expect(
        RideModel.fromJson(_penaltyRide(strikes: 1, blocked: false)).cancelPenalty?.cancelStrikes,
        1,
      );
    });
  });

  group('order refused while blocked', () {
    test('403 carries the block and the server text', () async {
      final repository = RideRequestRepository(_RefusingDataSource());
      final error = await repository
          .chooseVehicle(
            options: const RideBookingOptionsModel(vehicleTypeId: 2),
            pickup: const PickedLocationModel(latitude: 1, longitude: 1),
            dropoff: const PickedLocationModel(latitude: 2, longitude: 2),
          )
          .then<RideRequestException?>((_) => null, onError: (Object e) => e as RideRequestException);
      expect(error?.message, _blockText);
      expect(error?.block?.isBlocked, isTrue);
      expect(error?.block?.blockedUntilLocal, '04/10/2026, 18:42');
    });
  });

  group('AccountBlockCubit', () {
    late _FakeSocket socket;
    late _FakeBlockRepository repository;
    late StreamController<AccountBlockPush> pushes;
    late AccountBlockCubit cubit;

    setUp(() {
      ApiClient.authToken = 'token';
      socket = _FakeSocket();
      repository = _FakeBlockRepository()
        ..next = const AccountBlockModel(isBlocked: false, cancelStrikes: 1, strikeLimit: 3, blockHours: 24);
      pushes = StreamController<AccountBlockPush>.broadcast();
      cubit = AccountBlockCubit(socket, repository, pushes.stream)
        ..start(UserRole.customer, onAppVersionChanged: () {});
    });

    tearDown(() async {
      await cubit.close();
      await pushes.close();
      ApiClient.authToken = null;
    });

    test('loads the strikes on start', () async {
      await _settle();
      expect(repository.calls, 1);
      expect(cubit.state.block.cancelStrikes, 1);
      expect(cubit.state.block.strikeLimit, 3);
    });

    test('a counted cancel warns and updates the count', () async {
      await _settle();
      cubit.applyCancelPenalty(CancelPenaltyModel.fromRide(_penaltyRide(strikes: 2, blocked: false))!);
      expect(cubit.state.isBlocked, isFalse);
      expect(cubit.state.block.cancelStrikes, 2);
      expect(cubit.state.notice, const AccountBlockNotice(message: 'warning 2', blocked: false));
      expect(cubit.state.noticeCount, 1);
    });

    test('the 3rd counted cancel blocks at once', () async {
      await _settle();
      cubit.applyCancelPenalty(CancelPenaltyModel.fromRide(_penaltyRide(strikes: 3, blocked: true))!);
      expect(cubit.state.isBlocked, isTrue);
      expect(cubit.state.block.message, _blockText);
      expect(cubit.state.block.blockedUntil, DateTime.utc(2026, 10, 4, 15, 42, 10));
      expect(cubit.state.notice?.blocked, isTrue);
    });

    test('a refused order blocks and shows the text', () async {
      await _settle();
      repository.next = AccountBlockModel.fromJson(_blockedJson());
      cubit.applyOrderRefusal(AccountBlockModel.fromOrderRefusal(const {
        'reason_code': 'manager',
        'blocked_until': '2026-10-05 09:00:00',
        'message': 'manager block',
      }));
      expect(cubit.state.isBlocked, isTrue);
      expect(cubit.state.notice, const AccountBlockNotice(message: 'manager block', blocked: true));
    });

    test('socket snapshot keeps the strikes it does not carry', () async {
      await _settle();
      socket.onBlockStatus!({'action': 'snapshot', 'is_blocked': false, 'strike_limit': 3});
      expect(cubit.state.block.cancelStrikes, 1);
    });

    test('socket blocked switches at once, then loads the text', () async {
      await _settle();
      repository.next = AccountBlockModel.fromJson(_blockedJson());
      socket.onBlockStatus!({..._blockedJson()..remove('message'), 'action': 'blocked'});
      expect(cubit.state.isBlocked, isTrue);
      await _settle();
      expect(cubit.state.block.message, _blockText);
      expect(cubit.state.notice, isNull);
    });

    test('socket unblocked goes back to normal', () async {
      await _settle();
      cubit.applyCancelPenalty(CancelPenaltyModel.fromRide(_penaltyRide(strikes: 3, blocked: true))!);
      repository.next = const AccountBlockModel(isBlocked: false, strikeLimit: 3);
      socket.onBlockStatus!({'action': 'unblocked', 'is_blocked': false, 'cancel_strikes': 0, 'strike_limit': 3});
      expect(cubit.state.isBlocked, isFalse);
    });

    test('a tapped block push reloads and shows the block text', () async {
      await _settle();
      repository.next = AccountBlockModel.fromJson(_blockedJson());
      pushes.add((type: 'customer_auto_blocked', opened: true));
      await _settle();
      await _settle();
      expect(cubit.state.isBlocked, isTrue);
      expect(cubit.state.notice, const AccountBlockNotice(message: _blockText, blocked: true));
    });

    test('logout forgets the block', () async {
      await _settle();
      cubit.applyCancelPenalty(CancelPenaltyModel.fromRide(_penaltyRide(strikes: 3, blocked: true))!);
      cubit.stop();
      expect(cubit.state, const AccountBlockState());
    });
  });
}
