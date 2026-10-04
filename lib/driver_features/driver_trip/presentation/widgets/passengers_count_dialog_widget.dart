import 'package:flutter/material.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/widgets/app_animated_dialog.dart';
import '../../../../core/widgets/number_stepper_widget.dart';

/// "How many passengers?" before starting a customer app order: 1 to [max],
/// starting at 1. [onConfirm] gets the number once the driver starts.
Future<void> showPassengersCountDialog({
  required BuildContext context,
  required int max,
  required ValueChanged<int> onConfirm,
}) {
  final l10n = context.l10n;
  var count = 1;
  return showAppDialog<void>(
    context: context,
    title: l10n.passengersCountQuestion,
    icon: Icons.groups_rounded,
    confirmLabel: l10n.driverStartedTheTrip,
    content: NumberStepperWidget(
      initialValue: count,
      min: 1,
      max: max,
      label: l10n.passengersCountQuestion,
      onChanged: (value) => count = value,
    ),
    onConfirm: () => onConfirm(count),
  );
}
