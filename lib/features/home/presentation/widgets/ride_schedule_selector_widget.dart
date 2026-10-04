import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format_date.dart';
import '../../../../core/widgets/app_choice_chip_widget.dart';
import '../../../../core/widgets/app_snack_bar_widget.dart';

/// "Now" or "Later" for the ride being booked. "Later" opens a date then a
/// time picker limited to what the server accepts: from 30 minutes to
/// 7 days ahead. [value] is the chosen local time, null for now.
class RideScheduleSelectorWidget extends StatelessWidget {
  /// A minute of slack on both ends, so a time picked at the edge is still
  /// valid when the request reaches the server.
  static const Duration minLead = Duration(minutes: 31);
  static const Duration maxLead = Duration(days: 7, minutes: -1);

  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  const RideScheduleSelectorWidget({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final scheduled = value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.rideWhenLabel, style: textTheme.titleSmall),
        const SizedBox(height: AppConstants.paddingS),
        Wrap(
          spacing: AppConstants.paddingS,
          children: [
            AppChoiceChipWidget(
              label: l10n.rideWhenNow,
              selected: scheduled == null,
              onSelected: (_) => onChanged(null),
            ),
            AppChoiceChipWidget(
              label: l10n.rideWhenLater,
              selected: scheduled != null,
              onSelected: (_) => _pick(context),
            ),
          ],
        ),
        if (scheduled != null)
          Row(
            children: [
              const Icon(Icons.event_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: AppConstants.paddingS),
              Expanded(
                child: Text(
                  formatDateTimeValue(context, scheduled),
                  style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(
                onPressed: () => _pick(context),
                child: Text(l10n.rideWhenChange),
              ),
            ],
          ),
      ],
    );
  }

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final earliest = now.add(minLead);
    final latest = now.add(maxLead);
    final current = value;
    final initial = current != null && current.isAfter(earliest) && current.isBefore(latest)
        ? current
        : earliest;

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(earliest.year, earliest.month, earliest.day),
      lastDate: latest,
    );
    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !context.mounted) return;

    final picked = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    final checkNow = DateTime.now();
    if (picked.isBefore(checkNow.add(minLead)) || picked.isAfter(checkNow.add(maxLead))) {
      showAppSnackBar(
        context,
        context.l10n.rideScheduleOutOfRange,
        type: AppSnackBarType.warning,
      );
      return;
    }
    onChanged(picked);
  }
}
