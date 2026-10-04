import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import '../localization/l10n_context_extension.dart';
import 'second_ticker_widget.dart';

/// The time left until [until] (UTC) as `H:MM:SS` — with days in front when
/// longer than a day — passed through [label] and repainted every second.
/// Stops at zero.
class CountdownTextWidget extends StatelessWidget {
  final DateTime until;
  final String Function(String time) label;
  final TextStyle? style;
  final TextAlign? textAlign;

  const CountdownTextWidget({
    super.key,
    required this.until,
    required this.label,
    this.style,
    this.textAlign,
  });

  static String format(AppLocalizations l10n, Duration left) {
    if (left.isNegative) left = Duration.zero;
    String two(int n) => n.toString().padLeft(2, '0');
    final hms =
        '${left.inHours.remainder(24)}:${two(left.inMinutes.remainder(60))}:${two(left.inSeconds.remainder(60))}';
    return left.inDays > 0 ? l10n.countdownWithDays(left.inDays, hms) : hms;
  }

  @override
  Widget build(BuildContext context) {
    return SecondTickerWidget(
      active: until.isAfter(DateTime.now().toUtc()),
      builder: (context) => Text(
        label(format(context.l10n, until.difference(DateTime.now().toUtc()))),
        textAlign: textAlign,
        style: style?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
      ),
    );
  }
}
