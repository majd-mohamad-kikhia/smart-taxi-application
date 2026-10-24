import 'package:flutter/material.dart';
import '../localization/l10n_context_extension.dart';
import '../utils/format_price.dart';

/// A price from the API (new Syrian pounds) as a figure in [style], with the
/// same price in old pounds on a smaller, softer line under it. With [plain]
/// the figure is just the number and "SYP" ("ل.س"), without saying "new".
class PriceTextWidget extends StatelessWidget {
  final num price;
  final TextStyle? style;

  /// Put before the new price, e.g. "~" for an estimate.
  final String prefix;
  final CrossAxisAlignment alignment;

  /// The figure is "300 SYP", not "300 new SYP".
  final bool plain;

  const PriceTextWidget({
    super.key,
    required this.price,
    this.style,
    this.prefix = '',
    this.alignment = CrossAxisAlignment.end,
    this.plain = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final style = this.style ?? DefaultTextStyle.of(context).style;
    final textAlign = switch (alignment) {
      CrossAxisAlignment.start => TextAlign.start,
      CrossAxisAlignment.center => TextAlign.center,
      _ => TextAlign.end,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignment,
      children: [
        Text(
          '$prefix${plain ? formatPlainSyp(l10n, price) : formatNewSyp(l10n, price)}',
          textAlign: textAlign,
          style: style,
        ),
        Text(
          formatOldSyp(l10n, price),
          textAlign: textAlign,
          style: style.copyWith(
            fontSize: (style.fontSize ?? 14) * 0.7,
            fontWeight: FontWeight.w600,
            color: style.color?.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
