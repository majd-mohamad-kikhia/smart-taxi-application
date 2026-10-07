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

  final bool isCancelling;
  final String? errorMessage;

  /// The GPS button is waiting for a fix and its address.
  final bool isLocating;

  /// Where the customer is, for the map behind the screen to move to. Only
  /// meaningful together with [locateCount]: asking for the same spot twice
  /// must still move a map the customer has dragged away.
  final PickedLocationModel? userLocation;
  final int locateCount;

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
    required this.isLocating,
    this.userLocation,
    required this.locateCount,
  });

  factory HomeState.initial() {
    return HomeState(
      greeting: GreetingPeriod.fromHour(DateTime.now().hour),
      userName: '',
      isSearching: false,
      isBooking: false,
      isCancelling: false,
      isLocating: false,
      locateCount: 0,
    );
  }

  /// Both pickup and dropoff must be picked before "Search" is enabled.
  bool get canSearch => fromLocation != null && toLocation != null;

  /// A ride exists, so the primary action becomes cancelling it.
  bool get hasActiveRide => activeRide != null;

  bool get isBusy => isSearching || isBooking || isCancelling;

  /// While a quote or booking is in flight, a changed pin would leave the
  /// prices (or the ride) for a different trip than the one on screen.
  bool get arePointsLocked => hasActiveRide || isBusy;

  HomeState copyWith({
    GreetingPeriod? greeting,
    String? userName,
    PickedLocationModel? fromLocation,
    PickedLocationModel? toLocation,
    bool? isSearching,
    RideQuoteModel? quote,
    bool? isBooking,
    RideModel? activeRide,
    bool? isCancelling,
    String? errorMessage,
    bool? isLocating,
    PickedLocationModel? userLocation,
    int? locateCount,
    bool clearError = false,
    bool clearQuote = false,
    bool clearActiveRide = false,
    bool clearLocations = false,
    bool swapLocations = false,
  }) {
    return HomeState(
      greeting: greeting ?? this.greeting,
      userName: userName ?? this.userName,
      fromLocation: clearLocations
          ? null
          : swapLocations
              ? this.toLocation
              : (fromLocation ?? this.fromLocation),
      toLocation: clearLocations
          ? null
          : swapLocations
              ? this.fromLocation
              : (toLocation ?? this.toLocation),
      isSearching: isSearching ?? this.isSearching,
      quote: clearQuote ? null : (quote ?? this.quote),
      isBooking: isBooking ?? this.isBooking,
      activeRide: clearActiveRide ? null : (activeRide ?? this.activeRide),
      isCancelling: isCancelling ?? this.isCancelling,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isLocating: isLocating ?? this.isLocating,
      userLocation: userLocation ?? this.userLocation,
      locateCount: locateCount ?? this.locateCount,
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
        isLocating,
        userLocation,
        locateCount,
      ];
}
