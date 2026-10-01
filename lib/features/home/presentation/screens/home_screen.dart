import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/models/picked_location_model.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/account_block_gate_widget.dart';
import '../../../../core/widgets/app_brand_bar_widget.dart';
import '../../../../core/widgets/app_destructive_button_widget.dart';
import '../../../../core/widgets/auth_error_banner_widget.dart';
import '../../../../core/widgets/auth_primary_button_widget.dart';
import '../../data/models/ride_quote_model.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../widgets/active_ride_card_widget.dart';
import '../widgets/location_select_button_widget.dart';
import '../widgets/vehicle_type_sheet_widget.dart';
import 'location_picker_screen.dart';

/// Entry point for the "create request" feature.
/// Provides the [HomeCubit] and renders [_HomeView].
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeCubit>(
      create: (_) => sl<HomeCubit>()..initialize(),
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
            listener: (context, state) => _openVehicleSheet(context, state.quote!),
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

  Future<void> _openVehicleSheet(
    BuildContext context,
    RideQuoteModel quote,
  ) async {
    final cubit = context.read<HomeCubit>();
    final vehicleTypeId = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.neutralSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusXL),
        ),
      ),
      builder: (_) => VehicleTypeSheetWidget(quote: quote),
    );
    if (vehicleTypeId != null) await cubit.chooseVehicle(vehicleTypeId);
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
                      onTap: hasActiveRide
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
                    const SizedBox(height: 14),
                    LocationSelectButtonWidget(
                      label: l10n.toLabel,
                      icon: Icons.location_on_rounded,
                      accentColor: AppColors.accent,
                      value: state.toLocation,
                      placeholder: l10n.pickDestination,
                      onTap: hasActiveRide
                          ? null
                          : () => _pickLocation(
                              context,
                              title: l10n.pickDestination,
                              isPickup: false,
                              initial: state.toLocation,
                              onPicked: context.read<HomeCubit>().setToLocation,
                            ),
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
                onPressed: () => context.read<HomeCubit>().cancelRide(),
              )
            else
              // A block only stops new orders — a ride in progress (the
              // cancel button above) is unaffected.
              AccountBlockGateWidget(
                blockedMessage: l10n.accountBlockedRiderMessage,
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
