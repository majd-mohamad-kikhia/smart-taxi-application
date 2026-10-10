import 'package:dio/dio.dart';
import '../../../network/api_endpoints.dart';
import '../models/ride_rating_model.dart';

/// `POST /api/customer/rides/{id}/rating` — the customer's one rating of the
/// driver of a completed trip.
class RideRatingRemoteDataSource {
  final Dio _dio;
  final ApiEndpoints _endpoints;

  const RideRatingRemoteDataSource(this._dio, this._endpoints);

  /// [stars] is 1–5; [comment] is optional (the server takes up to 500
  /// characters). Returns the rating as the server stored it.
  Future<RideRatingModel> rateRide({
    required int rideId,
    required int stars,
    String? comment,
  }) async {
    final response = await _dio.post(
      _endpoints.customerRideRating(rideId),
      data: {
        'rating': stars,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      },
    );
    final data = (response.data as Map)['data'];
    final stored = data is Map ? RideRatingModel.tryParse(data['rating']) : null;
    // The rating was accepted; if the answer is oddly shaped, what the
    // customer picked is what was stored.
    return stored ?? RideRatingModel(value: stars, comment: comment);
  }
}
