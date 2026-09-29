import 'package:dio/dio.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/localization/app_strings.dart';
import '../datasources/profile_remote_data_source.dart';
import '../models/customer_profile_model.dart';

/// Repository for the customer profile. Failures surface as
/// [ApiException] so the Cubit never sees a raw `DioException`.
class ProfileRepository {
  final ProfileRemoteDataSource _remote;

  const ProfileRepository(this._remote);

  Future<CustomerProfileModel> getProfile() => _guard(_remote.getProfile);

  Future<CustomerProfileModel> updateProfile(Map<String, dynamic> fields) =>
      _guard(() => _remote.updateProfile(fields));

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      final error = e.error;
      throw error is ApiException
          ? error
          : ApiException(AppStrings.current.errServerUnreachable);
    }
  }
}
