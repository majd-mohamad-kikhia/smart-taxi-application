import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_bottom_nav_widget.dart';
import '../../../../core/widgets/app_nav_helper.dart';
import '../../../home/presentation/widgets/home_app_bar_widget.dart';
import '../cubit/trips_cubit.dart';
import '../cubit/trips_state.dart';
import '../../data/models/trip_history_model.dart';
import '../widgets/trip_card_widget.dart';
import '../widgets/trips_filters_widget.dart';
import '../widgets/trips_header_widget.dart';

/// My Trips / Order History screen with filters and date-grouped cards.
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
          final groups = state.filteredGroups;

          return Column(
            children: [
              TripsHeaderWidget(
                selectedTab: state.selectedTab,
                pastCount: state.pastCount,
                scheduledCount: state.scheduledCount,
                onTabChanged: (tab) =>
                    context.read<TripsCubit>().selectTab(tab),
              ),
              const SizedBox(height: 14),
              TripsFiltersWidget(
                selectedFilter: state.selectedFilter,
                filterCounts: state.filterCounts,
                onSearchChanged: (q) =>
                    context.read<TripsCubit>().updateSearch(q),
                onFilterChanged: (f) =>
                    context.read<TripsCubit>().selectFilter(f),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: state.selectedTab == TripsTab.scheduled
                    ? const _EmptyScheduled()
                    : groups.isEmpty
                        ? const _EmptyFiltered()
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: groups.length,
                            itemBuilder: (context, index) {
                              final group = groups[index];
                              return _DaySection(
                                group: group,
                                onReorder: (id) {
                                  context.read<TripsCubit>().reorderTrip(id);
                                  Navigator.of(context)
                                      .pushNamed(AppRouter.booking);
                                },
                                onInvoice: (id) =>
                                    context.read<TripsCubit>().showInvoice(id),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: AppBottomNavWidget(
        currentIndex: 1,
        onTap: (i) => AppNavHelper.handleTap(context, i, current: 1),
      ),
    );
  }
}

class _DaySection extends StatelessWidget {
  final TripDayGroup group;
  final ValueChanged<String>? onReorder;
  final ValueChanged<String>? onInvoice;

  const _DaySection({
    required this.group,
    this.onReorder,
    this.onInvoice,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 4),
          child: Row(
            children: [
              Text(
                '${group.title} — ${group.countLabel}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                'الإجمالي: ${group.totalLabel}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        ...group.trips.map(
          (trip) => TripCardWidget(
            trip: trip,
            onReorder: () => onReorder?.call(trip.id),
            onInvoice: () => onInvoice?.call(trip.id),
            onDetails: () {},
            onRate: () {},
            onHelp: () {},
          ),
        ),
      ],
    );
  }
}

class _EmptyScheduled extends StatelessWidget {
  const _EmptyScheduled();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined,
              size: 48, color: AppColors.textTertiary),
          SizedBox(height: 12),
          Text(
            'لا توجد رحلات مجدولة',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyFiltered extends StatelessWidget {
  const _EmptyFiltered();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'لا توجد نتائج مطابقة',
        style: TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
