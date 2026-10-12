import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/format_price.dart';
import '../../../../core/widgets/app_neutral_button_widget.dart';
import '../../../../core/widgets/entrance_animation_widget.dart';
import '../../data/models/ride_booking_options_model.dart';
import '../../data/models/ride_quote_model.dart';
import '../../data/models/vehicle_type_quote_model.dart';
import 'vehicle_request_button_widget.dart';
import 'vehicle_type_tile_widget.dart';

/// Bottom sheet where the customer compares the quoted price of every vehicle
/// type for their trip, picks one, and then confirms with a single
/// "Request {vehicle} · {price}" button. Choosing a card only selects it —
/// the ride is not requested until that button is pressed.
///
/// The customer can also leave a note for the driver.
///
/// Purely presentational — it pops itself with a [RideBookingOptionsModel],
/// and the caller fires the booking request. The choice lives in a
/// [ValueNotifier], so picking a card repaints only the cards and the button,
/// never the header, the trip card or the note field.
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

  final ValueNotifier<int?> _selectedId = ValueNotifier<int?>(null);
  final TextEditingController _noteController = TextEditingController();

  /// Guards against a second tap popping the sheet twice.
  bool _isLeaving = false;

  /// A type can be requested only when it is available and has a price.
  static bool _isChoosable(VehicleTypeQuoteModel type) =>
      type.available && type.price != null;

  @override
  void initState() {
    super.initState();
    // With a single choice there is nothing to compare — start selected.
    final choosable = widget.quote.vehicleTypes.where(_isChoosable).toList();
    if (choosable.length == 1) {
      _selectedId.value = choosable.first.vehicleTypeId;
    }
  }

  @override
  void dispose() {
    _selectedId.dispose();
    _noteController.dispose();
    super.dispose();
  }

  VehicleTypeQuoteModel? _selected(int? id) {
    for (final type in widget.quote.vehicleTypes) {
      if (type.vehicleTypeId == id) return type;
    }
    return null;
  }

  void _request(int vehicleTypeId) {
    if (_isLeaving) return;
    _isLeaving = true;
    final note = _noteController.text.trim();
    Navigator.of(context).pop(
      RideBookingOptionsModel(
        vehicleTypeId: vehicleTypeId,
        note: note.isEmpty ? null : note,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final quote = widget.quote;
    final types = quote.vehicleTypes;
    final hasChoice = types.any(_isChoosable);

    return SafeArea(
      child: Padding(
        // Keeps the note field above the keyboard.
        padding: EdgeInsets.fromLTRB(
          AppConstants.paddingL,
          AppConstants.paddingM,
          AppConstants.paddingL,
          AppConstants.paddingL + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _DragHandle(),
            const SizedBox(height: AppConstants.paddingL),
            _Header(
              distanceKm: quote.distanceKm,
              durationMin: quote.estimatedDurationMin,
            ),
            const SizedBox(height: AppConstants.paddingM),
            _TripCard(
              pickupLabel: widget.pickupLabel,
              dropoffLabel: widget.dropoffLabel,
            ),
            const SizedBox(height: AppConstants.paddingM),
            Flexible(
              child: hasChoice
                  ? ListView(
                      shrinkWrap: true,
                      children: [
                        ValueListenableBuilder<int?>(
                          valueListenable: _selectedId,
                          builder: (context, selectedId, _) => Column(
                            children: [
                              for (var i = 0; i < types.length; i++)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppConstants.paddingM,
                                  ),
                                  child: EntranceAnimationWidget(
                                    index: i,
                                    child: VehicleTypeTileWidget(
                                      vehicleType: types[i],
                                      locationFeeName: quote.locationFeeName,
                                      price: types[i].price,
                                      selected:
                                          types[i].vehicleTypeId == selectedId,
                                      onTap: _isChoosable(types[i])
                                          ? () => _selectedId.value =
                                                types[i].vehicleTypeId
                                          : null,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        _NoteField(
                          controller: _noteController,
                          maxLength: _maxNoteLength,
                        ),
                      ],
                    )
                  : const _NoVehicles(),
            ),
            const SizedBox(height: AppConstants.paddingM),
            if (hasChoice) ...[
              const _EstimateNote(),
              const SizedBox(height: AppConstants.paddingM),
              ValueListenableBuilder<int?>(
                valueListenable: _selectedId,
                builder: (context, selectedId, _) {
                  final selected = _selected(selectedId);
                  final price = selected?.price;
                  return VehicleRequestButtonWidget(
                    label: selected == null || price == null
                        ? l10n.pickVehicleType
                        : l10n.requestVehicle(
                            selected.name,
                            formatSyp(l10n, price),
                          ),
                    onPressed: selected == null
                        ? null
                        : () => _request(selected.vehicleTypeId),
                  );
                },
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

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44,
        height: 5,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        ),
      ),
    );
  }
}

/// The title, and the trip's distance and time in a green pill beside it.
class _Header extends StatelessWidget {
  final double distanceKm;
  final int durationMin;

  const _Header({required this.distanceKm, required this.durationMin});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final summary = [
      if (distanceKm > 0) l10n.distanceKm(distanceKm.toStringAsFixed(1)),
      if (durationMin > 0) l10n.durationMinutesShort('$durationMin'),
    ].join(' · ');
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              l10n.pickVehicleType,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ),
        if (summary.isNotEmpty) ...[
          const SizedBox(width: AppConstants.paddingM),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.primarySurface,
              borderRadius: BorderRadius.circular(AppConstants.radiusFull),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.route_rounded,
                    size: 16,
                    color: colors.primaryContent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    summary,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colors.primaryContent,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// The trip these prices are for — pickup and drop-off, joined by a dotted
/// line — so the customer never compares prices for a trip they can no longer
/// see.
class _TripCard extends StatelessWidget {
  final String pickupLabel;
  final String dropoffLabel;

  const _TripCard({required this.pickupLabel, required this.dropoffLabel});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.backgroundMuted,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          children: [
            _AddressRow(
              icon: Icons.trip_origin_rounded,
              color: AppColors.primaryBright,
              label: pickupLabel,
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 8),
              child: SizedBox(
                height: 14,
                child: VerticalDivider(
                  width: 1,
                  thickness: 1.5,
                  color: colors.borderStrong,
                ),
              ),
            ),
            _AddressRow(
              icon: Icons.location_on_rounded,
              color: AppColors.accent,
              label: dropoffLabel,
            ),
          ],
        ),
      ),
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
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
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

/// "The price is an estimate…", next to the button that commits to it: a
/// tinted notice with an icon and readable text, so the customer sees it
/// before they request.
class _EstimateNote extends StatelessWidget {
  const _EstimateNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingM,
        vertical: AppConstants.paddingM,
      ),
      decoration: BoxDecoration(
        color: context.colors.warningSurface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.info_rounded, size: 22, color: AppColors.warning),
          const SizedBox(width: AppConstants.paddingM),
          Expanded(
            child: Text(
              context.l10n.priceEstimateNote,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
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
          Icon(
            Icons.local_taxi_outlined,
            size: 40,
            color: context.colors.textSecondary,
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
