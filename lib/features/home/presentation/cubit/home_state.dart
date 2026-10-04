import 'package:equatable/equatable.dart';
import '../../../../core/models/picked_location_model.dart';
import '../../../../core/models/ride_model.dart';
import '../../data/models/ride_quote_model.dart';

/// Part of the day the greeting is for — the text itself is resolved in the
/// UI so it follows the active language.
enum GreetingPeriod {
  morning,
  afternoon,
  evening;

  static GreetingPeriod fromHour(int hour) => hour < 12
      ? GreetingPeriod.morning
      : hour < 17
          ? GreetingPeriod.afternoon
          : GreetingPeriod.evening;
}

class HomeState extends Equatable {
  final GreetingPeriod greeting;
  final String userName;
  final PickedLocationModel? fromLocation;
  final PickedLocationModel? toLocation;

  /// Step 1 in flight — resolving the two pins into a price quote.
  final bool isSearching;

  /// Step 1 result: distance/ETA + a price per vehicle type.
  final RideQuoteModel? quote;

  /// Step 2 in flight — creating the ride with the chosen vehicle.
  final bool isBooking;

  /// The created ride. While this is set the screen shows "Cancel request"
  /// instead of "Search".
  final RideModel? activeRide;

  /// A ride that was just scheduled for later — set until the screen has
  /// confirmed it to the customer.
  final RideModel? scheduledRide;

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
    this.scheduledRide,
    required this.isCancelling,
    this.errorMessage,
  });

  factory HomeState.initial() {
    return HomeState(
      greeting: GreetingPeriod.fromHour(DateTime.now().hour),
      userName: '',
      isSearching: false,
      isBooking: false,
      isCancelling: false,
    );
  }

  /// Both pickup and dropoff must be picked before "Search" is enabled.
  bool get canSearch => fromLocation != null && toLocation != null;

  /// A ride exists, so the primary action becomes cancelling it.
  bool get hasActiveRide => activeRide != null;

  bool get isBusy => isSearching || isBooking || isCancelling;

  HomeState copyWith({
    GreetingPeriod? greeting,
    String? userName,
    PickedLocationModel? fromLocation,
    PickedLocationModel? toLocation,
    bool? isSearching,
    RideQuoteModel? quote,
    bool? isBooking,
    RideModel? activeRide,
    RideModel? scheduledRide,
    bool? isCancelling,
    String? errorMessage,
    bool clearError = false,
    bool clearQuote = false,
    bool clearActiveRide = false,
    bool clearScheduledRide = false,
    bool clearLocations = false,
  }) {
    return HomeState(
      greeting: greeting ?? this.greeting,
      userName: userName ?? this.userName,
      fromLocation: clearLocations ? null : (fromLocation ?? this.fromLocation),
      toLocation: clearLocations ? null : (toLocation ?? this.toLocation),
      isSearching: isSearching ?? this.isSearching,
      quote: clearQuote ? null : (quote ?? this.quote),
      isBooking: isBooking ?? this.isBooking,
      activeRide: clearActiveRide ? null : (activeRide ?? this.activeRide),
      scheduledRide:
          clearScheduledRide ? null : (scheduledRide ?? this.scheduledRide),
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
        scheduledRide,
        isCancelling,
        errorMessage,
      ];
}
