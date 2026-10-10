import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/l10n/generated/app_localizations.dart';
import 'package:mshoar/core/network/api_endpoints.dart';
import 'package:mshoar/core/network/api_exception.dart';
import 'package:mshoar/core/ride_rating/data/datasources/ride_rating_remote_data_source.dart';
import 'package:mshoar/core/ride_rating/data/models/ride_rating_model.dart';
import 'package:mshoar/core/ride_rating/data/repositories/ride_rating_repository.dart';
import 'package:mshoar/core/ride_rating/presentation/cubit/ride_rating_cubit.dart';
import 'package:mshoar/core/ride_rating/presentation/cubit/ride_rating_state.dart';
import 'package:mshoar/core/ride_rating/presentation/widgets/ride_rating_dialog_widget.dart';
import 'package:mshoar/features/trips/data/models/ride_history_model.dart';

class _FakeRemote extends RideRatingRemoteDataSource {
  _FakeRemote() : super(Dio(), const ApiEndpoints());

  final sent = <({int rideId, int stars, String? comment})>[];
  ApiException? failure;

  @override
  Future<RideRatingModel> rateRide({
    required int rideId,
    required int stars,
    String? comment,
  }) async {
    sent.add((rideId: rideId, stars: stars, comment: comment));
    final error = failure;
    if (error != null) {
      throw DioException(requestOptions: RequestOptions(), error: error);
    }
    return RideRatingModel(value: stars, comment: comment);
  }
}

Map<String, dynamic> _ride({Object? canRate, Object? rating}) => {
  'id': 81,
  'status_id': 5,
  'status': 'completed',
  'price': 190,
  'requested_at': '2026-10-08T09:00:00Z',
  'can_rate': ?canRate,
  'rating': ?rating,
};

void main() {
  group('RideRatingModel.tryParse', () {
    test('reads the stars, comment and time', () {
      final rating = RideRatingModel.tryParse({
        'value': 4,
        'comment': ' Good driver ',
        'rated_at': '2026-10-08 10:37:50',
      });
      expect(rating?.value, 4);
      expect(rating?.comment, 'Good driver');
      expect(rating?.ratedAt, '2026-10-08 10:37:50');
    });

    test('null or unusable means no rating', () {
      expect(RideRatingModel.tryParse(null), isNull);
      expect(RideRatingModel.tryParse({'value': 0}), isNull);
      expect(RideRatingModel.tryParse({'value': 6}), isNull);
      expect(RideRatingModel.tryParse({'comment': 'x'}), isNull);
    });
  });

  group('a customer ride', () {
    test('can_rate shows the button, rating shows the stars', () {
      final unrated = RideHistoryModel.fromJson(_ride(canRate: true));
      expect(unrated.canRate, isTrue);
      expect(unrated.rating, isNull);

      final rated = RideHistoryModel.fromJson(
        _ride(canRate: false, rating: {'value': 4, 'comment': 'Good driver'}),
      );
      expect(rated.canRate, isFalse);
      expect(rated.rating?.value, 4);
    });

    test('a ride without the new fields cannot be rated', () {
      final ride = RideHistoryModel.fromJson(_ride());
      expect(ride.canRate, isFalse);
      expect(ride.rating, isNull);
    });

    test('once rated locally the button goes and the stars show', () {
      final rated = RideHistoryModel.fromJson(
        _ride(canRate: true),
      ).withRating(const RideRatingModel(value: 5));
      expect(rated.canRate, isFalse);
      expect(rated.rating?.value, 5);
      expect(rated.id, 81);
    });
  });

  group('RideRatingCubit', () {
    late _FakeRemote remote;
    late RideRatingCubit cubit;

    setUp(() {
      remote = _FakeRemote();
      cubit = RideRatingCubit(RideRatingRepository(remote), rideId: 81);
    });

    tearDown(() => cubit.close());

    test('Send needs a star', () async {
      expect(cubit.state.canSend, isFalse);
      await cubit.send('nice');
      expect(remote.sent, isEmpty);

      cubit.selectStars(4);
      expect(cubit.state.canSend, isTrue);
    });

    test('sends the stars and the trimmed comment once', () async {
      cubit.selectStars(4);
      await cubit.send('  Good driver ');

      expect(remote.sent, [(rideId: 81, stars: 4, comment: 'Good driver')]);
      expect(cubit.state.status, RideRatingStatus.sent);
      expect(cubit.state.saved?.value, 4);

      await cubit.send('again');
      expect(remote.sent, hasLength(1));
    });

    test('a comment left empty is not sent', () async {
      cubit.selectStars(5);
      await cubit.send('   ');
      expect(remote.sent.single.comment, isEmpty);
    });

    test('409 already rated is not an error to retry', () async {
      remote.failure = const ApiException(
        'This trip was already rated',
        statusCode: 409,
      );
      cubit.selectStars(3);
      await cubit.send('');
      expect(cubit.state.status, RideRatingStatus.alreadyRated);
    });

    test(
      '409 not completed and other failures keep the form open with the message',
      () async {
        remote.failure = const ApiException(
          'Only a completed trip can be rated',
          statusCode: 409,
        );
        cubit.selectStars(3);
        await cubit.send('');
        expect(cubit.state.status, RideRatingStatus.editing);
        expect(cubit.state.errorMessage, 'Only a completed trip can be rated');
        expect(cubit.state.stars, 3);

        remote.failure = null;
        await cubit.send('');
        expect(cubit.state.status, RideRatingStatus.sent);
      },
    );
  });

  group('rating dialog', () {
    late _FakeRemote remote;
    RideRatingOutcome? outcome;
    var closed = false;

    Future<void> open(WidgetTester tester) async {
      remote = _FakeRemote();
      outcome = null;
      closed = false;
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    outcome = await showRideRatingDialog(
                      context,
                      createCubit: () => RideRatingCubit(
                        RideRatingRepository(remote),
                        rideId: 81,
                      ),
                    );
                    closed = true;
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
    }

    testWidgets('asks for stars and a comment; Send waits for a star', (
      tester,
    ) async {
      await open(tester);
      expect(find.text('Rate your driver'), findsOneWidget);
      expect(find.byIcon(Icons.star_outline_rounded), findsNWidgets(5));

      final send = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Send rating'),
      );
      expect(send.onPressed, isNull);
    });

    testWidgets('picking 4 stars and sending closes it with the rating', (
      tester,
    ) async {
      await open(tester);
      await tester.tap(find.bySemanticsLabel('4 out of 5 stars'));
      await tester.pump();
      expect(
        find.byIcon(Icons.star_rounded),
        findsNWidgets(4 + 1),
      ); // 4 filled + the title badge

      await tester.enterText(find.byType(TextField), 'Good driver');
      await tester.tap(find.text('Send rating'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      expect(remote.sent.single.stars, 4);
      expect(remote.sent.single.comment, 'Good driver');
      expect(closed, isTrue);
      expect(outcome?.rating?.value, 4);
    });

    testWidgets('Skip sends nothing', (tester) async {
      await open(tester);
      await tester.tap(find.text('Skip'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      expect(remote.sent, isEmpty);
      expect(closed, isTrue);
      expect(outcome, isNull);
    });
  });
}
