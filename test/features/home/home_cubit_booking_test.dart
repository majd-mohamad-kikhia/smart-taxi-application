import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/account_block/account_block_cubit.dart';
import 'package:mshoar/core/geo/geo_exception.dart';
import 'package:mshoar/core/geo/geo_models.dart';
import 'package:mshoar/core/models/picked_location_model.dart';
import 'package:mshoar/core/models/ride_model.dart';
import 'package:mshoar/core/models/route_point_model.dart';
import 'package:mshoar/core/services/current_location_service.dart';
import 'package:mshoar/core/session/session_cubit.dart';
import 'package:mshoar/features/home/data/datasources/ride_request_remote_data_source.dart';
import 'package:mshoar/features/home/data/models/ride_booking_options_model.dart';
import 'package:mshoar/features/home/data/models/ride_quote_model.dart';
import 'package:mshoar/features/home/data/models/vehicle_type_quote_model.dart';
import 'package:mshoar/features/home/data/repositories/places_repository.dart';
import 'package:mshoar/features/home/data/repositories/ride_request_repository.dart';
import 'package:mshoar/features/home/presentation/cubit/home_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_geo.dart';

class _FakeAccountBlock extends Fake implements AccountBlockCubit {}

class _FakeLocation extends CurrentLocationService {}

/// The order endpoint, recording what the order carried.
class _FakeRides extends Fake implements RideRequestRemoteDataSource {
  final List<({String? key, int? pickupAlias, int? dropoffAlias})> created = [];

  @override
  Future<RideModel> chooseVehicle({
    required RideBookingOptionsModel options,
    required PickedLocationModel pickup,
    required PickedLocationModel dropoff,
    String? idempotencyKey,
  }) async {
    created.add((
      key: idempotencyKey,
      pickupAlias: pickup.aliasId,
      dropoffAlias: dropoff.aliasId,
    ));
    return const RideModel(
      id: 1,
      vehicleTypeId: 6,
      priceIsEstimate: false,
      statusId: 1,
      status: 'requested',
    );
  }
}

const _from = PickedLocationModel(
  latitude: 35.52,
  longitude: 35.79,
  address: 'a',
  aliasId: 12,
);
const _to = PickedLocationModel(
  latitude: 35.58,
  longitude: 35.83,
  address: 'b',
);
const _options = RideBookingOptionsModel(vehicleTypeId: 6);

const _quote = RideQuoteModel(
  distanceKm: 8,
  estimatedDurationMin: 15,
  vehicleTypes: [
    VehicleTypeQuoteModel(
      vehicleTypeId: 6,
      name: 'economy',
      available: true,
      price: 770,
      stopsFeeTotal: 0,
    ),
  ],
);

void main() {
  late FakeGeo geo;
  late _FakeRides rides;
  late HomeCubit cubit;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    geo = FakeGeo();
    rides = _FakeRides();
    cubit =
        HomeCubit(
            SessionCubit(),
            RideRequestRepository(rides, geo),
            _FakeAccountBlock(),
            _FakeLocation(),
            PlacesRepository(geo),
          )
          ..setFromLocation(_from)
          ..setToLocation(_to);
    cubit.emit(cubit.state.copyWith(quote: _quote));
  });

  tearDown(() => cubit.close());

  test(
    'Request asks the route fare once, then creates the order with its key',
    () async {
      await cubit.chooseVehicle(_options);

      expect(geo.quoteKeys, hasLength(1));
      expect(geo.quoteKeys.single.length, inInclusiveRange(8, 64));
      expect(rides.created.single.key, geo.quoteKeys.single);
      expect(cubit.state.activeRide, isNotNull);
      expect(cubit.state.pendingBooking, isNull);
    },
  );

  test(
    'the order carries the alias id of a point that came from a search',
    () async {
      await cubit.chooseVehicle(_options);
      expect(rides.created.single.pickupAlias, 12);
      expect(rides.created.single.dropoffAlias, isNull);
    },
  );

  test('every attempt gets its own key', () async {
    await cubit.chooseVehicle(_options);
    cubit.emit(cubit.state.copyWith(clearActiveRide: true));
    await cubit.chooseVehicle(_options);
    expect(geo.quoteKeys.toSet(), hasLength(2));
  });

  test('the real route line is kept for the tracking map', () async {
    geo.quote = const GeoRouteQuoteModel(
      fare: 770,
      needsReconfirm: false,
      route: [RoutePointModel(35.52, 35.79), RoutePointModel(35.58, 35.83)],
    );

    await cubit.chooseVehicle(_options);

    expect(cubit.state.routeLine, hasLength(2));
  });

  group('a final fare more than 15 % away', () {
    setUp(() {
      geo.quote = const GeoRouteQuoteModel(fare: 900, needsReconfirm: true);
    });

    test('waits for the customer, creating nothing yet', () async {
      await cubit.chooseVehicle(_options);

      expect(cubit.state.pendingBooking?.fare, 900);
      expect(cubit.state.isBooking, isFalse);
      expect(rides.created, isEmpty);
    });

    test('accepting creates the order with the same key', () async {
      await cubit.chooseVehicle(_options);
      final key = cubit.state.pendingBooking!.idempotencyKey;

      await cubit.confirmPendingBooking();

      expect(rides.created.single.key, key);
      expect(cubit.state.pendingBooking, isNull);
      expect(cubit.state.activeRide, isNotNull);
    });

    test('declining creates nothing', () async {
      await cubit.chooseVehicle(_options);

      cubit.declinePendingBooking();

      expect(rides.created, isEmpty);
      expect(cubit.state.pendingBooking, isNull);
    });
  });

  test('a route fare that cannot be had never blocks the ride', () async {
    geo.quoteFailure = const GeoException(GeoFailure.googleDailyCap);

    await cubit.chooseVehicle(_options);

    expect(rides.created.single.key, isNull);
    expect(cubit.state.activeRide, isNotNull);
  });
}
