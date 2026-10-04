/// Which ride has a trip screen open right now, so a `driver:active_ride`
/// for that ride (sent again on every socket connect) doesn't open a second
/// one. One instance per app session.
class OpenTripRegistry {
  int? _openRideId;

  int? get openRideId => _openRideId;

  void open(int rideId) => _openRideId = rideId;

  void close(int rideId) {
    if (_openRideId == rideId) _openRideId = null;
  }
}
