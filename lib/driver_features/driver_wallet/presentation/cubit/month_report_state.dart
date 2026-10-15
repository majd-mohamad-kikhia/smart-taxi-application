import 'package:equatable/equatable.dart';

/// A month's detail list: the month's [summary] (null until the first page
/// is in), the rows loaded so far, and where paging stands. Immutable.
class MonthReportState<Item, Summary> extends Equatable {
  final Summary? summary;
  final List<Item> items;
  final int page;
  final int totalPages;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;

  const MonthReportState({
    this.summary,
    this.items = const [],
    this.page = 1,
    this.totalPages = 1,
    this.isLoading = true,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  bool get hasMore => page < totalPages;

  MonthReportState<Item, Summary> copyWith({
    Summary? summary,
    List<Item>? items,
    int? page,
    int? totalPages,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MonthReportState(
      summary: summary ?? this.summary,
      items: items ?? this.items,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    summary,
    items,
    page,
    totalPages,
    isLoading,
    isLoadingMore,
    errorMessage,
  ];
}
