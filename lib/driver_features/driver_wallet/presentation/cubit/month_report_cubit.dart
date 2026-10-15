import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/month_report_page_model.dart';
import '../../data/repositories/driver_wallet_repository.dart';
import 'month_report_state.dart';

/// Reads one page of a month's report list from the server.
typedef MonthReportFetcher<Item, Summary> =
    Future<MonthReportPageModel<Item, Summary>> Function({
      required int year,
      required int month,
      required int page,
    });

/// Drives one of the wallet's month detail lists (trips, earnings or
/// rewards): the first page of a month, infinite scroll, pull-to-refresh and
/// switching month. Which list it is comes from the [MonthReportFetcher].
class MonthReportCubit<Item, Summary>
    extends Cubit<MonthReportState<Item, Summary>> {
  final MonthReportFetcher<Item, Summary> _fetch;

  MonthReportCubit(this._fetch) : super(MonthReportState<Item, Summary>());

  int? _year;
  int? _month;

  /// Which request is the latest, so a slow earlier month or page can never
  /// overwrite a later one.
  int _latestRequest = 0;

  /// Shows [year]/[month] from its first page. Another month's rows are
  /// dropped at once, so they never stay under this month's label.
  Future<void> load({required int year, required int month}) {
    _year = year;
    _month = month;
    emit(MonthReportState<Item, Summary>());
    return _loadPage(1, replace: true);
  }

  /// Pull-to-refresh: the same month again from page 1, keeping what is on
  /// screen until the new page arrives.
  Future<void> refresh() => _loadPage(1, replace: true);

  /// Infinite scroll: the next page, appended.
  Future<void> loadMore() {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) {
      return Future.value();
    }
    return _loadPage(state.page + 1, replace: false);
  }

  Future<void> _loadPage(int page, {required bool replace}) async {
    final year = _year;
    final month = _month;
    if (isClosed || year == null || month == null) return;
    final request = ++_latestRequest;
    emit(
      state.copyWith(
        isLoading: replace && state.items.isEmpty,
        isLoadingMore: !replace,
        clearError: true,
      ),
    );
    try {
      final result = await _fetch(year: year, month: month, page: page);
      if (isClosed || request != _latestRequest) return;
      emit(
        state.copyWith(
          summary: result.summary,
          items: replace ? result.items : [...state.items, ...result.items],
          page: result.pagination.page,
          totalPages: result.pagination.totalPages,
          isLoading: false,
          isLoadingMore: false,
        ),
      );
    } on DriverWalletException catch (e) {
      if (isClosed || request != _latestRequest) return;
      emit(
        state.copyWith(
          isLoading: false,
          isLoadingMore: false,
          errorMessage: e.message,
        ),
      );
    }
  }
}
