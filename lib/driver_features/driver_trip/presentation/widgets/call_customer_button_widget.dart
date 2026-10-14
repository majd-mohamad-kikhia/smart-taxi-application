import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/widgets/app_neutral_button_widget.dart';
import '../../../../core/widgets/app_snack_bar_widget.dart';
import '../cubit/call_customer_cubit.dart';
import '../cubit/call_customer_state.dart';
import '../cubit/driver_trip_cubit.dart';

/// "Call the customer": opens the dialer with their number. Needs a
/// [DriverTripCubit] above.
class CallCustomerButtonWidget extends StatelessWidget {
  const CallCustomerButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CallCustomerCubit>(
      create: (_) => sl<CallCustomerCubit>(),
      child: BlocConsumer<CallCustomerCubit, CallCustomerState>(
        listenWhen: (previous, current) =>
            current.failureCount > previous.failureCount,
        listener: (context, state) => showAppSnackBar(
          context,
          state.errorMessage ?? context.l10n.callNotAvailable,
          type: AppSnackBarType.error,
        ),
        builder: (context, state) => AppNeutralButtonWidget(
          label: context.l10n.callCustomer,
          icon: Icons.call_rounded,
          isLoading: state.isCalling,
          onPressed: () => context.read<CallCustomerCubit>().call(
            context.read<DriverTripCubit>().state.order.rideId,
          ),
        ),
      ),
    );
  }
}
