import 'package:equatable/equatable.dart';
import '../../data/models/ride_history_model.dart';

/// Immutable state for the paginated "my rides" list.
class TripsState extends Equatable {
  final List<RideHistoryModel> rides;
  final RideStatus? selectedStatus;
  final int page;
  final int totalPages;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;

  const TripsState({
    this.rides = const [],
    this.selectedStatus,
    this.page = 0,
    this.totalPages = 1,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  bool get hasMore => page < totalPages;

  TripsState copyWith({
    List<RideHistoryModel>? rides,
    RideStatus? selectedStatus,
    bool clearStatus = false,
    int? page,
    int? totalPages,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TripsState(
      rides: rides ?? this.rides,
      selectedStatus:
          clearStatus ? null : (selectedStatus ?? this.selectedStatus),
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props =>
      [rides, selectedStatus, page, totalPages, isLoading, isLoadingMore, errorMessage];
}
