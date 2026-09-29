import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_brand_bar_widget.dart';
import '../../../../core/widgets/app_loader_widget.dart';
import '../../../../core/widgets/network_photo_widget.dart';
import '../../../driver_auth/data/models/driver_user_model.dart';
import '../../../driver_auth/presentation/cubit/driver_auth_cubit.dart';
import '../../../driver_auth/presentation/cubit/driver_auth_state.dart';
import '../cubit/driver_vehicle_cubit.dart';
import '../cubit/driver_vehicle_state.dart';

/// Read-only driver profile — no edit-profile endpoint is documented yet,
/// so the driver's own info only displays what login already returned.
/// The vehicle card is fetched live from `GET /api/driver/vehicle` so it
/// stays current even if the vehicle changes after login.
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
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              BlocBuilder<DriverVehicleCubit, DriverVehicleState>(
                bloc: _vehicleCubit,
                builder: (context, vehicleState) =>
                    _InfoCard(driver: driver, vehicleState: vehicleState),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final DriverUserModel driver;
  final DriverVehicleState vehicleState;

  const _InfoCard({required this.driver, required this.vehicleState});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final vehicle = vehicleState.vehicle;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Row(
            icon: Icons.person_outline,
            label: l10n.profileName,
            value: driver.fullName,
          ),
          _Row(
            icon: Icons.phone_outlined,
            label: l10n.phoneNumber,
            value: driver.phone,
          ),
          if (driver.address != null)
            _Row(
              icon: Icons.location_on_outlined,
              label: l10n.address,
              value: driver.address!,
            ),
          _Row(
            icon: Icons.star_outline_rounded,
            label: l10n.profileRating,
            value: driver.rating != null
                ? driver.rating!.toStringAsFixed(1)
                : l10n.profileNoRatingYet,
          ),
          _Row(
            icon: Icons.account_balance_wallet_outlined,
            label: l10n.profileWalletBalance,
            value: l10n.priceSyp(driver.walletBalance.toStringAsFixed(2)),
          ),
          if (vehicleState.isLoading && vehicle == null) ...[
            const Divider(height: 28),
            const AppLoaderWidget(size: 100),
          ] else if (vehicleState.errorMessage != null && vehicle == null) ...[
            const Divider(height: 28),
            Text(
              vehicleState.errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ] else if (vehicle != null) ...[
            const Divider(height: 28),
            Text(
              l10n.vehicleInfo,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            NetworkPhotoWidget(
              imagePath: vehicle.photoUrl,
              width: double.infinity,
              height: 160,
              placeholderIcon: Icons.directions_car_outlined,
            ),
            const SizedBox(height: 12),
            _Row(
              icon: Icons.directions_car_outlined,
              label: l10n.vehicleType,
              value: vehicle.vehicleTypeName,
            ),
            _Row(
              icon: Icons.local_taxi_outlined,
              label: l10n.vehicleModel,
              value: '${vehicle.brand} ${vehicle.model}',
            ),
            _Row(
              icon: Icons.palette_outlined,
              label: l10n.vehicleColor,
              value: vehicle.color,
            ),
            _Row(
              icon: Icons.pin_outlined,
              label: l10n.vehiclePlate,
              value: vehicle.plateNumber,
            ),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Row({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
