import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';
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
    return TrackingState(
      captain: const CaptainModel(
        id: 'cap_1',
        name: 'عبدالرحمن الشمري',
        rating: 4.9,
        completedTrips: 1420,
        isVerified: true,
        vehicleModel: 'تويوتا كامري 2024',
        vehicleColor: 'رمادي',
        plateNumber: '2948',
        plateLetters: 'أ ب ج',
      ),
      trip: LiveTripModel(
        id: 'trip_live_1',
        status: LiveTripStatus.captainOnTheWay,
        etaMinutes: 4,
        captainLatLng: const LatLng(24.6950, 46.6780),
        pickupLatLng: const LatLng(24.6877, 46.6858),
        pickupTitle: 'أمام بوابة المجمع الرئيسية',
        pickupSubtitle: 'طريق الملك فهد، مقابل النافورة',
        paymentMethod: 'محفظة مشوار',
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
