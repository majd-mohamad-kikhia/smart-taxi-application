import 'package:equatable/equatable.dart';
import '../../data/models/trip_history_model.dart';

/// Immutable state for the My Trips screen.
class TripsState extends Equatable {
  final TripsTab selectedTab;
  final TripFilter selectedFilter;
  final String searchQuery;
  final List<TripDayGroup> dayGroups;
  final int pastCount;
  final int scheduledCount;
  final Map<TripFilter, int> filterCounts;
  final bool isLoading;

  const TripsState({
    required this.selectedTab,
    required this.selectedFilter,
    required this.searchQuery,
    required this.dayGroups,
    required this.pastCount,
    required this.scheduledCount,
    required this.filterCounts,
    required this.isLoading,
  });

  List<TripDayGroup> get filteredGroups {
    if (selectedTab == TripsTab.scheduled) return const [];

    final query = searchQuery.trim();
    return dayGroups
        .map((group) {
          final trips = group.trips.where((trip) {
            final matchesFilter = switch (selectedFilter) {
              TripFilter.all => true,
              TripFilter.completed =>
                trip.status == TripHistoryStatus.completed,
              TripFilter.cancelled =>
                trip.status == TripHistoryStatus.cancelled,
              TripFilter.business =>
                trip.status == TripHistoryStatus.business,
            };
            if (!matchesFilter) return false;
            if (query.isEmpty) return true;
            final haystack = [
              trip.pickupAddress,
              trip.destinationAddress,
              trip.categoryName,
              trip.vehicleDetails,
              trip.captainName ?? '',
            ].join(' ').toLowerCase();
            return haystack.contains(query.toLowerCase());
          }).toList();

          if (trips.isEmpty) return null;
          final total = trips.fold<double>(0, (sum, t) => sum + t.price);
          return TripDayGroup(
            title: group.title,
            totalPrice: total,
            trips: trips,
          );
        })
        .whereType<TripDayGroup>()
        .toList();
  }

  factory TripsState.initial() {
    final now = DateTime(2025, 10, 24, 14, 45);
    final yesterday = DateTime(2025, 10, 23, 8, 30);
    final lastWeek = DateTime(2025, 10, 19, 23, 15);

    final groups = [
      TripDayGroup(
        title: 'اليوم، 24 أكتوبر',
        totalPrice: 38.50,
        trips: [
          TripHistoryModel(
            id: 't1',
            status: TripHistoryStatus.completed,
            dateTime: now,
            categoryName: 'سيارة مريحة',
            vehicleDetails: 'لكزس ES • لوحة أ ب ج 4022',
            pickupAddress: 'برج المملكة، طريق العروبة...',
            destinationAddress: 'النخيل مول، بوابة 3',
            price: 38.50,
            distanceKm: 18.4,
            durationMinutes: 22,
            paymentMethod: 'Apple Pay',
          ),
        ],
      ),
      TripDayGroup(
        title: 'أمس، 23 أكتوبر',
        totalPrice: 44.00,
        trips: [
          TripHistoryModel(
            id: 't2',
            status: TripHistoryStatus.completed,
            dateTime: yesterday,
            categoryName: 'اقتصادي',
            vehicleDetails: 'هيونداي إلنترا • لوحة س د ق 1984',
            pickupAddress: 'الياسمين، شارع أنس بن مالك',
            destinationAddress: 'واجهة روشن، بوابة الفعاليات',
            price: 44.00,
            captainName: 'كابتن ماجد',
            captainRating: 5.0,
            paymentMethod: 'محفظة',
          ),
        ],
      ),
      TripDayGroup(
        title: 'الأسبوع الماضي، 19 أكتوبر',
        totalPrice: 0,
        trips: [
          TripHistoryModel(
            id: 't3',
            status: TripHistoryStatus.cancelled,
            dateTime: lastWeek,
            categoryName: 'مشوار عادي',
            vehicleDetails: '—',
            pickupAddress: 'بوليفارد سيتي',
            destinationAddress: 'حطين، شارع الخير',
            price: 0,
            cancelReason: 'أُلغيت من قبل الراكب خلال دقيقتين',
            isDimmed: true,
          ),
        ],
      ),
    ];

    return TripsState(
      selectedTab: TripsTab.past,
      selectedFilter: TripFilter.all,
      searchQuery: '',
      dayGroups: groups,
      pastCount: 3,
      scheduledCount: 0,
      filterCounts: const {
        TripFilter.all: 24,
        TripFilter.completed: 22,
        TripFilter.cancelled: 2,
        TripFilter.business: 1,
      },
      isLoading: false,
    );
  }

  TripsState copyWith({
    TripsTab? selectedTab,
    TripFilter? selectedFilter,
    String? searchQuery,
    List<TripDayGroup>? dayGroups,
    int? pastCount,
    int? scheduledCount,
    Map<TripFilter, int>? filterCounts,
    bool? isLoading,
  }) {
    return TripsState(
      selectedTab: selectedTab ?? this.selectedTab,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      dayGroups: dayGroups ?? this.dayGroups,
      pastCount: pastCount ?? this.pastCount,
      scheduledCount: scheduledCount ?? this.scheduledCount,
      filterCounts: filterCounts ?? this.filterCounts,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
        selectedTab,
        selectedFilter,
        searchQuery,
        dayGroups,
        pastCount,
        scheduledCount,
        filterCounts,
        isLoading,
      ];
}
