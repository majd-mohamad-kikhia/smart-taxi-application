import 'package:equatable/equatable.dart';
import '../../data/models/driver_ratings_page_model.dart';

class DriverRatingsState extends Equatable {
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final DriverRatingsSummaryModel summary;
  final List<DriverRatingItemModel> ratings;
  final int page;
  final bool hasMore;

  /// The first page arrived at least once.
  final bool isLoaded;

  const DriverRatingsState({
    this.isLoading = true,
    this.isLoadingMore = false,
    this.errorMessage,
    this.summary = const DriverRatingsSummaryModel(),
    this.ratings = const [],
    this.page = 0,
    this.hasMore = false,
    this.isLoaded = false,
  });

  DriverRatingsState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
    DriverRatingsSummaryModel? summary,
    List<DriverRatingItemModel>? ratings,
    int? page,
    bool? hasMore,
    bool? isLoaded,
  }) => DriverRatingsState(
    isLoading: isLoading ?? this.isLoading,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    summary: summary ?? this.summary,
    ratings: ratings ?? this.ratings,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    isLoaded: isLoaded ?? this.isLoaded,
  );

  @override
  List<Object?> get props => [
    isLoading,
    isLoadingMore,
    errorMessage,
    summary,
    ratings,
    page,
    hasMore,
    isLoaded,
  ];
}
