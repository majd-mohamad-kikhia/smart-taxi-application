import 'package:equatable/equatable.dart';
import 'driver_status.dart';
import 'driver_vehicle_model.dart';

/// The signed-in driver, built from the API's `driver` + `vehicle` +
/// `tokens` response objects (see `DriverAuthSuccessData` in
/// swagger.json).
class DriverUserModel extends Equatable {
  final int id;
  final String fullName;
  final String phone;
  final String? photoUrl;
  final String? address;
  final DriverStatus status;
  final double walletBalance;
  final double? rating;
  final bool isOnline;
  final DriverVehicleModel? vehicle;
  final double searchRadiusKm;
  final String accessToken;
  final String refreshToken;

  const DriverUserModel({
    required this.id,
    required this.fullName,
    required this.phone,
    this.photoUrl,
    this.address,
    required this.status,
    required this.walletBalance,
    this.rating,
    required this.isOnline,
    this.vehicle,
    this.searchRadiusKm = 1,
    required this.accessToken,
    required this.refreshToken,
  });

  /// Builds a [DriverUserModel] from a login response's `data` object,
  /// i.e. `{ "driver": {...}, "vehicle": {...} | null, "tokens": {...} }`.
  factory DriverUserModel.fromApiData(Map<String, dynamic> data) {
    final driver = data['driver'] as Map<String, dynamic>;
    final tokens = data['tokens'] as Map<String, dynamic>;
    final vehicleJson = data['vehicle'] as Map<String, dynamic>?;
    return DriverUserModel(
      id: driver['id'] as int,
      fullName: '${driver['first_name']} ${driver['last_name']}',
      phone: driver['phone_number'] as String,
      photoUrl: driver['photo_url'] as String?,
      address: driver['address'] as String?,
      status: DriverStatus.fromId(driver['status_id'] as int),
      walletBalance: (driver['wallet_balance'] as num).toDouble(),
      rating: (driver['rating'] as num?)?.toDouble(),
      isOnline: driver['is_online'] as bool? ?? false,
      vehicle:
          vehicleJson != null ? DriverVehicleModel.fromJson(vehicleJson) : null,
      searchRadiusKm: (driver['search_radius_km'] as num?)?.toDouble() ?? 1,
      accessToken: tokens['accessToken'] as String,
      refreshToken: tokens['refreshToken'] as String,
    );
  }

  DriverUserModel copyWith({double? searchRadiusKm}) {
    return DriverUserModel(
      id: id,
      fullName: fullName,
      phone: phone,
      photoUrl: photoUrl,
      address: address,
      status: status,
      walletBalance: walletBalance,
      rating: rating,
      isOnline: isOnline,
      vehicle: vehicle,
      searchRadiusKm: searchRadiusKm ?? this.searchRadiusKm,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  @override
  List<Object?> get props => [
        id,
        fullName,
        phone,
        photoUrl,
        address,
        status,
        walletBalance,
        rating,
        isOnline,
        vehicle,
        searchRadiusKm,
        accessToken,
        refreshToken,
      ];
}
