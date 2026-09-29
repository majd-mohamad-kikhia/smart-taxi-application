import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/l10n/generated/app_localizations.dart';

/// Status of an active live trip.
enum LiveTripStatus { captainOnTheWay, arrived, inProgress, completed }

/// Model representing live trip tracking data.
class LiveTripModel extends Equatable {
  final String id;
  final LiveTripStatus status;
  final int etaMinutes;
  final LatLng captainLatLng;
  final LatLng pickupLatLng;
  final String pickupTitle;
  final String pickupSubtitle;
  final String paymentMethod;
  final double fare;
  final bool isTrackingEnabled;
  final bool isLocationSharingEnabled;

  const LiveTripModel({
    required this.id,
    required this.status,
    required this.etaMinutes,
    required this.captainLatLng,
    required this.pickupLatLng,
    required this.pickupTitle,
    required this.pickupSubtitle,
    required this.paymentMethod,
    required this.fare,
    required this.isTrackingEnabled,
    required this.isLocationSharingEnabled,
  });

  String statusTitle(AppLocalizations l10n) {
    return switch (status) {
      LiveTripStatus.captainOnTheWay => l10n.liveCaptainOnTheWay,
      LiveTripStatus.arrived => l10n.liveArrived,
      LiveTripStatus.inProgress => l10n.liveInProgress,
      LiveTripStatus.completed => l10n.liveCompleted,
    };
  }

  String statusSubtitle(AppLocalizations l10n) {
    return switch (status) {
      LiveTripStatus.captainOnTheWay => l10n.liveEtaOnly('$etaMinutes'),
      LiveTripStatus.arrived => l10n.liveArrivedSub,
      LiveTripStatus.inProgress => l10n.liveRemaining('$etaMinutes'),
      LiveTripStatus.completed => l10n.liveThanks,
    };
  }

  String etaShortLabel(AppLocalizations l10n) =>
      l10n.durationMinutesShort('$etaMinutes');

  String fareLabel(AppLocalizations l10n) =>
      l10n.priceSar(fare.toStringAsFixed(2));

  LiveTripModel copyWith({
    String? id,
    LiveTripStatus? status,
    int? etaMinutes,
    LatLng? captainLatLng,
    LatLng? pickupLatLng,
    String? pickupTitle,
    String? pickupSubtitle,
    String? paymentMethod,
    double? fare,
    bool? isTrackingEnabled,
    bool? isLocationSharingEnabled,
  }) {
    return LiveTripModel(
      id: id ?? this.id,
      status: status ?? this.status,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      captainLatLng: captainLatLng ?? this.captainLatLng,
      pickupLatLng: pickupLatLng ?? this.pickupLatLng,
      pickupTitle: pickupTitle ?? this.pickupTitle,
      pickupSubtitle: pickupSubtitle ?? this.pickupSubtitle,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      fare: fare ?? this.fare,
      isTrackingEnabled: isTrackingEnabled ?? this.isTrackingEnabled,
      isLocationSharingEnabled:
          isLocationSharingEnabled ?? this.isLocationSharingEnabled,
    );
  }

  @override
  List<Object?> get props => [
        id,
        status,
        etaMinutes,
        captainLatLng,
        pickupLatLng,
        pickupTitle,
        pickupSubtitle,
        paymentMethod,
        fare,
        isTrackingEnabled,
        isLocationSharingEnabled,
      ];
}
