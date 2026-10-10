import 'package:dio/dio.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/network/api_exception.dart';
import '../datasources/driver_ratings_remote_data_source.dart';
import '../models/driver_ratings_page_model.dart';

/// Failures surface as [ApiException] so the cubit never sees a `DioException`.
class DriverRatingsRepository {
  static const int pageSize = 20;

  final DriverRatingsRemoteDataSource _remote;

  const DriverRatingsRepository(this._remote);

  Future<DriverRatingsPageModel> getRatings({required int page}) async {
    try {
      return await _remote.getRatings(page: page, limit: pageSize);
    } on DioException catch (e) {
      final error = e.error;
      throw error is ApiException
          ? error
          : ApiException(AppStrings.current.errServerUnreachable);
    } on TypeError {
      throw ApiException(AppStrings.current.errUnexpected);
    }
  }
}
