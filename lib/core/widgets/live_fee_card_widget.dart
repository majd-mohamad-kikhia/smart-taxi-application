import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../l10n/generated/app_localizations.dart';
import '../localization/l10n_context_extension.dart';
import '../theme/app_colors.dart';

/// The card shared by the live fee timers (waiting at pickup, trip pause):
/// a title with the elapsed mm:ss clock, the fee so far as the large
/// figure, a status line (free time left / over) and an optional rules
/// line. Presentational only — see `RideWaitingTimerWidget` and
/// `RidePauseTimerWidget` for where the numbers come from.
///
/// State is never color alone: [accent] tints the card, and the caller also
/// swaps [icon] and the [statusText] between states.
///
/// Screen readers get one spoken summary ([semanticsLabel], with durations
/// in words) instead of a ticking clock. The card speaks up only when
/// [phaseKey] changes (free time ending, a new billable minute) with
/// [phaseAnnouncement], and once when it first appears if [announceOnShow].
class LiveFeeCardWidget extends StatefulWidget {
  final IconData icon;
  final String title;
  final int elapsedSeconds;
  final Color accent;
  final String semanticsLabel;
  final String? statusText;
  final String? rulesText;
  final String? feeText;

  /// Changes whenever the card should speak up; compared between rebuilds.
  final Object? phaseKey;

  /// What to say when [phaseKey] changes. Nothing is said when null.
  final String? phaseAnnouncement;

  /// Say [semanticsLabel] once when the card first appears.
  final bool announceOnShow;

  const LiveFeeCardWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.elapsedSeconds,
    required this.accent,
    required this.semanticsLabel,
    this.statusText,
    this.rulesText,
    this.feeText,
    this.phaseKey,
    this.phaseAnnouncement,
    this.announceOnShow = false,
  });

  /// mm:ss for a number of seconds.
  static String clock(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// A duration in words ("4 minutes 37 seconds") for [semanticsLabel].
  static String spoken(AppLocalizations l10n, int totalSeconds) =>
      l10n.spokenMinutesSeconds(totalSeconds ~/ 60, totalSeconds % 60);

  @override
  State<LiveFeeCardWidget> createState() => _LiveFeeCardWidgetState();
}

class _LiveFeeCardWidgetState extends State<LiveFeeCardWidget> {
  static const _tabularFigures = [FontFeature.tabularFigures()];

  /// The text of the card's live region. It only changes at a phase change,
  /// so a screen reader hears it then and not every second.
  late String _liveMessage =
      widget.announceOnShow ? widget.semanticsLabel : '';

  @override
  void didUpdateWidget(covariant LiveFeeCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phaseKey != widget.phaseKey) {
      _liveMessage = widget.phaseAnnouncement ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasFee = widget.feeText != null;

    return Stack(
      children: [
        Semantics(
          container: true,
          label: widget.semanticsLabel,
          excludeSemantics: true,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingL,
              vertical: AppConstants.paddingM,
            ),
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                widget.accent.withValues(alpha: 0.08),
                AppColors.backgroundWhite,
              ),
              borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
              border: Border.all(color: widget.accent.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(widget.icon, color: widget.accent, size: 24),
                    const SizedBox(width: AppConstants.paddingS),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: textTheme.titleSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      LiveFeeCardWidget.clock(widget.elapsedSeconds),
                      textDirection: TextDirection.ltr,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontFeatures: _tabularFigures,
                      ),
                    ),
                  ],
                ),
                if (hasFee) ...[
                  const SizedBox(height: AppConstants.paddingM),
                  Text(
                    context.l10n.liveFeeSoFar,
                    style: textTheme.labelMedium,
                  ),
                  // A very large amount shrinks to fit instead of squeezing
                  // the rest of the card.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      widget.feeText!,
                      style: textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontFeatures: _tabularFigures,
                      ),
                    ),
                  ),
                ],
                if (widget.statusText != null) ...[
                  const SizedBox(height: AppConstants.paddingS),
                  Text(
                    widget.statusText!,
                    style: (hasFee ? textTheme.bodyMedium : textTheme.titleMedium)
                        ?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontFeatures: _tabularFigures,
                    ),
                  ),
                ],
                if (widget.rulesText != null) ...[
                  const SizedBox(height: AppConstants.paddingXS),
                  Text(
                    widget.rulesText!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_liveMessage.isNotEmpty)
          PositionedDirectional(
            start: 0,
            top: 0,
            child: Semantics(
              liveRegion: true,
              label: _liveMessage,
              child: const SizedBox(width: 1, height: 1),
            ),
          ),
      ],
    );
  }
}
