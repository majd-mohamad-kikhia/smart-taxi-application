import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/picked_location_model.dart';

/// Remote data source for creating a ride search/match request.
///
/// The backend does not expose this endpoint yet (confirmed against
/// `lib/features/auth/data/swagger.json`). `ApiEndpoints.customerRides` /
/// `customerRideById` are a *separate* order-creation step and must not be
/// used here — do not wire this method to them once the search endpoint
/// exists; ask for the actual path/body/response shape first.
class RideRequestRemoteDataSource {
  // ignore: unused_field
  final Dio _dio;
  // ignore: unused_field
  final ApiEndpoints _endpoints;

  const RideRequestRemoteDataSource(this._dio, this._endpoints);

  Future<void> searchRide({
    required PickedLocationModel from,
    required PickedLocationModel to,
  }) async {
    throw UnimplementedError(
      'RideRequestRemoteDataSource.searchRide: backend endpoint not '
      'defined yet — see swagger.json.',
    );
  }
}
