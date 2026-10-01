import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format_price.dart';
import '../../../../core/widgets/app_animated_dialog.dart';
import '../../../../core/widgets/app_dialog_layout_widget.dart';
import '../../../../core/widgets/auth_error_banner_widget.dart';
import '../../../../core/widgets/auth_primary_button_widget.dart';
import '../../../../core/widgets/bill_row_widget.dart';
import '../../../../core/widgets/fare_breakdown_widget.dart';
import '../../data/models/driver_trip_fare_model.dart';
import '../../data/models/driver_trip_payment_model.dart';
import '../cubit/driver_trip_cubit.dart';
import '../cubit/driver_trip_state.dart';

/// Shown to the driver once a ride is finished. First what to collect from
/// the customer (the final fare, and the driver's earnings under it) with a
/// "Payment received" button; the rest of the bill is one tap away under
/// "Fare details". If confirming fails, the reason shows above the button,
/// which then reads "Retry". Once the driver confirms the customer paid, the
/// money split and wallet balance appear, with Done. Pops with no value on
/// Done. Needs a [DriverTripCubit] above it (the caller re-provides the
/// screen's cubit, since dialogs live outside its subtree).
class DriverFareDialogWidget extends StatefulWidget {
  const DriverFareDialogWidget({super.key});

  @override
  State<DriverFareDialogWidget> createState() => _DriverFareDialogWidgetState();
}

class _DriverFareDialogWidgetState extends State<DriverFareDialogWidget> {
  /// Done was tapped; the dialog is closing. Stops a second tap from
  /// popping whatever route is underneath.
  bool _leaving = false;

  void _done() {
    setState(() => _leaving = true);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppDialogLayoutWidget(
      child: BlocBuilder<DriverTripCubit, DriverTripState>(
        buildWhen: (previous, current) =>
            previous.isPaid != current.isPaid ||
            previous.isConfirmingPayment != current.isConfirmingPayment ||
            previous.errorMessage != current.errorMessage,
        builder: (context, state) {
          final fare = state.fare!;
          final isPaid = state.isPaid;
          return AppAnimatedDialog(
            title: isPaid ? l10n.paymentConfirmedTitle : l10n.fareSummaryTitle,
            cancelLabel: l10n.goBack,
            icon: isPaid ? Icons.check_circle_rounded : Icons.payments_outlined,
            tone: isPaid ? AppDialogTone.success : AppDialogTone.warning,
            showActions: false,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isPaid)
                  _PaymentDetails(payment: state.payment, fare: fare)
                else
                  _FareDetails(fare: fare),
                if (state.errorMessage != null && !isPaid) ...[
                  const SizedBox(height: AppConstants.paddingM),
                  AuthErrorBannerWidget(message: state.errorMessage!),
                ],
                const SizedBox(height: AppConstants.paddingL),
                AuthPrimaryButtonWidget(
                  label: isPaid
                      ? l10n.done
                      : (state.errorMessage != null ? l10n.retry : l10n.paymentReceived),
                  isLoading: state.isConfirmingPayment,
                  onPressed: _leaving
                      ? null
                      : isPaid
                      ? _done
                      : context.read<DriverTripCubit>().confirmPayment,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

String _price(BuildContext context, double amount) =>
    context.l10n.priceSyp(formatPrice(amount));

/// What to collect, the driver's earnings, and the rest of the bill folded
/// away under "Fare details".
class _FareDetails extends StatelessWidget {
  final DriverTripFareModel fare;

  const _FareDetails({required this.fare});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        _HeadlineAmount(
          label: l10n.fareCollectFromCustomer,
          value: _price(context, fare.finalPrice),
        ),
        const SizedBox(height: AppConstants.paddingM),
        _EarningsChip(
          label: l10n.fareYourEarning,
          value: _price(context, fare.driverEarningAmount),
        ),
        Theme(
          data: Theme.of(context).copyWith(dividerColor: AppColors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            shape: const Border(),
            collapsedShape: const Border(),
            iconColor: AppColors.textSecondary,
            collapsedIconColor: AppColors.textSecondary,
            title: Text(l10n.fareDetails, style: textTheme.titleSmall),
            children: [
              FareBreakdownWidget(fare: fare.breakdown, showTotal: false),
              const Divider(height: AppConstants.paddingXL),
              BillRowWidget(
                label: l10n.fareEstimatedPrice,
                value: _price(context, fare.estimatedPrice),
              ),
              BillRowWidget(
                label: l10n.fareDifference,
                value: _price(context, fare.difference),
              ),
              BillRowWidget(
                label: l10n.fareDistanceDriven,
                value: l10n.distanceKm(fare.actualDistanceKm.toStringAsFixed(1)),
              ),
              BillRowWidget(
                label: l10n.fareCommission,
                value: _price(context, fare.adminCommissionAmount),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The money split after "Payment received". Falls back to the fare's own
/// numbers when the server's reply had no `payment` block.
class _PaymentDetails extends StatelessWidget {
  final DriverTripPaymentModel? payment;
  final DriverTripFareModel fare;

  const _PaymentDetails({required this.payment, required this.fare});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final payment = this.payment;

    return Column(
      children: [
        _HeadlineAmount(
          label: l10n.paymentTotalPaid,
          value: _price(context, payment?.totalPaid ?? fare.finalPrice),
        ),
        const SizedBox(height: AppConstants.paddingM),
        _EarningsChip(
          label: l10n.paymentYourShare,
          value: _price(context, payment?.driverShare ?? fare.driverEarningAmount),
        ),
        const SizedBox(height: AppConstants.paddingS),
        BillRowWidget(
          label: l10n.paymentCommissionDeducted,
          value: _price(context, payment?.managerShare ?? fare.adminCommissionAmount),
        ),
        if (payment != null)
          BillRowWidget(
            label: l10n.paymentWalletBalance,
            value: _price(context, payment.walletBalanceAfter),
          ),
      ],
    );
  }
}

/// The big number: heavy, tabular, and scaled down to fit rather than
/// squeezed or cut off.
class _HeadlineAmount extends StatelessWidget {
  final String label;
  final String value;

  const _HeadlineAmount({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(label, textAlign: TextAlign.center, style: textTheme.bodyMedium),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

/// The driver's own number, on its green wash so it reads as "yours" at a
/// glance without competing with the amount to collect.
class _EarningsChip extends StatelessWidget {
  final String label;
  final String value;

  const _EarningsChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: AppColors.successSurface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.account_balance_wallet_outlined,
            color: AppColors.success,
            size: 20,
          ),
          const SizedBox(width: AppConstants.paddingS),
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppConstants.paddingS),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: textTheme.titleMedium?.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
