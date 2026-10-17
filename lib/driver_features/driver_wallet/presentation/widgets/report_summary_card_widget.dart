import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_surface_card_widget.dart';
import 'wallet_amount_widget.dart';

/// One line of a [ReportSummaryCardWidget]: a [label] and either a money
/// [amount] (shown in new and old pounds) or plain [text].
class ReportMetric {
  final String label;
  final double? amount;
  final String? text;

  /// The headline figure of the card, drawn larger and in [color].
  final bool emphasized;
  final Color? color;

  const ReportMetric.amount(
    this.label,
    double this.amount, {
    this.emphasized = false,
    this.color,
  }) : text = null;

  const ReportMetric.text(this.label, String this.text)
    : amount = null,
      emphasized = false,
      color = null;
}

/// The month's totals above a report list — the numbers of the wallet card
/// that was opened — one metric per line, label on the start side and the
/// figure on the end side.
class ReportSummaryCardWidget extends StatelessWidget {
  final List<ReportMetric> metrics;

  const ReportSummaryCardWidget({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      child: AppSurfaceCardWidget(
        color: context.colors.primarySurface,
        bordered: false,
        child: Column(
          children: [
            for (var i = 0; i < metrics.length; i++) ...[
              if (i > 0) const SizedBox(height: AppConstants.paddingM),
              _MetricRow(metric: metrics[i], textTheme: textTheme),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final ReportMetric metric;
  final TextTheme textTheme;

  const _MetricRow({required this.metric, required this.textTheme});

  @override
  Widget build(BuildContext context) {
    final amount = metric.amount;
    final figureStyle =
        (metric.emphasized ? textTheme.headlineMedium : textTheme.titleLarge)
            ?.copyWith(color: metric.color ?? context.colors.textPrimary);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            metric.label,
            style: textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: context.colors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: AppConstants.paddingM),
        Flexible(
          child: amount != null
              ? WalletAmountWidget(
                  amount: amount,
                  style: figureStyle,
                  alignment: CrossAxisAlignment.end,
                )
              : Text(
                  metric.text ?? '',
                  textAlign: TextAlign.end,
                  style: figureStyle?.copyWith(fontWeight: FontWeight.w800),
                ),
        ),
      ],
    );
  }
}
