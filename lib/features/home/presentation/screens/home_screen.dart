import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/models/picked_location_model.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/saved_addresses/data/models/saved_address_model.dart';
import '../../../../core/saved_addresses/presentation/cubit/saved_addresses_cubit.dart';
import '../../../../core/saved_addresses/presentation/cubit/saved_addresses_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/account_block_gate_widget.dart';
import '../../../../core/widgets/app_brand_bar_widget.dart';
import '../../../../core/widgets/app_destructive_button_widget.dart';
import '../../../../core/widgets/auth_error_banner_widget.dart';
import '../../../../core/widgets/auth_primary_button_widget.dart';
import '../../../../core/widgets/cancel_reason_dialog_widget.dart';
import '../../data/models/ride_booking_options_model.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../widgets/active_ride_card_widget.dart';
import '../widgets/saved_address_chips_widget.dart';
import '../../../../core/widgets/location_select_button_widget.dart';
import '../widgets/vehicle_type_sheet_widget.dart';
import 'location_picker_screen.dart';

/// Entry point for the "create request" feature.
/// Provides the [HomeCubit] and renders [_HomeView].
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<HomeCubit>(create: (_) => sl<HomeCubit>()
            ..initialize()
            ..restoreActiveRide(),
        ),
        BlocProvider<SavedAddressesCubit>.value(value: sl<SavedAddressesCubit>()),
      ],
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: AppBrandBarWidget(showNotifications: true),
      ),
      body: MultiBlocListener(
        listeners: [
          // A fresh quote is the signal to let the customer pick a vehicle.
          BlocListener<HomeCubit, HomeState>(
            listenWhen: (previous, current) =>
                previous.quote != current.quote && current.quote != null,
            listener: (context, state) => _openVehicleSheet(context, state),
          ),
          // The ride was just created — hand off to the live tracking
          // screen, which owns everything from here (accept, GPS, status,
          // cancel) until the ride ends.
          BlocListener<HomeCubit, HomeState>(
            listenWhen: (previous, current) =>
                previous.activeRide == null && current.activeRide != null,
            listener: (context, state) => _openTracking(context, state),
          ),
        ],
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) => _HomeBody(state: state),
        ),
      ),
    );
  }

  Future<void> _openVehicleSheet(BuildContext context, HomeState state) async {
    final quote = state.quote;
    if (quote == null) return;
    final cubit = context.read<HomeCubit>();
    final options = await showModalBottomSheet<RideBookingOptionsModel>(
      context: context,
      backgroundColor: AppColors.neutralSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusXL),
        ),
      ),
      builder: (_) => VehicleTypeSheetWidget(
        quote: quote,
        pickupLabel: state.fromLocation?.displayLabel ?? '',
        dropoffLabel: state.toLocation?.displayLabel ?? '',
      ),
    );
    if (options != null) await cubit.chooseVehicle(options);
  }

  Future<void> _openTracking(BuildContext context, HomeState state) async {
    final ride = state.activeRide;
    final pickup = state.fromLocation;
    final dropoff = state.toLocation;
    if (ride == null || pickup == null || dropoff == null) return;

    final cubit = context.read<HomeCubit>();
    await Navigator.of(context).pushNamed(
      AppRouter.rideTracking,
      arguments: RideTrackingRouteArgs(initialRide: ride, pickup: pickup, dropoff: dropoff),
    );
    cubit.resetAfterRideEnded();
  }
}

class _HomeBody extends StatelessWidget {
  final HomeState state;

  const _HomeBody({required this.state});

  String _greetingText(AppLocalizations l10n) {
    final greeting = switch (state.greeting) {
      GreetingPeriod.morning => l10n.greetingMorning,
      GreetingPeriod.afternoon => l10n.greetingAfternoon,
      GreetingPeriod.evening => l10n.greetingEvening,
    };
    return state.userName.isNotEmpty
        ? l10n.greetingWithName(greeting, state.userName)
        : l10n.greetingOnly(greeting);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasActiveRide = state.hasActiveRide;
    // While a quote or booking is in flight, a changed pin would leave the
    // prices (or the ride) for a different trip than the one on screen.
    final isLocked = hasActiveRide || state.isBusy;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingXL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greetingText(l10n),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingS),
                    Text(
                      hasActiveRide
                          ? l10n.homeRequestInProgress
                          : l10n.homeWhereTo,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    LocationSelectButtonWidget(
                      label: l10n.fromLabel,
                      icon: Icons.trip_origin_rounded,
                      accentColor: AppColors.primary,
                      value: state.fromLocation,
                      placeholder: l10n.pickPickupPoint,
                      onTap: isLocked
                          ? null
                          : () => _pickLocation(
                              context,
                              title: l10n.pickPickupPoint,
                              isPickup: true,
                              initial: state.fromLocation,
                              onPicked: context
                                  .read<HomeCubit>()
                                  .setFromLocation,
                            ),
                    ),
                    if (!isLocked)
                      _SavedChips(
                        onSelected: (address) => context
                            .read<HomeCubit>()
                            .setFromLocation(address.toPickedLocation()),
                      ),
                    const SizedBox(height: 14),
                    LocationSelectButtonWidget(
                      label: l10n.toLabel,
                      icon: Icons.location_on_rounded,
                      accentColor: AppColors.accent,
                      value: state.toLocation,
                      placeholder: l10n.pickDestination,
                      onTap: isLocked
                          ? null
                          : () => _pickLocation(
                              context,
                              title: l10n.pickDestination,
                              isPickup: false,
                              initial: state.toLocation,
                              onPicked: context.read<HomeCubit>().setToLocation,
                            ),
                    ),
                    if (!isLocked)
                      _SavedChips(
                        onSelected: (address) => context
                            .read<HomeCubit>()
                            .setToLocation(address.toPickedLocation()),
                      ),
                    if (state.activeRide != null) ...[
                      const SizedBox(height: AppConstants.paddingXL),
                      ActiveRideCardWidget(ride: state.activeRide!),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppConstants.paddingL),
            if (state.errorMessage != null) ...[
              AuthErrorBannerWidget(message: state.errorMessage!),
              const SizedBox(height: AppConstants.paddingM),
            ],
            if (hasActiveRide)
              AppDestructiveButtonWidget(
                label: l10n.cancelRequest,
                isLoading: state.isCancelling,
                onPressed: () => _confirmCancel(context),
              )
            else
              // A block only stops new orders — a ride in progress (the
              // cancel button above) is unaffected.
              AccountBlockGateWidget(
                blockedMessage: l10n.accountBlockedCustomerMessage,
                child: AuthPrimaryButtonWidget(
                  label: l10n.search,
                  isLoading: state.isSearching || state.isBooking,
                  onPressed: state.canSearch
                      ? () => context.read<HomeCubit>().searchRide()
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Asks for a reason first, like the tracking screen, so a request can't
  /// be cancelled by one stray tap.
  Future<void> _confirmCancel(BuildContext context) async {
    final cubit = context.read<HomeCubit>();
    final reason = await showDialog<String>(
      context: context,
      builder: (_) =>
          CancelReasonDialogWidget(
            title: context.l10n.cancelRequest,
            showCancelLimit: false,
          ),
    );
    if (reason != null) cubit.cancelRide(reason: reason);
  }

  Future<void> _pickLocation(
    BuildContext context, {
    required String title,
    required bool isPickup,
    required PickedLocationModel? initial,
    required void Function(PickedLocationModel) onPicked,
  }) async {
    final result = await Navigator.of(context).push<PickedLocationModel>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          title: title,
          isPickup: isPickup,
          initialLocation: initial,
        ),
      ),
    );
    if (result != null) onPicked(result);
  }
}

/// Saved places as quick picks; rebuilds only when the list changes.
class _SavedChips extends StatelessWidget {
  final ValueChanged<SavedAddressModel> onSelected;

  const _SavedChips({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<SavedAddressesCubit, SavedAddressesState, List<SavedAddressModel>>(
      selector: (state) => state.addresses,
      builder: (context, addresses) => SavedAddressChipsWidget(
        addresses: addresses,
        onSelected: onSelected,
      ),
    );
  }
}
