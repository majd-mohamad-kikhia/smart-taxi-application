import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/utils/format_price.dart';
import '../../../../core/widgets/warning_notice_widget.dart';
import '../../../driver_auth/presentation/cubit/driver_auth_cubit.dart';
import '../../../driver_auth/presentation/cubit/driver_auth_state.dart';

/// A heads-up under the driver's status when the wallet is at or below what
/// accepting an order needs ([AppConstants.lowDriverWalletBalance]) — so the
/// driver learns to charge it before an order is refused, not after.
///
/// Renders nothing while the balance is fine or still unknown. The balance
/// is asked of the server when this appears and whenever the app comes back
/// to the foreground (a top-up happens outside the app), so the notice never
/// rests on the copy saved at sign in.
class DriverLowWalletNoticeWidget extends StatefulWidget {
  const DriverLowWalletNoticeWidget({super.key});

  @override
  State<DriverLowWalletNoticeWidget> createState() => _DriverLowWalletNoticeWidgetState();
}

class _DriverLowWalletNoticeWidgetState extends State<DriverLowWalletNoticeWidget>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  void _refresh() => sl<DriverAuthCubit>().refreshWalletBalance();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<DriverAuthCubit, DriverAuthState, double?>(
      bloc: sl<DriverAuthCubit>(),
      // The balance only while it is low: it changing from one fine value
      // to another rebuilds nothing.
      selector: (state) => state.isWalletLow ? state.walletBalance : null,
      builder: (context, balance) {
        if (balance == null) return const SizedBox.shrink();
        final l10n = context.l10n;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: WarningNoticeWidget(
            message: l10n.driverWalletLowNotice(formatSignedPrice(l10n, balance)),
          ),
        );
      },
    );
  }
}
