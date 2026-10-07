import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/widgets/app_neutral_button_widget.dart';
import '../../../../core/widgets/app_snack_bar_widget.dart';
import '../cubit/driver_trip_cubit.dart';
import '../cubit/share_ride_info_cubit.dart';
import '../cubit/share_ride_info_state.dart';

/// "Send my details on WhatsApp": opens the customer's chat with the
/// driver's name and car, so they know who is coming. Needs a
/// [DriverTripCubit] above.
class ShareRideInfoButtonWidget extends StatelessWidget {
  const ShareRideInfoButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ShareRideInfoCubit>(
      create: (_) => sl<ShareRideInfoCubit>(),
      child: BlocConsumer<ShareRideInfoCubit, ShareRideInfoState>(
        listenWhen: (previous, current) =>
            current.failureCount > previous.failureCount,
        listener: (context, state) => showAppSnackBar(
          context,
          state.errorMessage ?? context.l10n.shareRideInfoFailed,
          type: AppSnackBarType.error,
        ),
        builder: (context, state) => AppNeutralButtonWidget(
          label: context.l10n.shareRideInfoWhatsApp,
          icon: Icons.chat_outlined,
          isLoading: state.isSharing,
          onPressed: () {
            final order = context.read<DriverTripCubit>().state.order;
            context.read<ShareRideInfoCubit>().share(
              order.rideId,
              etaMinutes: order.pickupEta?.durationMinutes,
            );
          },
        ),
      ),
    );
  }
}
