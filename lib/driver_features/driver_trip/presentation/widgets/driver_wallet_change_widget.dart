import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/format_price.dart';
import '../../../../core/widgets/app_choice_chip_widget.dart';
import '../../../../core/widgets/app_neutral_button_widget.dart';
import '../cubit/driver_trip_cubit.dart';
import '../cubit/driver_trip_state.dart';

/// Under the amount to collect: a button "Add change to the customer's
/// wallet". It opens the amounts the driver can leave — 10, 20, 30, 40 or
/// another amount of his own, never more than
/// [DriverTripState.maxWalletCredit] — and the choice goes to the cubit,
/// which sends it with "Payment received". Tapping an amount again, or the
/// button, takes the choice back.
class DriverWalletChangeWidget extends StatefulWidget {
  const DriverWalletChangeWidget({super.key});

  @override
  State<DriverWalletChangeWidget> createState() =>
      _DriverWalletChangeWidgetState();
}

class _DriverWalletChangeWidgetState extends State<DriverWalletChangeWidget> {
  static const _presets = [10, 20, 30, 40];

  final _customController = TextEditingController();
  bool _isOpen = false;

  /// The chosen preset, or null when none (or "Other" is chosen).
  int? _preset;
  bool _isCustom = false;

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  double get _customAmount => double.tryParse(_customController.text) ?? 0;

  void _report() {
    final credit = !_isOpen
        ? 0.0
        : (_isCustom ? _customAmount : (_preset ?? 0).toDouble());
    context.read<DriverTripCubit>().setWalletCredit(credit);
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (!_isOpen) {
        _preset = null;
        _isCustom = false;
        _customController.clear();
      }
    });
    _report();
  }

  void _pickPreset(int amount, bool selected) {
    setState(() {
      _preset = selected ? amount : null;
      _isCustom = false;
    });
    _report();
  }

  void _pickCustom(bool selected) {
    setState(() {
      _isCustom = selected;
      _preset = null;
    });
    _report();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final max = DriverTripState.maxWalletCredit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppNeutralButtonWidget(
          label: _isOpen ? l10n.walletChangeCancel : l10n.walletChangeButton,
          icon: _isOpen
              ? Icons.close_rounded
              : Icons.account_balance_wallet_outlined,
          onPressed: _toggle,
        ),
        if (_isOpen) ...[
          const SizedBox(height: AppConstants.paddingM),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppConstants.paddingS,
            runSpacing: AppConstants.paddingS,
            children: [
              for (final amount in _presets)
                AppChoiceChipWidget(
                  label: formatPlainSypAndOld(l10n, amount),
                  selected: _preset == amount,
                  onSelected: (selected) => _pickPreset(amount, selected),
                ),
              AppChoiceChipWidget(
                label: l10n.walletChangeOther,
                selected: _isCustom,
                onSelected: _pickCustom,
              ),
            ],
          ),
          if (_isCustom) ...[
            const SizedBox(height: AppConstants.paddingM),
            TextField(
              controller: _customController,
              autofocus: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                // An amount above the limit is not typed at all.
                TextInputFormatter.withFunction(
                  (oldValue, newValue) =>
                      (double.tryParse(newValue.text) ?? 0) > max
                      ? oldValue
                      : newValue,
                ),
              ],
              decoration: InputDecoration(
                labelText: l10n.walletChangeCustomLabel(
                  formatPlainSyp(l10n, max),
                ),
              ),
              onChanged: (_) {
                setState(() {});
                _report();
              },
            ),
          ],
          if (_preset != null || (_isCustom && _customAmount > 0)) ...[
            const SizedBox(height: AppConstants.paddingS),
            Text(
              l10n.walletChangeWalletHint,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
            ),
          ],
        ],
      ],
    );
  }
}
