import 'package:dio/dio.dart';
import '../../../localization/app_strings.dart';
import '../../../network/api_exception.dart';
import '../../../network/status_code.dart';
import '../datasources/ride_rating_remote_data_source.dart';
import '../models/ride_rating_model.dart';

class RideRatingException implements Exception {
  final String message;
  final int? statusCode;

  const RideRatingException(this.message, {this.statusCode});

  /// `409 This trip was already rated`: the rating exists, so there is
  /// nothing left to send. (The other 409, "Only a completed trip can be
  /// rated", is a plain error.)
  bool get isAlreadyRated =>
      statusCode == StatusCode.conflict &&
      message.toLowerCase().contains('already');

  @override
  String toString() => message;
}

class RideRatingRepository {
  final RideRatingRemoteDataSource _remote;

  const RideRatingRepository(this._remote);

  Future<RideRatingModel> rateRide({
    required int rideId,
    required int stars,
    String? comment,
  }) async {
    try {
      return await _remote.rateRide(rideId: rideId, stars: stars, comment: comment);
    } on DioException catch (e) {
      final error = e.error;
      throw RideRatingException(
        error is ApiException ? error.message : AppStrings.current.errServerUnreachable,
        statusCode: error is ApiException ? error.statusCode : null,
      );
    }
  }
}
