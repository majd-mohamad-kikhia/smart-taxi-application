import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/paginated_list_widget.dart';
import '../../../home/presentation/widgets/home_app_bar_widget.dart';
import '../../data/models/ride_history_model.dart';
import '../cubit/trips_cubit.dart';
import '../cubit/trips_state.dart';
import '../widgets/trip_card_widget.dart';
import '../widgets/trips_status_filter_widget.dart';

/// "My rides" tab: a plain paginated list of the customer's rides.
class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TripsCubit>(
      create: (_) => sl<TripsCubit>()..initialize(),
      child: const _TripsView(),
    );
  }
}

class _TripsView extends StatelessWidget {
  const _TripsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: HomeAppBarWidget(),
      ),
      body: BlocBuilder<TripsCubit, TripsState>(
        builder: (context, state) {
          final cubit = context.read<TripsCubit>();
          final list = PaginatedListWidget<RideHistoryModel>(
            items: state.rides,
            isLoading: state.isLoading,
            isLoadingMore: state.isLoadingMore,
            hasMore: state.hasMore,
            errorMessage: state.errorMessage,
            emptyMessage: context.l10n.noRidesYet,
            emptyIcon: Icons.local_taxi_outlined,
            onLoadMore: cubit.loadMore,
            onRetry: cubit.refresh,
            onRefresh: cubit.refresh,
            itemBuilder: (context, ride, _) => TripCardWidget(
              ride: ride,
              showStatus: state.selectedStatus == null,
              onTap: () => Navigator.of(context).pushNamed(
                AppRouter.rideDetails,
                arguments: ride.id,
              ),
            ),
          );
          return Column(
            children: [
              TripsStatusFilterWidget(
                selected: state.selectedStatus,
                onSelected: cubit.selectStatus,
              ),
              Expanded(child: list),
            ],
          );
        },
      ),
    );
  }
}
