import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format_price.dart';
import '../../../../core/widgets/app_neutral_button_widget.dart';
import '../../../../core/widgets/app_snack_bar_widget.dart';
import '../../../../core/widgets/auth_primary_button_widget.dart';
import '../../data/models/ride_booking_options_model.dart';
import '../../data/models/ride_quote_model.dart';
import '../../data/models/vehicle_type_quote_model.dart';
import 'ride_schedule_selector_widget.dart';
import 'vehicle_type_tile_widget.dart';

/// Bottom sheet where the customer compares the quoted price of every vehicle
/// type for their trip, picks one, and then confirms with a single yellow
/// "Request {vehicle} · {price}" button. Choosing a tile only selects it —
/// the ride is not requested until that button is pressed.
///
/// The customer can also leave a note for the driver and pick "Later" to
/// schedule the ride.
///
/// Purely presentational — it pops itself with a [RideBookingOptionsModel],
/// and the caller fires the booking request.
class VehicleTypeSheetWidget extends StatefulWidget {
  final RideQuoteModel quote;
  final String pickupLabel;
  final String dropoffLabel;

  const VehicleTypeSheetWidget({
    super.key,
    required this.quote,
    required this.pickupLabel,
    required this.dropoffLabel,
  });

  @override
  State<VehicleTypeSheetWidget> createState() => _VehicleTypeSheetWidgetState();
}

class _VehicleTypeSheetWidgetState extends State<VehicleTypeSheetWidget> {
  static const _maxNoteLength = 500;

  int? _selectedId;
  DateTime? _scheduledAt;
  final TextEditingController _noteController = TextEditingController();

  /// Guards against a second tap popping the sheet twice.
  bool _isLeaving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  double? _priceOf(VehicleTypeQuoteModel type) =>
      type.displayPrice(widget.quote.distanceKm);

  /// A type can be requested only when it is available and has a price.
  bool _isChoosable(VehicleTypeQuoteModel type) =>
      type.available && _priceOf(type) != null;

  VehicleTypeQuoteModel? get _selected {
    for (final type in widget.quote.vehicleTypes) {
      if (type.vehicleTypeId == _selectedId) return type;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    // With a single choice there is nothing to compare — start selected.
    final choosable = widget.quote.vehicleTypes.where(_isChoosable).toList();
    if (choosable.length == 1) _selectedId = choosable.first.vehicleTypeId;
  }

  void _request(int vehicleTypeId) {
    if (_isLeaving) return;
    final scheduledAt = _scheduledAt;
    if (scheduledAt != null &&
        scheduledAt.isBefore(DateTime.now().add(RideScheduleSelectorWidget.minLead))) {
      // The sheet stayed open long enough for the picked time to get too close.
      setState(() => _scheduledAt = null);
      showAppSnackBar(
        context,
        context.l10n.rideScheduleOutOfRange,
        type: AppSnackBarType.warning,
      );
      return;
    }
    _isLeaving = true;
    final note = _noteController.text.trim();
    Navigator.of(context).pop(
      RideBookingOptionsModel(
        vehicleTypeId: vehicleTypeId,
        note: note.isEmpty ? null : note,
        scheduledAt: scheduledAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final quote = widget.quote;
    final types = quote.vehicleTypes;
    final hasChoice = types.any(_isChoosable);
    final selected = _selected;
    final selectedPrice = selected == null ? null : _priceOf(selected);

    return SafeArea(
      child: Padding(
        // Keeps the note field above the keyboard.
        padding: EdgeInsets.fromLTRB(
          AppConstants.paddingXL,
          AppConstants.paddingXL,
          AppConstants.paddingXL,
          AppConstants.paddingXL + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                ),
              ),
            ),
            const SizedBox(height: AppConstants.paddingXL),
            Semantics(
              header: true,
              child: Text(
                l10n.pickVehicleType,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: AppConstants.paddingM),
            _TripSummary(
              pickupLabel: widget.pickupLabel,
              dropoffLabel: widget.dropoffLabel,
              distanceKm: quote.distanceKm,
              durationMin: quote.estimatedDurationMin,
            ),
            const SizedBox(height: AppConstants.paddingL),
            Flexible(
              child: hasChoice
                  ? ListView(
                      shrinkWrap: true,
                      children: [
                        for (final type in types) ...[
                          VehicleTypeTileWidget(
                            vehicleType: type,
                            price: _priceOf(type),
                            selected: type.vehicleTypeId == _selectedId,
                            onTap: _isChoosable(type)
                                ? () => setState(
                                    () => _selectedId = type.vehicleTypeId,
                                  )
                                : null,
                          ),
                          const SizedBox(height: AppConstants.paddingM),
                        ],
                        const SizedBox(height: AppConstants.paddingS),
                        RideScheduleSelectorWidget(
                          value: _scheduledAt,
                          onChanged: (value) => setState(() => _scheduledAt = value),
                        ),
                        const SizedBox(height: AppConstants.paddingL),
                        _NoteField(
                          controller: _noteController,
                          maxLength: _maxNoteLength,
                        ),
                        const SizedBox(height: AppConstants.paddingS),
                        _FeeRules(quote: quote),
                      ],
                    )
                  : const _NoVehicles(),
            ),
            const SizedBox(height: AppConstants.paddingM),
            if (hasChoice) ...[
              const _EstimateNote(),
              const SizedBox(height: AppConstants.paddingM),
              AuthPrimaryButtonWidget(
                label: selected == null || selectedPrice == null
                    ? l10n.pickVehicleType
                    : (_scheduledAt == null ? l10n.requestVehicle : l10n.scheduleVehicle)(
                        selected.name,
                        formatSyp(l10n, selectedPrice),
                      ),
                isLoading: false,
                onPressed: selected == null
                    ? null
                    : () => _request(selected.vehicleTypeId),
              ),
            ] else
              AppNeutralButtonWidget(
                label: l10n.close,
                onPressed: () => Navigator.of(context).pop(),
              ),
          ],
        ),
      ),
    );
  }
}

/// The trip these prices are for — pickup, drop-off, distance and time — so
/// the customer never compares prices for a trip they can no longer see.
class _TripSummary extends StatelessWidget {
  final String pickupLabel;
  final String dropoffLabel;
  final double distanceKm;
  final int durationMin;

  const _TripSummary({
    required this.pickupLabel,
    required this.dropoffLabel,
    required this.distanceKm,
    required this.durationMin,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AddressRow(
          icon: Icons.trip_origin_rounded,
          color: AppColors.primary,
          label: pickupLabel,
        ),
        const SizedBox(height: AppConstants.paddingS),
        _AddressRow(
          icon: Icons.location_on_rounded,
          color: AppColors.accent,
          label: dropoffLabel,
        ),
        if (distanceKm > 0 || durationMin > 0) ...[
          const SizedBox(height: AppConstants.paddingS),
          Text(
            [
              if (distanceKm > 0)
                l10n.distanceKm(distanceKm.toStringAsFixed(1)),
              if (durationMin > 0) l10n.durationMinutesShort('$durationMin'),
            ].join(' · '),
            style: textTheme.bodyMedium?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ],
    );
  }
}

class _AddressRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _AddressRow({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppConstants.paddingS),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}

/// The waiting and stop fee rules, folded away until the customer wants them.
class _FeeRules extends StatelessWidget {
  final RideQuoteModel quote;

  const _FeeRules({required this.quote});

  @override
  Widget build(BuildContext context) {
    final waiting = quote.waitingFee;
    final pause = quote.pauseFee;
    final hasWaiting = waiting?.isCharged ?? false;
    final hasPause = pause?.isCharged ?? false;
    if (!hasWaiting && !hasPause) return const SizedBox.shrink();

    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: AppColors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        shape: const Border(),
        collapsedShape: const Border(),
        iconColor: AppColors.textSecondary,
        collapsedIconColor: AppColors.textSecondary,
        title: Text(l10n.fareDetails, style: textTheme.titleSmall),
        children: [
          if (hasWaiting)
            Padding(
              padding: const EdgeInsets.only(bottom: AppConstants.paddingS),
              child: Text(
                '${l10n.waitingAtPickup}: ${l10n.waitingRules(
                  '${waiting!.freeMinutes}',
                  formatSyp(l10n, waiting.pricePerMinute),
                )}',
                style: textTheme.bodyMedium,
              ),
            ),
          if (hasPause)
            Padding(
              padding: const EdgeInsets.only(bottom: AppConstants.paddingS),
              child: Text(
                '${l10n.pauseStopLabel}: ${l10n.pauseRules(
                  formatSyp(l10n, pause!.baseFee),
                  '${pause.includedMinutes}',
                  formatSyp(l10n, pause.pricePerMinute),
                )}',
                style: textTheme.bodyMedium,
              ),
            ),
        ],
      ),
    );
  }
}

/// Optional note for the driver ("I have two suitcases").
class _NoteField extends StatelessWidget {
  final TextEditingController controller;
  final int maxLength;

  const _NoteField({required this.controller, required this.maxLength});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      minLines: 1,
      maxLines: 3,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: context.l10n.rideNoteLabel,
        hintText: context.l10n.rideNoteHint,
        prefixIcon: const Icon(Icons.sticky_note_2_outlined),
      ),
    );
  }
}

/// "The price is an estimate…" next to the button that commits to it.
class _EstimateNote extends StatelessWidget {
  const _EstimateNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.info_outline_rounded,
          size: 16,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: AppConstants.paddingS),
        Expanded(
          child: Text(
            context.l10n.priceEstimateNote,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _NoVehicles extends StatelessWidget {
  const _NoVehicles();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingXL),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_taxi_outlined,
            size: 40,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppConstants.paddingM),
          Text(
            context.l10n.noVehiclesAvailable,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
