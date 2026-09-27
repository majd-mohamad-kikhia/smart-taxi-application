import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../driver_auth/data/models/driver_user_model.dart';
import '../../../driver_auth/presentation/cubit/driver_auth_cubit.dart';
import '../../../driver_auth/presentation/cubit/driver_auth_state.dart';

/// Read-only driver profile — no edit-profile endpoint is documented yet,
/// so this only displays what login already returned.
class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(title: const Text('الملف الشخصي')),
      body: BlocBuilder<DriverAuthCubit, DriverAuthState>(
        bloc: sl<DriverAuthCubit>(),
        builder: (context, state) {
          final driver = state.driver;
          if (driver == null) return const SizedBox.shrink();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [_InfoCard(driver: driver)],
          );
        },
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final DriverUserModel driver;

  const _InfoCard({required this.driver});

  @override
  Widget build(BuildContext context) {
    final vehicle = driver.vehicle;
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
            label: 'الاسم',
            value: driver.fullName,
          ),
          _Row(
            icon: Icons.phone_outlined,
            label: 'رقم الجوال',
            value: driver.phone,
          ),
          if (driver.address != null)
            _Row(
              icon: Icons.location_on_outlined,
              label: 'العنوان',
              value: driver.address!,
            ),
          _Row(
            icon: Icons.star_outline_rounded,
            label: 'التقييم',
            value: driver.rating != null
                ? driver.rating!.toStringAsFixed(1)
                : 'لا يوجد بعد',
          ),
          _Row(
            icon: Icons.account_balance_wallet_outlined,
            label: 'رصيد المحفظة',
            value: '${driver.walletBalance.toStringAsFixed(2)} ل.س',
          ),
          if (vehicle != null) ...[
            const Divider(height: 28),
            Text(
              'بيانات المركبة',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _Row(
              icon: Icons.directions_car_outlined,
              label: 'النوع',
              value: vehicle.vehicleTypeName,
            ),
            _Row(
              icon: Icons.local_taxi_outlined,
              label: 'الموديل',
              value: '${vehicle.brand} ${vehicle.model}',
            ),
            _Row(
              icon: Icons.palette_outlined,
              label: 'اللون',
              value: vehicle.color,
            ),
            _Row(
              icon: Icons.pin_outlined,
              label: 'رقم اللوحة',
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
