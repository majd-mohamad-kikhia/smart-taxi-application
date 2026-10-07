import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/session/session_cubit.dart';
import '../../data/repositories/share_ride_info_repository.dart';
import 'share_ride_info_state.dart';

/// "Send my details on WhatsApp" after accepting a ride: opens the
/// customer's chat with the driver's name and car ready to send.
class ShareRideInfoCubit extends Cubit<ShareRideInfoState> {
  final ShareRideInfoRepository _repository;
  final SessionCubit _session;

  ShareRideInfoCubit(this._repository, this._session)
    : super(const ShareRideInfoState());

  Future<void> share(int rideId, {int? etaMinutes}) async {
    final driver = _session.state;
    if (isClosed || state.isSharing || driver == null) return;
    emit(ShareRideInfoState(isSharing: true, failureCount: state.failureCount));
    try {
      await _repository.shareWithCustomer(
        rideId: rideId,
        driverName: driver.fullName,
        driverPhone: driver.phone,
        etaMinutes: etaMinutes,
      );
      if (!isClosed) emit(ShareRideInfoState(failureCount: state.failureCount));
    } on ShareRideInfoException catch (e) {
      if (isClosed) return;
      emit(
        ShareRideInfoState(
          errorMessage: e.message,
          failureCount: state.failureCount + 1,
        ),
      );
    }
  }
}
