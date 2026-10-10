import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format_price.dart';
import '../../../../core/widgets/app_brand_bar_widget.dart';
import '../../../driver_auth/data/models/driver_user_model.dart';
import '../../../driver_auth/presentation/cubit/driver_auth_cubit.dart';
import '../../../driver_auth/presentation/cubit/driver_auth_state.dart';
import '../cubit/driver_vehicle_cubit.dart';
import '../cubit/driver_vehicle_state.dart';
import '../widgets/driver_vehicle_card_widget.dart';
import '../widgets/profile_figure_tile_widget.dart';
import '../widgets/profile_header_widget.dart';
import '../widgets/profile_info_row_widget.dart';

/// Read-only driver profile — no edit-profile endpoint is documented yet,
/// so the driver's own info only displays what login already returned.
/// The vehicle card is fetched live from `GET /api/driver/vehicle` so it
/// stays current even if the vehicle changes after login.
///
/// Reads as a headline first (who, and whether the account can take trips),
/// then the two figures a driver checks (rating, wallet balance), then the
/// contact details and the vehicle.
class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  late final DriverVehicleCubit _vehicleCubit;

  @override
  void initState() {
    super.initState();
    _vehicleCubit = sl<DriverVehicleCubit>()..load();
  }

  @override
  void dispose() {
    _vehicleCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: AppBrandBarWidget(),
      ),
      body: BlocBuilder<DriverAuthCubit, DriverAuthState>(
        bloc: sl<DriverAuthCubit>(),
        builder: (context, state) {
          final driver = state.driver;
          if (driver == null) return const SizedBox.shrink();
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.all(AppConstants.paddingL),
                children: [
                  ProfileHeaderWidget(driver: driver),
                  const SizedBox(height: AppConstants.paddingM),
                  _Figures(driver: driver),
                  const SizedBox(height: AppConstants.paddingM),
                  _Contact(driver: driver),
                  const SizedBox(height: AppConstants.paddingM),
                  BlocBuilder<DriverVehicleCubit, DriverVehicleState>(
                    bloc: _vehicleCubit,
                    builder: (context, vehicleState) => DriverVehicleCardWidget(
                      state: vehicleState,
                      onRetry: _vehicleCubit.load,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The two figures a driver checks here: the rating (opens "My ratings") and
/// the wallet balance.
class _Figures extends StatelessWidget {
  final DriverUserModel driver;

  const _Figures({required this.driver});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rating = driver.rating;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ProfileFigureTileWidget(
              icon: Icons.star_rounded,
              iconColor: AppColors.accent,
              label: l10n.profileRating,
              value: rating == null ? '—' : rating.toStringAsFixed(2),
              onTap: () => Navigator.of(context).pushNamed(AppRouter.driverRatings),
            ),
          ),
          const SizedBox(width: AppConstants.paddingM),
          Expanded(
            child: ProfileFigureTileWidget(
              icon: Icons.account_balance_wallet_outlined,
              iconColor: AppColors.primary,
              label: l10n.profileWalletBalance,
              value: formatSignedPrice(l10n, driver.walletBalance),
            ),
          ),
        ],
      ),
    );
  }
}

/// Phone and address.
class _Contact extends StatelessWidget {
  final DriverUserModel driver;

  const _Contact({required this.driver});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingL,
        vertical: AppConstants.paddingS,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          ProfileInfoRowWidget(
            icon: Icons.phone_outlined,
            label: l10n.phoneNumber,
            value: driver.phone,
            isLtrValue: true,
          ),
          if (driver.address != null)
            ProfileInfoRowWidget(
              icon: Icons.location_on_outlined,
              label: l10n.address,
              value: driver.address!,
            ),
        ],
      ),
    );
  }
}
