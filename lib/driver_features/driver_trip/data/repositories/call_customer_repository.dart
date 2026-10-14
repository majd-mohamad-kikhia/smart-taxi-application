import '../../../../core/localization/app_strings.dart';
import '../../../../core/utils/open_external_url.dart';
import 'driver_trip_repository.dart';

class CallCustomerException implements Exception {
  final String message;

  const CallCustomerException(this.message);

  @override
  String toString() => message;
}

/// Lets the driver ring the customer of the ride in one tap: looks up the
/// customer's number on the active ride and hands it to the phone's dialer.
class CallCustomerRepository {
  final DriverTripRepository _trips;

  const CallCustomerRepository(this._trips);

  /// Throws [CallCustomerException] when the number isn't known or the
  /// device can't place calls.
  Future<void> callCustomer({required int rideId}) async {
    final strings = AppStrings.current;
    try {
      final ride = await _trips.fetchActiveRide();
      final phone = ride?.order.rideId == rideId
          ? ride?.customer?.phoneNumber
          : null;
      final dialable = phone == null ? null : _dialable(phone);
      if (dialable == null) {
        throw CallCustomerException(strings.shareRideInfoNoPhone);
      }
      final opened = await openExternalUrl('tel:$dialable');
      if (!opened) throw CallCustomerException(strings.callNotAvailable);
    } on DriverTripException catch (e) {
      throw CallCustomerException(e.message);
    }
  }

  /// [phone] without spaces or punctuation, keeping a leading "+"; null when
  /// there are too few digits to be a number.
  static String? _dialable(String phone) {
    final trimmed = phone.trim();
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 6) return null;
    return trimmed.startsWith('+') ? '+$digits' : digits;
  }
}
