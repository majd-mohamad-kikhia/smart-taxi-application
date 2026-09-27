import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';

/// Remote data source for driver complaints — talks to
/// `POST /api/driver/complaints` (see swagger.json).
class DriverComplaintsRemoteDataSource {
  final Dio _dio;
  final ApiEndpoints _endpoints;

  const DriverComplaintsRemoteDataSource(this._dio, this._endpoints);

  Future<void> submitComplaint({required String message, String? subject}) {
    return _dio.post(
      _endpoints.driverComplaints,
      data: {
        'message': message,
        if (subject != null && subject.isNotEmpty) 'subject': subject,
      },
    );
  }
}
