import 'package:dio/dio.dart';
import '../../../localization/app_strings.dart';
import '../../../network/api_exception.dart';
import '../datasources/saved_addresses_remote_data_source.dart';
import '../models/saved_address_model.dart';

/// Every failure is an [ApiException] (with per-field errors for 409 / 422).
class SavedAddressesRepository {
  final SavedAddressesRemoteDataSource _remote;

  const SavedAddressesRepository(this._remote);

  Future<List<SavedAddressModel>> getAll() => _guard(_remote.fetchAll);

  Future<SavedAddressSaveResult> create({
    required SavedAddressType type,
    String? label,
    required double lat,
    required double lng,
    String? address,
    String? addressDetails,
  }) {
    return _guard(() => _remote.create({
          'type': type.wireValue,
          'label': ?label,
          'lat': lat,
          'lng': lng,
          'address': ?address,
          'address_details': ?addressDetails,
        }));
  }

  Future<SavedAddressModel> update(int id, Map<String, dynamic> changes) =>
      _guard(() => _remote.update(id, changes));

  Future<void> delete(int id) => _guard(() => _remote.delete(id));

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
