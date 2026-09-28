import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_destructive_button_widget.dart';
import '../../../../core/widgets/auth_error_banner_widget.dart';
import '../../../../core/widgets/auth_primary_button_widget.dart';
import '../../data/models/picked_location_model.dart';
import '../../data/models/ride_quote_model.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../widgets/active_ride_card_widget.dart';
import '../widgets/home_app_bar_widget.dart';
import '../widgets/location_select_button_widget.dart';
import '../widgets/vehicle_type_sheet_widget.dart';
import 'location_picker_screen.dart';

/// Entry point for the "إنشاء طلب" (create request) feature.
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
        child: HomeAppBarWidget(),
      ),
      body: BlocConsumer<HomeCubit, HomeState>(
        // A fresh quote is the signal to let the customer pick a vehicle.
        listenWhen: (previous, current) =>
            previous.quote != current.quote && current.quote != null,
        listener: (context, state) => _openVehicleSheet(context, state.quote!),
        builder: (context, state) => _HomeBody(state: state),
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
}

class _HomeBody extends StatelessWidget {
  final HomeState state;

  const _HomeBody({required this.state});

  @override
  Widget build(BuildContext context) {
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
                    // ── Welcome message ───────────────────────────
                    Text(
                      '${state.greeting}${state.userName.isNotEmpty ? '، ${state.userName}' : ''} 👋',
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
                          ? 'طلبك قيد التنفيذ الآن'
                          : 'إلى أين تريد الذهاب اليوم؟',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // ── From / To pick cards ──────────────────────
                    LocationSelectButtonWidget(
                      label: 'من',
                      icon: Icons.trip_origin_rounded,
                      accentColor: AppColors.primary,
                      value: state.fromLocation,
                      placeholder: 'اختر نقطة الانطلاق',
                      onTap: hasActiveRide
                          ? null
                          : () => _pickLocation(
                              context,
                              title: 'اختر نقطة الانطلاق',
                              initial: state.fromLocation,
                              onPicked: context
                                  .read<HomeCubit>()
                                  .setFromLocation,
                            ),
                    ),
                    const SizedBox(height: 14),
                    LocationSelectButtonWidget(
                      label: 'إلى',
                      icon: Icons.location_on_rounded,
                      accentColor: AppColors.accent,
                      value: state.toLocation,
                      placeholder: 'اختر وجهتك',
                      onTap: hasActiveRide
                          ? null
                          : () => _pickLocation(
                              context,
                              title: 'اختر وجهتك',
                              initial: state.toLocation,
                              onPicked: context.read<HomeCubit>().setToLocation,
                            ),
                    ),
                    // ── Active ride summary ────────────────────────
                    if (state.activeRide != null) ...[
                      const SizedBox(height: AppConstants.paddingXL),
                      ActiveRideCardWidget(ride: state.activeRide!),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppConstants.paddingL),
            // ── Error banner ───────────────────────────────
            if (state.errorMessage != null) ...[
              AuthErrorBannerWidget(message: state.errorMessage!),
              const SizedBox(height: AppConstants.paddingM),
            ],
            // ── Primary action ─────────────────────────────
            if (hasActiveRide)
              AppDestructiveButtonWidget(
                label: 'إلغاء الطلب',
                isLoading: state.isCancelling,
                onPressed: () => context.read<HomeCubit>().cancelRide(),
              )
            else
              AuthPrimaryButtonWidget(
                label: 'بحث',
                isLoading: state.isSearching || state.isBooking,
                onPressed: state.canSearch
                    ? () => context.read<HomeCubit>().searchRide()
                    : null,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickLocation(
    BuildContext context, {
    required String title,
    required PickedLocationModel? initial,
    required void Function(PickedLocationModel) onPicked,
  }) async {
    final result = await Navigator.of(context).push<PickedLocationModel>(
      MaterialPageRoute(
        builder: (_) =>
            LocationPickerScreen(title: title, initialLocation: initial),
      ),
    );
    if (result != null) onPicked(result);
  }
}
