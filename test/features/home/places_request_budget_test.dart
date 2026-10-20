import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mshoar/core/account_block/account_block_cubit.dart';
import 'package:mshoar/core/models/picked_location_model.dart';
import 'package:mshoar/core/services/current_location_service.dart';
import 'package:mshoar/core/services/google_api_credentials_loader.dart';
import 'package:mshoar/core/session/session_cubit.dart';
import 'package:mshoar/features/home/data/datasources/google_places_data_source.dart';
import 'package:mshoar/features/home/data/datasources/recent_places_local_data_source.dart';
import 'package:mshoar/features/home/data/repositories/places_repository.dart';
import 'package:mshoar/features/home/data/repositories/ride_request_repository.dart';
import 'package:mshoar/features/home/presentation/cubit/home_cubit.dart';
import 'package:mshoar/features/home/presentation/cubit/map_pick_cubit.dart';
import 'package:mshoar/features/home/presentation/cubit/map_pick_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Answers like Google's Geocoding API and counts what is asked: the test
/// never reaches the network.
class _CountingAdapter implements HttpClientAdapter {
  int forward = 0;
  int reverse = 0;

  int get total => forward + reverse;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final query = options.queryParameters;
    final Map<String, dynamic> body;
    if (query.containsKey('address')) {
      forward++;
      body = {
        'status': 'OK',
        'results': [
          {
            'formatted_address': 'مطار باسل الأسد الدولي، اللاذقية، سوريا',
            'address_components': [
              {
                'long_name': 'مطار باسل الأسد الدولي',
                'types': ['establishment', 'point_of_interest'],
              },
            ],
            'geometry': {
              'location': {'lat': 35.4011, 'lng': 35.9487},
            },
          },
          {
            'formatted_address': 'طريق المطار، اللاذقية، سوريا',
            'address_components': [
              {
                'long_name': 'طريق المطار',
                'types': ['route'],
              },
            ],
            'geometry': {
              'location': {'lat': 35.45, 'lng': 35.9},
            },
          },
        ],
      };
    } else {
      reverse++;
      body = {
        'status': 'OK',
        'results': [
          {
            'types': ['route'],
            'formatted_address': 'شارع بغداد، اللاذقية، سوريا',
            'address_components': [
              {
                'long_name': 'شارع بغداد',
                'types': ['route'],
              },
              {
                'long_name': 'اللاذقية',
                'types': ['locality'],
              },
            ],
          },
        ],
      };
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _FakeAccountBlock extends Fake implements AccountBlockCubit {}

class _FakeRideRepository extends Fake implements RideRequestRepository {}

class _FakeLocation extends CurrentLocationService {
  @override
  Future<Position> getCurrentLocation() async => _here;

  @override
  Future<Position?> getPositionAskingOnce() async => _here;

  @override
  Future<Position?> getPositionIfAllowed() async => _here;
}

final _here = Position(
  latitude: 35.5200,
  longitude: 35.7900,
  timestamp: DateTime(2026),
  accuracy: 1,
  altitude: 0,
  altitudeAccuracy: 1,
  heading: 0,
  headingAccuracy: 1,
  speed: 0,
  speedAccuracy: 1,
);

void main() {
  late _CountingAdapter google;
  late PlacesRepository places;
  late HomeCubit home;
  late MapPickCubit pick;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    google = _CountingAdapter();
    places = PlacesRepository(
      GooglePlacesDataSource(
        credentials: () async => const GoogleApiCredentials(apiKey: 'KEY'),
        dio: Dio()..httpClientAdapter = google,
      ),
      const RecentPlacesLocalDataSource(),
    );
    home = HomeCubit(
      SessionCubit(),
      _FakeRideRepository(),
      _FakeAccountBlock(),
      _FakeLocation(),
      places,
    );
    pick = MapPickCubit(places, _FakeLocation());
  });

  tearDown(() async {
    await home.close();
    await pick.close();
  });

  test(
    'open the order screen, search "airport", pick a result, drag the pin once: 3 requests',
    () async {
      // Opening the order screen names where the customer is: 1 reverse.
      await home.setDefaultPickup();
      expect(home.state.fromLocation?.address, 'شارع بغداد، اللاذقية');
      expect(google.total, 1);

      // Tapping the search box opens the pick mode: nothing is asked.
      pick.enter(PickTarget.to, autofocusSearch: true);
      await pumpEventQueue();
      expect(google.total, 1);

      // Typing asks nothing; submitting asks once.
      for (final typed in [
        'a',
        'ai',
        'air',
        'airp',
        'airpo',
        'airpor',
        'airport',
      ]) {
        pick.queryChanged(typed);
      }
      expect(google.total, 1);
      await pick.submitSearch('airport');
      expect(google.forward, 1);
      expect(pick.state.suggestions, hasLength(2));

      // Choosing a result and letting the camera settle on it asks nothing.
      final chosen = pick.state.suggestions.first;
      pick.selectSuggestion(chosen);
      pick.onCameraMoveStarted();
      pick.onCameraIdle(chosen.latitude, chosen.longitude);
      await pumpEventQueue();
      expect(google.total, 2);
      expect(pick.state.address, chosen.description);

      // Dragging the pin once to a new spot names it: 1 reverse.
      pick.onCameraMoveStarted();
      pick.onCameraMove(35.43, 35.92);
      pick.onCameraIdle(35.43, 35.92);
      await pumpEventQueue();
      expect(google.total, 3);
      expect(google.forward, 1);
      expect(google.reverse, 2);

      // Confirming asks nothing more.
      final picked = await pick.confirm();
      expect(picked?.address, 'شارع بغداد، اللاذقية');
      expect(google.total, 3);
    },
  );

  test(
    'coming back to the order screen from where the customer already is costs nothing',
    () async {
      await home.setDefaultPickup();
      expect(google.reverse, 1);

      // The "create order" tab tapped again: the points are cleared and the
      // pickup is the customer's position again.
      home.setToLocation(
        const PickedLocationModel(
          latitude: 35.4,
          longitude: 35.9,
          address: 'x',
        ),
      );
      home.resetPoints();
      await pumpEventQueue();

      expect(home.state.fromLocation?.address, 'شارع بغداد، اللاذقية');
      expect(home.state.toLocation, isNull);
      expect(google.reverse, 1);
    },
  );

  test('the GPS button pressed twice in the same place asks once', () async {
    await home.locateMe();
    await home.locateMe();

    expect(google.reverse, 1);
    expect(home.state.fromLocation?.address, 'شارع بغداد، اللاذقية');
  });
}
