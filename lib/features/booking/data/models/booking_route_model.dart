import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/l10n/generated/app_localizations.dart';

/// Model representing pickup → destination route details for a booking.
class BookingRouteModel extends Equatable {
  final String pickupAddress;
  final String destinationAddress;
  final LatLng pickupLatLng;
  final LatLng destinationLatLng;
  final int durationMinutes;
  final double distanceKm;
  final String viaRoad;

  const BookingRouteModel({
    required this.pickupAddress,
    required this.destinationAddress,
    required this.pickupLatLng,
    required this.destinationLatLng,
    required this.durationMinutes,
    required this.distanceKm,
    required this.viaRoad,
  });

  String durationLabel(AppLocalizations l10n) =>
      l10n.durationMinutes('$durationMinutes');

  String distanceLabel(AppLocalizations l10n) =>
      l10n.distanceKmVia(distanceKm.toStringAsFixed(1), viaRoad);

  BookingRouteModel swap() {
    return BookingRouteModel(
      pickupAddress: destinationAddress,
      destinationAddress: pickupAddress,
      pickupLatLng: destinationLatLng,
      destinationLatLng: pickupLatLng,
      durationMinutes: durationMinutes,
      distanceKm: distanceKm,
      viaRoad: viaRoad,
    );
  }

  BookingRouteModel copyWith({
    String? pickupAddress,
    String? destinationAddress,
    LatLng? pickupLatLng,
    LatLng? destinationLatLng,
    int? durationMinutes,
    double? distanceKm,
    String? viaRoad,
  }) {
    return BookingRouteModel(
      pickupAddress: pickupAddress ?? this.pickupAddress,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      pickupLatLng: pickupLatLng ?? this.pickupLatLng,
      destinationLatLng: destinationLatLng ?? this.destinationLatLng,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      distanceKm: distanceKm ?? this.distanceKm,
      viaRoad: viaRoad ?? this.viaRoad,
    );
  }

  @override
  List<Object?> get props => [
        pickupAddress,
        destinationAddress,
        pickupLatLng,
        destinationLatLng,
        durationMinutes,
        distanceKm,
        viaRoad,
      ];
}
