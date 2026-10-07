import 'dart:ui' show Locale;
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/utils/open_external_url.dart';
import '../../../../core/utils/whatsapp_number.dart';
import 'driver_trip_repository.dart';

class ShareRideInfoException implements Exception {
  final String message;

  const ShareRideInfoException(this.message);

  @override
  String toString() => message;
}

/// Tells the customer who is coming: opens their WhatsApp chat with a ready
/// message (driver name, phone, car and, when the server worked it out, the
/// time to the pickup) for the driver to send.
class ShareRideInfoRepository {
  final DriverTripRepository _trips;

  const ShareRideInfoRepository(this._trips);

  /// Throws [ShareRideInfoException] when the customer's number, the car or
  /// WhatsApp itself isn't there.
  Future<void> shareWithCustomer({
    required int rideId,
    required String driverName,
    required String driverPhone,
    int? etaMinutes,
  }) async {
    final strings = AppStrings.current;
    try {
      final (ride, vehicle) = await (
        _trips.fetchActiveRide(),
        _trips.fetchVehicle(),
      ).wait;
      final phone = ride?.order.rideId == rideId
          ? ride?.customer?.phoneNumber
          : null;
      final number = phone == null ? null : whatsAppNumber(phone);
      if (number == null) {
        throw ShareRideInfoException(strings.shareRideInfoNoPhone);
      }

      String block(Locale locale) {
        final l10n = lookupAppLocalizations(locale);
        final message = l10n.shareRideInfoMessage(
          driverName,
          driverPhone,
          vehicle.color,
          vehicle.brand,
          vehicle.model,
          vehicle.plateNumber,
        );
        final etaLine = etaMinutes == null
            ? null
            : l10n.shareRideInfoEta(etaMinutes);
        return [message, ?etaLine].join('\n');
      }

      final text = [
        block(const Locale('ar')),
        block(const Locale('en')),
      ].join('\n\n');
      final opened = await openExternalUrl(
        'https://wa.me/$number?text=${Uri.encodeComponent(text)}',
      );
      if (!opened) throw ShareRideInfoException(strings.shareRideInfoFailed);
    } on DriverTripException catch (e) {
      throw ShareRideInfoException(e.message);
    }
  }
}
