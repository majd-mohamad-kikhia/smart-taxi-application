import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/network/api_endpoints.dart';
import 'package:mshoar/core/network/api_exception.dart';
import 'package:mshoar/driver_features/driver_auth/data/models/driver_status.dart';
import 'package:mshoar/driver_features/driver_auth/data/models/driver_user_model.dart';
import 'package:mshoar/driver_features/driver_ratings/data/datasources/driver_ratings_remote_data_source.dart';
import 'package:mshoar/driver_features/driver_ratings/data/models/driver_ratings_page_model.dart';
import 'package:mshoar/driver_features/driver_ratings/data/repositories/driver_ratings_repository.dart';
import 'package:mshoar/driver_features/driver_ratings/presentation/cubit/driver_ratings_cubit.dart';

Map<String, dynamic> _page({
  int page = 1,
  int totalPages = 1,
  List<int> rideIds = const [81],
}) => {
  'summary': {
    'average': 4.8,
    'count': 12,
    'distribution': {'1': 0, '2': 0, '3': 1, '4': 2, '5': 9},
  },
  'ratings': [
    for (final id in rideIds)
      {
        'ride_id': id,
        'rating': 5,
        'comment': 'Great driver',
        'rated_at': '2026-10-08 09:30:00',
        'completed_at': '2026-10-08 09:20:00',
        'pickup_address': 'A',
        'dropoff_address': 'B',
        'customer': {'first_name': 'Ali'},
      },
  ],
  'pagination': {
    'page': page,
    'limit': 20,
    'total': 12,
    'total_pages': totalPages,
  },
};

class _FakeRemote extends DriverRatingsRemoteDataSource {
  _FakeRemote() : super(Dio(), const ApiEndpoints());

  final requested = <int>[];
  final pages = <int, DriverRatingsPageModel>{};
  ApiException? failure;

  @override
  Future<DriverRatingsPageModel> getRatings({
    required int page,
    required int limit,
  }) async {
    requested.add(page);
    final error = failure;
    if (error != null) {
      throw DioException(requestOptions: RequestOptions(), error: error);
    }
    return pages[page]!;
  }
}

void main() {
  group('DriverRatingsPageModel', () {
    test('reads the summary, the bars and the ratings', () {
      final page = DriverRatingsPageModel.fromJson(_page());

      expect(page.summary.average, 4.8);
      expect(page.summary.count, 12);
      expect(page.summary.distribution, {1: 0, 2: 0, 3: 1, 4: 2, 5: 9});
      expect(page.summary.shareOf(5), closeTo(0.75, 1e-9));
      final rating = page.ratings.single;
      expect(
        (rating.rideId, rating.stars, rating.comment),
        (81, 5, 'Great driver'),
      );
      expect(rating.customerFirstName, 'Ali');
      expect(page.hasMore, isFalse);
    });

    test('a driver with no ratings has no average and empty bars', () {
      final page = DriverRatingsPageModel.fromJson({
        'summary': {
          'average': null,
          'count': 0,
          'distribution': {'1': 0, '2': 0, '3': 0, '4': 0, '5': 0},
        },
        'ratings': <dynamic>[],
        'pagination': {'page': 1, 'limit': 20, 'total': 0, 'total_pages': 0},
      });
      expect(page.summary.average, isNull);
      expect(page.summary.shareOf(5), 0);
      expect(page.ratings, isEmpty);
    });
  });

  group('DriverRatingReceivedModel', () {
    test('reads the live event', () {
      final event = DriverRatingReceivedModel.tryParse({
        'ride_id': 81,
        'rating': 4,
        'comment': 'x',
        'average': 4.8,
        'count': 12,
      });
      expect((event?.stars, event?.average, event?.count), (4, 4.8, 12));
    });

    test('an event without usable stars is ignored', () {
      expect(DriverRatingReceivedModel.tryParse({'ride_id': 1}), isNull);
      expect(DriverRatingReceivedModel.tryParse({'rating': 9}), isNull);
    });
  });

  test('the profile average follows the driver:rating_received event', () {
    const driver = DriverUserModel(
      id: 1,
      fullName: 'Driver',
      phone: '0999',
      status: DriverStatus.active,
      walletBalance: 100,
      rating: 5,
      isOnline: false,
      accessToken: 'a',
      refreshToken: 'r',
    );
    expect(driver.copyWith(rating: 4.8).rating, 4.8);
    expect(driver.copyWith(searchRadiusKm: 3).rating, 5);
  });

  group('DriverRatingsCubit', () {
    late _FakeRemote remote;
    late DriverRatingsCubit cubit;

    setUp(() {
      remote = _FakeRemote();
      cubit = DriverRatingsCubit(DriverRatingsRepository(remote));
    });

    tearDown(() => cubit.close());

    test('loads the first page', () async {
      remote.pages[1] = DriverRatingsPageModel.fromJson(_page(totalPages: 2));
      await cubit.load();

      expect(cubit.state.isLoaded, isTrue);
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.summary.average, 4.8);
      expect(cubit.state.ratings, hasLength(1));
      expect(cubit.state.hasMore, isTrue);
    });

    test('loadMore adds the next page once, and stops at the last', () async {
      remote.pages[1] = DriverRatingsPageModel.fromJson(_page(totalPages: 2));
      remote.pages[2] = DriverRatingsPageModel.fromJson(
        _page(page: 2, totalPages: 2, rideIds: [70, 71]),
      );
      await cubit.load();

      await Future.wait([cubit.loadMore(), cubit.loadMore()]);
      expect(remote.requested, [1, 2]);
      expect(cubit.state.ratings.map((r) => r.rideId), [81, 70, 71]);
      expect(cubit.state.hasMore, isFalse);

      await cubit.loadMore();
      expect(remote.requested, [1, 2]);
    });

    test('a failed first load shows the message and can be retried', () async {
      remote.failure = const ApiException('No connection');
      await cubit.load();
      expect(cubit.state.isLoaded, isFalse);
      expect(cubit.state.errorMessage, 'No connection');

      remote.failure = null;
      remote.pages[1] = DriverRatingsPageModel.fromJson(_page());
      await cubit.load();
      expect(cubit.state.isLoaded, isTrue);
      expect(cubit.state.errorMessage, isNull);
    });

    test('a failed refresh keeps the list that is on screen', () async {
      remote.pages[1] = DriverRatingsPageModel.fromJson(_page());
      await cubit.load();

      remote.failure = const ApiException('No connection');
      await cubit.load();

      expect(cubit.state.ratings, hasLength(1));
      expect(cubit.state.isLoaded, isTrue);
    });
  });
}
