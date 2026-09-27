import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_bottom_nav_widget.dart';
import '../../../../core/widgets/app_nav_helper.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../widgets/home_app_bar_widget.dart';
import '../widgets/home_map_widget.dart';
import '../widgets/last_trip_widget.dart';
import '../widgets/nearest_captain_banner_widget.dart';
import '../widgets/saved_destinations_widget.dart';
import '../widgets/search_destination_widget.dart';
import '../widgets/weekly_offer_widget.dart';

/// Entry point for the Home feature.
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

/// Stateful inner view that handles bottom nav index.
class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      // ── Custom App Bar ──────────────────────────────────
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: HomeAppBarWidget(),
      ),
      // ── Body ────────────────────────────────────────────
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          return _HomeBody(state: state);
        },
      ),
      // ── Bottom Nav ──────────────────────────────────────
      bottomNavigationBar: AppBottomNavWidget(
        currentIndex: 0,
        onTap: (i) => AppNavHelper.handleTap(context, i, current: 0),
      ),
    );
  }
}

/// Scrollable body of the home screen.
class _HomeBody extends StatelessWidget {
  final HomeState state;

  const _HomeBody({required this.state});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Greeting + Location ──────────────────
              _GreetingSectionWidget(state: state),
              // ── Map ──────────────────────────────────
              const HomeMapWidget(),
              // ── Nearest Captain Banner ───────────────
              NearestCaptainBannerWidget(
                minutesAway: state.nearestCaptainMinutes,
                isAvailable: state.isCaptainAvailable,
              ),
              _SectionDivider(),
              const SizedBox(height: 16),
              // ── Search Destination ───────────────────
              SearchDestinationWidget(
                userName: state.userName,
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRouter.booking),
              ),
              const SizedBox(height: 20),
              // ── Saved Destinations ───────────────────
              SavedDestinationsWidget(
                destinations: state.savedDestinations,
                onDestinationTapped: (id) {
                  context.read<HomeCubit>().requestRideToDestination(id);
                  Navigator.of(context).pushNamed(AppRouter.booking);
                },
                onEditTapped: () =>
                    Navigator.of(context).pushNamed(AppRouter.favorites),
              ),
              // ── Last Trip ────────────────────────────
              if (state.lastTrip != null) ...[
                const SizedBox(height: 16),
                LastTripWidget(
                  trip: state.lastTrip!,
                  onRepeatTapped: () {
                    context.read<HomeCubit>().repeatLastTrip();
                    Navigator.of(context).pushNamed(AppRouter.booking);
                  },
                ),
              ],
              // ── Weekly Offer ─────────────────────────
              if (state.weeklyOffer != null) ...[
                const SizedBox(height: 16),
                WeeklyOfferWidget(
                  offer: state.weeklyOffer!,
                  onApplyTapped: () {
                    context.read<HomeCubit>().applyPromoCode(
                          state.weeklyOffer!.promoCode,
                        );
                    Navigator.of(context).pushNamed(AppRouter.booking);
                  },
                ),
              ],
              const SizedBox(height: 28),
            ],
          ),
        ),
      ],
    );
  }
}

/// Greeting section at the top of the body showing name, greeting
/// and current area with a quick-request chip.
class _GreetingSectionWidget extends StatelessWidget {
  final HomeState state;

  const _GreetingSectionWidget({required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Quick Request chip ───────────────────────
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: _QuickRequestChip(),
          ),
          const SizedBox(height: 12),
          // ── Greeting text ────────────────────────────
          Row(
            children: [
              Text(
                '${state.greeting}، ${state.userName} 👋',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // ── Location row ─────────────────────────────
          Row(
            children: [
              const Icon(
                Icons.navigation_rounded,
                color: AppColors.primary,
                size: 16,
              ),
              const SizedBox(width: 5),
              Text(
                'أنت الآن في ${state.currentArea}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Quick-request action chip shown at the top of the greeting section.
class _QuickRequestChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.backgroundGray,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt_rounded, color: AppColors.primary, size: 16),
            SizedBox(width: 4),
            Text(
              'طلب سريع',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thin divider line separating the map area from scrollable content.
class _SectionDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: AppColors.borderLight);
  }
}
