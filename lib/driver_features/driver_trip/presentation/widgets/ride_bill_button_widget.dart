import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/widgets/app_neutral_button_widget.dart';
import '../../../../core/widgets/app_snack_bar_widget.dart';
import '../cubit/driver_trip_cubit.dart';
import '../cubit/ride_bill_cubit.dart';
import '../cubit/ride_bill_state.dart';

/// "Send bill on WhatsApp" for a paid trip (app or office order): opens the customer's
/// chat with the trip's PDF bill attached. Needs a [DriverTripCubit] above.
class RideBillButtonWidget extends StatelessWidget {
  const RideBillButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RideBillCubit>(
      create: (_) => sl<RideBillCubit>(),
      child: BlocConsumer<RideBillCubit, RideBillState>(
        listenWhen: (previous, current) => current.failureCount > previous.failureCount,
        listener: (context, state) => showAppSnackBar(
          context,
          state.errorMessage ?? context.l10n.billSendFailed,
          type: AppSnackBarType.error,
        ),
        builder: (context, state) => AppNeutralButtonWidget(
          label: context.l10n.billSendWhatsApp,
          icon: Icons.picture_as_pdf_outlined,
          isLoading: state.isSending,
          onPressed: () => context.read<RideBillCubit>().send(
            context.read<DriverTripCubit>().state,
            origin: _origin(context),
          ),
        ),
      ),
    );
  }

  /// The button's rect, for the share sheet's popover on an iPad.
  static Rect? _origin(BuildContext context) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }
}
