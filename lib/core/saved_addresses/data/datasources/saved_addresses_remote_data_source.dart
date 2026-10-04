import 'package:dio/dio.dart';
import '../../../network/api_endpoints.dart';
import '../models/saved_address_model.dart';

/// `GET/POST /api/customer/saved-addresses` and
/// `GET/PUT/DELETE /api/customer/saved-addresses/{id}` (swagger tag
/// "Customer Saved Addresses").
class SavedAddressesRemoteDataSource {
  final Dio _dio;
  final ApiEndpoints _endpoints;

  const SavedAddressesRemoteDataSource(this._dio, this._endpoints);

  /// Home first, then work, then the others.
  Future<List<SavedAddressModel>> fetchAll() async {
    final response = await _dio.get(_endpoints.customerSavedAddresses);
    final data = response.data['data'] as Map<String, dynamic>;
    return (data['addresses'] as List<dynamic>? ?? const [])
        .map((a) => SavedAddressModel.fromJson(a as Map<String, dynamic>))
        .toList();
  }

  /// Saving `home` / `work` again replaces the old one (`replaced: true`).
  Future<SavedAddressSaveResult> create(Map<String, dynamic> body) async {
    final response = await _dio.post(
      _endpoints.customerSavedAddresses,
      data: body,
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return SavedAddressSaveResult(
      address: SavedAddressModel.fromJson(data),
      replaced: data['replaced'] as bool? ?? false,
    );
  }

  /// Partial edit — `null` clears `label` / `address` / `address_details`.
  Future<SavedAddressModel> update(int id, Map<String, dynamic> changes) async {
    final response = await _dio.put(
      _endpoints.customerSavedAddressById(id),
      data: changes,
    );
    return SavedAddressModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<void> delete(int id) =>
      _dio.delete(_endpoints.customerSavedAddressById(id));
}
