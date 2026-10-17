import 'package:flutter/material.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/format_price.dart';

/// A wallet amount in new pounds with its currency, and the same amount in
/// old pounds on its own line under it. The old amount keeps a readable size
/// of its own instead of shrinking with the headline figure.
class WalletAmountWidget extends StatelessWidget {
  final double amount;

  /// The headline figure's style; defaults to a bold title.
  final TextStyle? style;
  final CrossAxisAlignment alignment;

  const WalletAmountWidget({
    super.key,
    required this.amount,
    this.style,
    this.alignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final headline = (style ?? textTheme.titleLarge)?.copyWith(
      fontWeight: FontWeight.w800,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final textAlign = alignment == CrossAxisAlignment.end
        ? TextAlign.end
        : TextAlign.start;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignment,
      children: [
        // Scales down only when even the whole width is too small for it.
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            formatNewSyp(l10n, amount),
            textAlign: textAlign,
            style: headline,
          ),
        ),
        Text(
          formatOldSyp(l10n, amount),
          textAlign: textAlign,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: context.colors.textSecondary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
