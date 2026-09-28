import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_brand_bar_widget.dart';
import '../../../driver_auth/data/models/driver_status.dart';
import '../../../driver_auth/presentation/cubit/driver_auth_cubit.dart';
import '../../../driver_auth/presentation/cubit/driver_auth_state.dart';
import '../widgets/driver_online_toggle_widget.dart';
import '../widgets/driver_status_card_widget.dart';

/// Driver home tab.
///
/// The API has no endpoint yet for a driver to discover/list incoming
/// ride requests (only accept/pickup/start/finish/cancel on a ride ID
/// the driver already has) — so this only shows the driver's own status
/// for now, with an honest placeholder instead of a fake ride feed.
class DriverHomeScreen extends StatelessWidget {
  const DriverHomeScreen({super.key});

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
              DriverStatusCardWidget(driver: driver),
              const SizedBox(height: 12),
              DriverOnlineToggleWidget(enabled: driver.status == DriverStatus.active),
              const SizedBox(height: 20),
              const _RideRequestsPlaceholder(),
            ],
          );
        },
      ),
    );
  }
}

class _RideRequestsPlaceholder extends StatelessWidget {
  const _RideRequestsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_taxi_outlined, size: 40, color: AppColors.textTertiary),
          SizedBox(height: 10),
          Text(
            'طلبات الرحلات قريباً',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
