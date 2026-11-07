import 'package:dio/dio.dart';
import '../network/api_endpoints.dart';

/// Remote data source for `GET /api/app/map-provider` (public).
class MapProviderRemoteDataSource {
  final Dio _dio;
  final ApiEndpoints _endpoints;

  const MapProviderRemoteDataSource(this._dio, this._endpoints);

  /// The provider the manager chose: `google` or `osm`.
  Future<String?> fetchProvider() async {
    final response = await _dio.get(_endpoints.appMapProvider);
    final data = (response.data as Map)['data'];
    final provider = data is Map ? data['provider'] : null;
    return provider is String ? provider : null;
  }
}
