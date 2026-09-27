import 'package:dio/dio.dart';
import '../../../../core/network/api_exception.dart';
import '../datasources/driver_complaints_remote_data_source.dart';

/// Structured failure thrown by [DriverComplaintsRepository], so the Cubit
/// never has to interpret a raw exception.
class DriverComplaintsException implements Exception {
  final String message;

  const DriverComplaintsException(this.message);

  @override
  String toString() => message;
}

/// Repository for driver complaints. The Cubit talks to this, never to
/// [DriverComplaintsRemoteDataSource] directly.
class DriverComplaintsRepository {
  final DriverComplaintsRemoteDataSource _remoteDataSource;

  const DriverComplaintsRepository(this._remoteDataSource);

  Future<void> submitComplaint({required String message, String? subject}) async {
    try {
      await _remoteDataSource.submitComplaint(message: message, subject: subject);
    } on DioException catch (e) {
      final error = e.error;
      throw DriverComplaintsException(
        error is ApiException ? error.message : 'تعذر الاتصال بالخادم',
      );
    }
  }
}
