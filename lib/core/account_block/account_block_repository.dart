import 'package:dio/dio.dart';
import '../localization/app_strings.dart';
import '../models/account_block_model.dart';
import '../network/api_exception.dart';
import 'account_block_remote_data_source.dart';

class AccountBlockException implements Exception {
  final String message;

  const AccountBlockException(this.message);

  @override
  String toString() => message;
}

class AccountBlockRepository {
  final AccountBlockRemoteDataSource _remoteDataSource;

  const AccountBlockRepository(this._remoteDataSource);

  Future<AccountBlockModel> fetchCustomerBlock() async {
    try {
      return await _remoteDataSource.fetchCustomerBlock();
    } on DioException catch (e) {
      final error = e.error;
      throw AccountBlockException(
        error is ApiException ? error.message : AppStrings.current.errServerUnreachable,
      );
    }
  }
}
