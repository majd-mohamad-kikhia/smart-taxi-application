import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';

/// One line of a bill: a label (with an optional detail such as
/// "3 min × 500") and a right-aligned value. Values use tabular figures so
/// amounts line up, and [isBold] makes the line the heaviest of the bill
/// (a total). [valueColor] tints the value, e.g. green for the driver's
/// earnings. The detail uses Text Secondary, not the dimmer tertiary tone,
/// so it stays readable.
class BillRowWidget extends StatelessWidget {
  final String label;
  final String value;
  final String? detail;
  final bool isBold;
  final Color? valueColor;

  const BillRowWidget({
    super.key,
    required this.label,
    required this.value,
    this.detail,
    this.isBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final weight = isBold ? FontWeight.w800 : FontWeight.w600;
    final base = textTheme.bodyMedium?.copyWith(fontWeight: weight);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingXS),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                text: label,
                children: [
                  if (detail != null)
                    TextSpan(text: '  ($detail)', style: textTheme.bodySmall),
                ],
              ),
              style: base,
            ),
          ),
          const SizedBox(width: AppConstants.paddingS),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: base?.copyWith(
                color: valueColor ?? AppColors.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
