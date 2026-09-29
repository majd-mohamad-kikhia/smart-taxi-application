import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/localization/app_strings.dart';
import '../../data/models/captain_model.dart';
import '../../data/models/live_trip_model.dart';

/// Immutable state for the Live Trip Tracking screen.
class TrackingState extends Equatable {
  final CaptainModel captain;
  final LiveTripModel trip;
  final bool isCancelling;
  final bool isCancelled;

  const TrackingState({
    required this.captain,
    required this.trip,
    required this.isCancelling,
    required this.isCancelled,
  });

  factory TrackingState.initial() {
    // Sample data, worded in the language active when the state is created.
    final l10n = AppStrings.current;
    return TrackingState(
      captain: CaptainModel(
        id: 'cap_1',
        name: l10n.mockCaptainName,
        rating: 4.9,
        completedTrips: 1420,
        isVerified: true,
        vehicleModel: l10n.mockVehicleModel,
        vehicleColor: l10n.mockVehicleColor,
        plateNumber: '2948',
        plateLetters: l10n.mockPlateLetters,
      ),
      trip: LiveTripModel(
        id: 'trip_live_1',
        status: LiveTripStatus.captainOnTheWay,
        etaMinutes: 4,
        captainLatLng: const LatLng(24.6950, 46.6780),
        pickupLatLng: const LatLng(24.6877, 46.6858),
        pickupTitle: l10n.mockPickupTitle,
        pickupSubtitle: l10n.mockPickupSubtitle,
        paymentMethod: l10n.mockPaymentWallet,
        fare: 38.50,
        isTrackingEnabled: true,
        isLocationSharingEnabled: true,
      ),
      isCancelling: false,
      isCancelled: false,
    );
  }

  TrackingState copyWith({
    CaptainModel? captain,
    LiveTripModel? trip,
    bool? isCancelling,
    bool? isCancelled,
  }) {
    return TrackingState(
      captain: captain ?? this.captain,
      trip: trip ?? this.trip,
      isCancelling: isCancelling ?? this.isCancelling,
      isCancelled: isCancelled ?? this.isCancelled,
    );
  }

  @override
  List<Object?> get props => [captain, trip, isCancelling, isCancelled];
}
