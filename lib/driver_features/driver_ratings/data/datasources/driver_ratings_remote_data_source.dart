import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/driver_ratings_page_model.dart';

/// `GET /api/driver/ratings` — the ratings customers gave this driver,
/// newest first, with the summary on every page.
class DriverRatingsRemoteDataSource {
  final Dio _dio;
  final ApiEndpoints _endpoints;

  const DriverRatingsRemoteDataSource(this._dio, this._endpoints);

  Future<DriverRatingsPageModel> getRatings({
    required int page,
    required int limit,
  }) async {
    final response = await _dio.get(
      _endpoints.driverRatings,
      queryParameters: {'page': page, 'limit': limit},
    );
    return DriverRatingsPageModel.fromJson(
      Map<String, dynamic>.from((response.data as Map)['data'] as Map),
    );
  }
}
