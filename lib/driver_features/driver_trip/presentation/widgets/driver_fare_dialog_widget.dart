import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/fare_breakdown_widget.dart';
import '../../data/models/driver_trip_fare_model.dart';
import '../../data/models/driver_trip_payment_model.dart';
import '../cubit/driver_trip_cubit.dart';
import '../cubit/driver_trip_state.dart';

/// Shown to the driver once a ride is finished. First the server's final
/// fare with a "Payment received" button; once the driver confirms the
/// customer paid, the money split and wallet balance, with Done. Pops with
/// no value on Done. Needs a [DriverTripCubit] above it (the caller
/// re-provides the screen's cubit, since dialogs live outside its subtree).
class DriverFareDialogWidget extends StatelessWidget {
  const DriverFareDialogWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.backgroundWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: BlocBuilder<DriverTripCubit, DriverTripState>(
          buildWhen: (previous, current) =>
              previous.isPaid != current.isPaid ||
              previous.isConfirmingPayment != current.isConfirmingPayment ||
              previous.errorMessage != current.errorMessage,
          builder: (context, state) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 40),
                  const SizedBox(height: 10),
                  Text(
                    state.isPaid
                        ? context.l10n.paymentConfirmedTitle
                        : context.l10n.fareSummaryTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (state.isPaid)
                    _PaymentDetails(payment: state.payment, fare: state.fare!)
                  else
                    _FareDetails(fare: state.fare!),
                  if (state.errorMessage != null && !state.isPaid) ...[
                    const SizedBox(height: 12),
                    Text(
                      state.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: AppColors.error),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _ActionButton(state: state),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FareDetails extends StatelessWidget {
  final DriverTripFareModel fare;

  const _FareDetails({required this.fare});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String price(double amount) => l10n.priceSyp(amount.toStringAsFixed(0));

    return Column(
      children: [
        _HeadlineAmount(label: l10n.fareFinalPrice, value: price(fare.finalPrice)),
        const SizedBox(height: 16),
        FareBreakdownWidget(fare: fare.breakdown, showTotal: false),
        const Divider(height: 20),
        _FareRow(label: l10n.fareEstimatedPrice, value: price(fare.estimatedPrice)),
        _FareRow(label: l10n.fareDifference, value: price(fare.difference)),
        _FareRow(
          label: l10n.fareDistanceDriven,
          value: l10n.distanceKm(fare.actualDistanceKm.toStringAsFixed(1)),
        ),
        _FareRow(label: l10n.fareCommission, value: price(fare.adminCommissionAmount)),
        _FareRow(
          label: l10n.fareYourEarning,
          value: price(fare.driverEarningAmount),
          isHighlighted: true,
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
    String price(double amount) => l10n.priceSyp(amount.toStringAsFixed(0));
    final payment = this.payment;

    return Column(
      children: [
        _HeadlineAmount(
          label: l10n.paymentTotalPaid,
          value: price(payment?.totalPaid ?? fare.finalPrice),
        ),
        const SizedBox(height: 16),
        _FareRow(
          label: l10n.paymentYourShare,
          value: price(payment?.driverShare ?? fare.driverEarningAmount),
          isHighlighted: true,
        ),
        _FareRow(
          label: l10n.paymentCommissionDeducted,
          value: price(payment?.managerShare ?? fare.adminCommissionAmount),
        ),
        if (payment != null)
          _FareRow(
            label: l10n.paymentWalletBalance,
            value: price(payment.walletBalanceAfter),
          ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final DriverTripState state;

  const _ActionButton({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isPaid = state.isPaid;

    return ElevatedButton(
      onPressed: state.isConfirmingPayment
          ? null
          : isPaid
          ? () => Navigator.of(context).pop()
          : context.read<DriverTripCubit>().confirmPayment,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPaid ? AppColors.primary : AppColors.success,
        foregroundColor: isPaid ? AppColors.textOnPrimary : Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: state.isConfirmingPayment
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Text(isPaid ? l10n.done : l10n.paymentReceived),
    );
  }
}

class _HeadlineAmount extends StatelessWidget {
  final String label;
  final String value;

  const _HeadlineAmount({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _FareRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlighted;

  const _FareRow({
    required this.label,
    required this.value,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final weight = isHighlighted ? FontWeight.w800 : FontWeight.w600;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: weight,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: weight,
              color: isHighlighted ? AppColors.success : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
