import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/call_customer_repository.dart';
import 'call_customer_state.dart';

/// "Call the customer" on the driver's trip screen: opens the phone's
/// dialer with the customer's number.
class CallCustomerCubit extends Cubit<CallCustomerState> {
  final CallCustomerRepository _repository;

  CallCustomerCubit(this._repository) : super(const CallCustomerState());

  Future<void> call(int rideId) async {
    if (isClosed || state.isCalling) return;
    emit(CallCustomerState(isCalling: true, failureCount: state.failureCount));
    try {
      await _repository.callCustomer(rideId: rideId);
      if (!isClosed) emit(CallCustomerState(failureCount: state.failureCount));
    } on CallCustomerException catch (e) {
      if (isClosed) return;
      emit(
        CallCustomerState(
          errorMessage: e.message,
          failureCount: state.failureCount + 1,
        ),
      );
    }
  }
}
