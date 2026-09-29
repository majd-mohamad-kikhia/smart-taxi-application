import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';

/// Remote data source for customer complaints — talks to
/// `POST /api/customer/complaints` (see swagger.json).
class CustomerComplaintsRemoteDataSource {
  final Dio _dio;
  final ApiEndpoints _endpoints;

  const CustomerComplaintsRemoteDataSource(this._dio, this._endpoints);

  Future<void> submitComplaint({required String message, String? subject}) {
    return _dio.post(
      _endpoints.customerComplaints,
      data: {
        'message': message,
        if (subject != null && subject.isNotEmpty) 'subject': subject,
      },
    );
  }
}
