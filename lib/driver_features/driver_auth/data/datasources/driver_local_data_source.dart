import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/driver_status.dart';
import '../models/driver_user_model.dart';
import '../models/driver_vehicle_model.dart';

/// Persists the signed-in driver's session locally via
/// [SharedPreferences], so the app doesn't force a fresh login on every
/// restart. Mirrors the auth feature's `AuthLocalDataSource` — deliberately
/// stores only what a successful login already returned, never the
/// password.
class DriverLocalDataSource {
  static const _sessionKey = 'driver_session';

  const DriverLocalDataSource();

  Future<void> saveSession(DriverUserModel driver) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _sessionKey,
      jsonEncode({
        'id': driver.id,
        'full_name': driver.fullName,
        'phone': driver.phone,
        'photo_url': driver.photoUrl,
        'address': driver.address,
        'status': driver.status.name,
        'wallet_balance': driver.walletBalance,
        'rating': driver.rating,
        'is_online': driver.isOnline,
        'search_radius_km': driver.searchRadiusKm,
        'vehicle': driver.vehicle == null
            ? null
            : {
                'id': driver.vehicle!.id,
                'vehicle_type_id': driver.vehicle!.vehicleTypeId,
                'vehicle_type_name': driver.vehicle!.vehicleTypeName,
                'brand': driver.vehicle!.brand,
                'model': driver.vehicle!.model,
                'color': driver.vehicle!.color,
                'plate_number': driver.vehicle!.plateNumber,
                'photo_url': driver.vehicle!.photoUrl,
                'ownership': driver.vehicle!.ownership?.wireValue,
              },
        'access_token': driver.accessToken,
        'refresh_token': driver.refreshToken,
      }),
    );
  }

  Future<DriverUserModel?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionKey);
    if (raw == null) return null;

    final json = jsonDecode(raw) as Map<String, dynamic>;
    final vehicleJson = json['vehicle'] as Map<String, dynamic>?;
    return DriverUserModel(
      id: json['id'] as int,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String,
      photoUrl: json['photo_url'] as String?,
      address: json['address'] as String?,
      status: DriverStatus.values.byName(json['status'] as String),
      walletBalance: (json['wallet_balance'] as num).toDouble(),
      rating: (json['rating'] as num?)?.toDouble(),
      isOnline: json['is_online'] as bool? ?? false,
      searchRadiusKm: (json['search_radius_km'] as num?)?.toDouble() ?? 1,
      vehicle: vehicleJson != null
          ? DriverVehicleModel(
              id: vehicleJson['id'] as int,
              vehicleTypeId: vehicleJson['vehicle_type_id'] as int,
              vehicleTypeName: vehicleJson['vehicle_type_name'] as String,
              brand: vehicleJson['brand'] as String,
              model: vehicleJson['model'] as String,
              color: vehicleJson['color'] as String,
              plateNumber: vehicleJson['plate_number'] as String,
              photoUrl: vehicleJson['photo_url'] as String?,
              ownership: VehicleOwnership.fromWire(vehicleJson['ownership']),
            )
          : null,
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
    );
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }
}
