import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/account_block/account_block_cubit.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/models/picked_location_model.dart';
import '../../../../core/services/current_location_service.dart';
import '../../../../core/session/session_cubit.dart';
import '../../data/models/ride_booking_options_model.dart';
import '../../data/repositories/places_repository.dart';
import '../../data/repositories/ride_request_repository.dart';
import 'home_state.dart';

/// Cubit driving the "create request" order flow:
/// pick two points → resolve a price quote per vehicle type → choose a
/// vehicle (which creates the ride) → cancel it. A refused order or a
/// counted cancel is handed to [AccountBlockCubit], which blocks ordering
/// and shows the server's text.
class HomeCubit extends Cubit<HomeState> {
  /// How long a GPS-button message (location off, permission denied, no
  /// address) stays on screen before it clears itself.
  static const Duration _locateErrorDuration = Duration(seconds: 4);

  Timer? _locateErrorTimer;
  final SessionCubit _sessionCubit;
  final RideRequestRepository _repository;
  final AccountBlockCubit _accountBlock;
  final CurrentLocationService _location;
  final PlacesRepository _places;

  HomeCubit(
    this._sessionCubit,
    this._repository,
    this._accountBlock,
    this._location,
    this._places,
  ) : super(HomeState.initial());

  void initialize() {
    if (isClosed) return;
    final user = _sessionCubit.state;
    emit(state.copyWith(userName: user?.firstName));
  }

  /// Puts the customer back on a ride that was live when the app closed.
  /// Sets the ride and its two points together, which is what the screen
  /// waits for to open the tracking screen — the same path as a ride just
  /// ordered. Does nothing when a ride is already shown or being ordered.
  Future<void> restoreActiveRide() async {
    if (isClosed || state.hasActiveRide || state.isBusy) return;
    try {
      final restored = await _repository.fetchActiveRide();
      if (isClosed || restored == null || state.hasActiveRide) return;
      emit(state.copyWith(
        activeRide: restored.ride,
        fromLocation: restored.pickup,
        toLocation: restored.dropoff,
        clearQuote: true,
      ));
    } on RideRequestException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(errorMessage: e.message));
    }
  }

  void setFromLocation(PickedLocationModel location) {
    if (isClosed) return;
    // Any previous quote priced a different trip.
    emit(state.copyWith(fromLocation: location, clearQuote: true));
  }

  void setToLocation(PickedLocationModel location) {
    if (isClosed) return;
    emit(state.copyWith(toLocation: location, clearQuote: true));
  }

  /// Exchanges pickup and dropoff — a no-op while the points are locked or
  /// neither is picked yet.
  void swapLocations() {
    if (isClosed || state.arePointsLocked) return;
    if (state.fromLocation == null && state.toLocation == null) return;
    emit(state.copyWith(swapLocations: true, clearQuote: true));
  }

  /// Quietly moves the map behind the screen to the customer when their
  /// position is already known. Never asks for permission and never touches
  /// the pickup — that is the GPS button's job ([locateMe]).
  Future<void> centerOnUser() async {
    final position = await _location.getPositionIfAllowed();
    if (isClosed || position == null) return;
    emit(state.copyWith(
      userLocation: PickedLocationModel(
        latitude: position.latitude,
        longitude: position.longitude,
      ),
      locateCount: state.locateCount + 1,
    ));
  }

  /// The GPS button: moves the map to the customer and, while the points can
  /// still change, sets the pickup to where they are. The pickup needs a
  /// real address, so it is only set once one is found. [setPickup] false
  /// only moves the map — used while the customer is placing a point on it.
  Future<void> locateMe({bool setPickup = true}) async {
    if (isClosed || state.isLocating) return;
    emit(state.copyWith(isLocating: true, clearError: true));
    try {
      final position = await _location.getCurrentLocation();
      if (isClosed) return;
      // The map moves at once; the address follows.
      emit(state.copyWith(
        userLocation: PickedLocationModel(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
        locateCount: state.locateCount + 1,
      ));
      if (!setPickup || state.arePointsLocked) {
        emit(state.copyWith(isLocating: false));
        return;
      }

      final address = await _places.addressFor(
        position.latitude,
        position.longitude,
      );
      if (isClosed) return;
      if (address == null || state.arePointsLocked) {
        if (address == null) {
          _showLocateError(AppStrings.current.locationUnresolved);
        } else {
          emit(state.copyWith(isLocating: false));
        }
        return;
      }
      emit(state.copyWith(
        isLocating: false,
        fromLocation: PickedLocationModel(
          latitude: position.latitude,
          longitude: position.longitude,
          address: address,
        ),
        clearQuote: true,
      ));
    } on LocationPermissionDeniedException catch (e) {
      if (isClosed) return;
      final strings = AppStrings.current;
      _showLocateError(
        e.reason == LocationFailureReason.serviceDisabled
            ? strings.errLocationServiceOff
            : strings.errLocationDenied,
      );
    }
  }

  /// Shows a GPS-button message and clears it after [_locateErrorDuration],
  /// unless something else has replaced it by then. Unlike a failed order,
  /// it needs no action from the customer, so it must not stay on screen.
  void _showLocateError(String message) {
    emit(state.copyWith(isLocating: false, errorMessage: message));
    _locateErrorTimer?.cancel();
    _locateErrorTimer = Timer(_locateErrorDuration, () {
      if (!isClosed && state.errorMessage == message) {
        emit(state.copyWith(clearError: true));
      }
    });
  }

  @override
  Future<void> close() {
    _locateErrorTimer?.cancel();
    return super.close();
  }

  /// Order flow step 1 — resolves the two pins into distance, ETA and a
  /// price per vehicle type. The screen opens the vehicle sheet when
  /// [HomeState.quote] arrives.
  Future<void> searchRide() async {
    final from = state.fromLocation;
    final to = state.toLocation;
    if (!state.canSearch || from == null || to == null || isClosed) return;

    emit(state.copyWith(isSearching: true, clearError: true, clearQuote: true));
    try {
      final quote = await _repository.resolveLocations(
        pickup: from,
        dropoff: to,
      );
      if (isClosed) return;
      emit(state.copyWith(isSearching: false, quote: quote));
    } on RideRequestException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(isSearching: false, errorMessage: _errorFor(e)));
    }
  }

  /// Order flow step 2 — creates the ride with the chosen vehicle type.
  Future<void> chooseVehicle(RideBookingOptionsModel options) async {
    final from = state.fromLocation;
    final to = state.toLocation;
    if (from == null || to == null || isClosed) return;

    emit(state.copyWith(isBooking: true, clearError: true));
    try {
      final ride = await _repository.chooseVehicle(
        options: options,
        pickup: from,
        dropoff: to,
      );
      if (isClosed) return;
      emit(state.copyWith(isBooking: false, activeRide: ride));
    } on RideRequestException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(isBooking: false, errorMessage: _errorFor(e)));
    }
  }

  /// Resets the order flow once `RideTrackingScreen` has ended the ride
  /// (completed/cancelled) — no REST call here, that already happened
  /// server-side via the tracking screen's socket events.
  void resetAfterRideEnded() {
    if (isClosed) return;
    emit(state.copyWith(clearActiveRide: true, clearQuote: true, clearLocations: true));
  }

  Future<void> cancelRide({String? reason}) async {
    final ride = state.activeRide;
    if (ride == null || isClosed) return;

    emit(state.copyWith(isCancelling: true, clearError: true));
    try {
      final cancelled = await _repository.cancelRide(
        rideId: ride.id,
        cancellationReason: reason,
      );
      final penalty = cancelled.cancelPenalty;
      if (penalty != null) _accountBlock.applyCancelPenalty(penalty);
      if (isClosed) return;
      emit(state.copyWith(
        isCancelling: false,
        clearActiveRide: true,
        clearQuote: true,
      ));
    } on RideRequestException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(isCancelling: false, errorMessage: e.message));
    }
  }

  /// A refused order blocks ordering instead: the blocked panel and dialog
  /// show the server's text, so no error banner on top of it.
  String? _errorFor(RideRequestException e) {
    final block = e.block;
    if (block == null) return e.message;
    _accountBlock.applyOrderRefusal(block);
    return null;
  }
}
