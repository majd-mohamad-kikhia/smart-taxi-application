import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';

/// One label and value line on the profile. The labels share one column and
/// the values share another, both starting at the same edge on every row, so
/// a list of rows reads as a table. The label may wrap and the value takes the
/// rest of the width, so a long address or a "brand model" never overflows.
/// A phone number or a plate is a left-to-right value: with [isLtrValue] it
/// keeps its order inside Arabic text and still starts at the column's edge.
class ProfileInfoRowWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLtrValue;

  const ProfileInfoRowWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.isLtrValue = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isRtlScreen = Directionality.of(context) == TextDirection.rtl;
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: '$label: $value',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingS),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: AppConstants.paddingM),
            Expanded(flex: 2, child: Text(label, style: textTheme.bodyMedium)),
            const SizedBox(width: AppConstants.paddingM),
            Expanded(
              flex: 3,
              child: Text(
                value,
                textDirection: isLtrValue ? TextDirection.ltr : null,
                // Every value starts at the column's start edge. A
                // left-to-right value inside an Arabic screen starts at the
                // same (right) edge, which is its "end" in its own direction.
                textAlign: isLtrValue && isRtlScreen
                    ? TextAlign.end
                    : TextAlign.start,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
