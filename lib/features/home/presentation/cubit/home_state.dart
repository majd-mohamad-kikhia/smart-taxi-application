import 'package:equatable/equatable.dart';
import '../../data/models/picked_location_model.dart';
import '../../data/models/ride_model.dart';
import '../../data/models/ride_quote_model.dart';

/// Immutable state for the "إنشاء طلب" (create request) screen.
class HomeState extends Equatable {
  final String greeting;
  final String userName;
  final PickedLocationModel? fromLocation;
  final PickedLocationModel? toLocation;

  /// Step 1 in flight — resolving the two pins into a price quote.
  final bool isSearching;

  /// Step 1 result: distance/ETA + a price per vehicle type.
  final RideQuoteModel? quote;

  /// Step 2 in flight — creating the ride with the chosen vehicle.
  final bool isBooking;

  /// The created ride. While this is set the screen shows "إلغاء الطلب"
  /// instead of "بحث".
  final RideModel? activeRide;

  final bool isCancelling;
  final String? errorMessage;

  const HomeState({
    required this.greeting,
    required this.userName,
    this.fromLocation,
    this.toLocation,
    required this.isSearching,
    this.quote,
    required this.isBooking,
    this.activeRide,
    required this.isCancelling,
    this.errorMessage,
  });

  factory HomeState.initial() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'صباح الخير'
        : hour < 17
            ? 'مساء الخير'
            : 'مساء النور';

    return HomeState(
      greeting: greeting,
      userName: '',
      isSearching: false,
      isBooking: false,
      isCancelling: false,
    );
  }

  /// Both pickup and dropoff must be picked before "بحث" is enabled.
  bool get canSearch => fromLocation != null && toLocation != null;

  /// A ride exists, so the primary action becomes cancelling it.
  bool get hasActiveRide => activeRide != null;

  bool get isBusy => isSearching || isBooking || isCancelling;

  HomeState copyWith({
    String? greeting,
    String? userName,
    PickedLocationModel? fromLocation,
    PickedLocationModel? toLocation,
    bool? isSearching,
    RideQuoteModel? quote,
    bool? isBooking,
    RideModel? activeRide,
    bool? isCancelling,
    String? errorMessage,
    bool clearError = false,
    bool clearQuote = false,
    bool clearActiveRide = false,
  }) {
    return HomeState(
      greeting: greeting ?? this.greeting,
      userName: userName ?? this.userName,
      fromLocation: fromLocation ?? this.fromLocation,
      toLocation: toLocation ?? this.toLocation,
      isSearching: isSearching ?? this.isSearching,
      quote: clearQuote ? null : (quote ?? this.quote),
      isBooking: isBooking ?? this.isBooking,
      activeRide: clearActiveRide ? null : (activeRide ?? this.activeRide),
      isCancelling: isCancelling ?? this.isCancelling,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        greeting,
        userName,
        fromLocation,
        toLocation,
        isSearching,
        quote,
        isBooking,
        activeRide,
        isCancelling,
        errorMessage,
      ];
}
