import 'dart:ui' show Rect;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/session/session_cubit.dart';
import '../../data/models/ride_bill_model.dart';
import '../../data/repositories/ride_bill_repository.dart';
import 'driver_trip_state.dart';
import 'ride_bill_state.dart';

/// "Send bill on WhatsApp" at the end of an office order: turns the paid
/// trip into a PDF bill and opens the customer's chat with it.
class RideBillCubit extends Cubit<RideBillState> {
  final RideBillRepository _repository;
  final SessionCubit _session;

  RideBillCubit(this._repository, this._session) : super(const RideBillState());

  Future<void> send(DriverTripState trip, {Rect? origin}) async {
    final bill = billOf(trip);
    if (isClosed || state.isSending || bill == null) return;
    emit(RideBillState(isSending: true, failureCount: state.failureCount));
    try {
      await _repository.sendOnWhatsApp(bill, origin: origin);
      if (!isClosed) emit(RideBillState(failureCount: state.failureCount));
    } on RideBillException catch (e) {
      if (isClosed) return;
      emit(RideBillState(errorMessage: e.message, failureCount: state.failureCount + 1));
    }
  }

  /// Null until the trip is a finished, paid office order.
  RideBillModel? billOf(DriverTripState trip) {
    final fare = trip.fare;
    if (!trip.canSendBill || fare == null) return null;
    return RideBillModel(
      rideId: trip.order.rideId,
      issuedAt: (trip.completedAt ?? DateTime.now()).toLocal(),
      customerName: trip.customer?.fullName,
      customerPhone: trip.customer?.phoneNumber,
      driverName: _session.state?.fullName,
      pickupAddress: trip.order.pickupAddress,
      dropoffAddress: trip.order.dropoffAddress,
      distanceKm: fare.actualDistanceKm,
      breakdown: fare.breakdown,
    );
  }
}
