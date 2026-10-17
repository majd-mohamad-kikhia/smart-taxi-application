import 'package:flutter/material.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_palette.dart';
import '../../data/models/report_month_model.dart';

/// "October 2026" in the active language.
String walletMonthLabel(AppLocalizations l10n, ReportMonthModel month) {
  final names = [
    l10n.monthJan,
    l10n.monthFeb,
    l10n.monthMar,
    l10n.monthApr,
    l10n.monthMay,
    l10n.monthJun,
    l10n.monthJul,
    l10n.monthAug,
    l10n.monthSep,
    l10n.monthOct,
    l10n.monthNov,
    l10n.monthDec,
  ];
  return '${names[month.month - 1]} ${month.year}';
}

/// Previous / next month around the month's name. The month announces
/// itself to screen readers when it changes. Never steps before the first
/// month the server has or after the current one.
class WalletMonthStepperWidget extends StatelessWidget {
  final ReportMonthModel month;
  final ValueChanged<ReportMonthModel> onChanged;

  const WalletMonthStepperWidget({
    super.key,
    required this.month,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Start side = previous month, end side = next month. These icons
        // mirror themselves in RTL, so the arrows point the right way in
        // both languages.
        IconButton(
          tooltip: l10n.walletPreviousMonth,
          icon: const Icon(Icons.chevron_left_rounded),
          color: context.colors.textSecondary,
          onPressed: month.canGoBack
              ? () => onChanged(month.shifted(-1))
              : null,
        ),
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 140),
            child: Semantics(
              header: true,
              liveRegion: true,
              child: Text(
                walletMonthLabel(l10n, month),
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: l10n.walletNextMonth,
          icon: const Icon(Icons.chevron_right_rounded),
          color: context.colors.textSecondary,
          onPressed: month.canGoForward
              ? () => onChanged(month.shifted(1))
              : null,
        ),
      ],
    );
  }
}
