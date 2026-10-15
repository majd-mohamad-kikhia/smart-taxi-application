import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/driver_features/driver_wallet/data/models/month_report_page_model.dart';
import 'package:mshoar/driver_features/driver_wallet/data/models/report_earning_model.dart';
import 'package:mshoar/driver_features/driver_wallet/data/models/report_month_model.dart';
import 'package:mshoar/driver_features/driver_wallet/data/models/report_pagination_model.dart';
import 'package:mshoar/driver_features/driver_wallet/data/models/report_reward_model.dart';
import 'package:mshoar/driver_features/driver_wallet/data/models/report_trip_model.dart';
import 'package:mshoar/driver_features/driver_wallet/data/repositories/driver_wallet_repository.dart';
import 'package:mshoar/driver_features/driver_wallet/presentation/cubit/month_report_cubit.dart';

const _pagination = {'page': 1, 'limit': 20, 'total': 1, 'total_pages': 1};

void main() {
  group('report models', () {
    test('trips page reads the summary, the trip and the paging', () {
      final page =
          MonthReportPageModel<ReportTripModel, TripsSummaryModel>.fromJson(
            {
              'summary': {
                'orders_count': 10,
                'total_distance_km': 42.7,
                'orders_total_amount': 2320,
              },
              'trips': [
                {
                  'id': 192,
                  'completed_at': '2026-10-10 17:44:39',
                  'pickup_address': 'A',
                  'dropoff_address': null,
                  'distance_km': 3.4,
                  'duration_min': 21,
                  'vehicle_type': {'id': 4, 'name': 'VIP'},
                  'customer_first_name': 'Ahmad',
                  'order_source': 'whatsapp',
                  'price': 220,
                  'payment_status': 'paid',
                  'rating': 5,
                },
              ],
              'pagination': _pagination,
            },
            listKey: 'trips',
            summary: TripsSummaryModel.fromJson,
            item: ReportTripModel.fromJson,
          );

      expect(page.summary.ordersCount, 10);
      expect(page.summary.totalDistanceKm, 42.7);
      final trip = page.items.single;
      expect(trip.id, 192);
      expect(trip.vehicleTypeName, 'VIP');
      expect(trip.orderSource, ReportOrderSource.whatsapp);
      expect(trip.dropoffAddress, isNull);
      expect(trip.isPaid, isTrue);
      expect(trip.rating, 5);
      expect(page.pagination.totalPages, 1);
    });

    test('an unknown order source reads as the app', () {
      expect(ReportOrderSource.fromApi('something'), ReportOrderSource.app);
      expect(ReportOrderSource.fromApi(null), ReportOrderSource.app);
    });

    test('an earning keeps its fees and the null average rate', () {
      final earning = ReportEarningModel.fromJson({
        'id': 192,
        'price': 220,
        'price_is_fixed': true,
        'commission_rate': 5,
        'commission_amount': 11,
        'driver_earning': 209,
        'fees': {'distance_fare': 220, 'waiting_fee': 0},
        'payment_status': 'unpaid',
      });
      expect(earning.driverEarning, 209);
      expect(earning.priceIsFixed, isTrue);
      expect(earning.fees.distanceFare, 220);
      expect(earning.fees.nightFee, 0);
      expect(earning.isPaid, isFalse);
      expect(
        EarningsSummaryModel.fromJson(const {
          'orders_count': 0,
          'avg_commission_rate': null,
        }).avgCommissionRate,
        isNull,
      );
    });

    test('a reward without a note has no description', () {
      final reward = ReportRewardModel.fromJson({
        'id': 7,
        'amount': 500,
        'description': null,
        'balance_after': 4000,
        'created_at': '2026-10-03 09:00:00',
      });
      expect(reward.description, isNull);
      expect(reward.balanceAfter, 4000);
    });
  });

  group('ReportMonthModel', () {
    test('steps across a year boundary', () {
      expect(
        const ReportMonthModel(2026, 1).shifted(-1),
        const ReportMonthModel(2025, 12),
      );
      expect(
        const ReportMonthModel(2025, 12).shifted(1),
        const ReportMonthModel(2026, 1),
      );
    });

    test('stops at the first month and at the current one', () {
      expect(const ReportMonthModel(2020, 1).canGoBack, isFalse);
      expect(const ReportMonthModel(2020, 2).canGoBack, isTrue);
      expect(ReportMonthModel.current().canGoForward, isFalse);
      expect(ReportMonthModel.current().shifted(-1).canGoForward, isTrue);
    });
  });

  group('MonthReportCubit', () {
    MonthReportPageModel<int, String> pageOf(int number, int totalPages) =>
        MonthReportPageModel(
          summary: 'month',
          items: [number * 10, number * 10 + 1],
          pagination: ReportPaginationStub.of(number, totalPages),
        );

    test('loads the first page, then appends the next', () async {
      final calls = <(int, int, int)>[];
      final cubit = MonthReportCubit<int, String>(({
        required year,
        required month,
        required page,
      }) async {
        calls.add((year, month, page));
        return pageOf(page, 2);
      });

      await cubit.load(year: 2026, month: 10);
      expect(cubit.state.items, [10, 11]);
      expect(cubit.state.summary, 'month');
      expect(cubit.state.hasMore, isTrue);

      await cubit.loadMore();
      expect(cubit.state.items, [10, 11, 20, 21]);
      expect(cubit.state.hasMore, isFalse);

      await cubit.loadMore();
      expect(calls, [(2026, 10, 1), (2026, 10, 2)]);
      await cubit.close();
    });

    test('another month drops the old rows and starts from page 1', () async {
      final cubit = MonthReportCubit<int, String>(
        ({required year, required month, required page}) async =>
            pageOf(month, 1),
      );

      await cubit.load(year: 2026, month: 3);
      expect(cubit.state.items, [30, 31]);
      final next = cubit.load(year: 2026, month: 4);
      expect(cubit.state.items, isEmpty);
      expect(cubit.state.isLoading, isTrue);
      await next;
      expect(cubit.state.items, [40, 41]);
      await cubit.close();
    });

    test('a failure keeps the message and the rows already loaded', () async {
      var fail = false;
      final cubit = MonthReportCubit<int, String>(({
        required year,
        required month,
        required page,
      }) async {
        if (fail) throw const DriverWalletException('offline');
        return pageOf(page, 2);
      });

      await cubit.load(year: 2026, month: 10);
      fail = true;
      await cubit.loadMore();
      expect(cubit.state.errorMessage, 'offline');
      expect(cubit.state.items, [10, 11]);
      expect(cubit.state.isLoadingMore, isFalse);
      await cubit.close();
    });
  });
}

/// Builds a pagination block without going through JSON.
class ReportPaginationStub {
  static ReportPaginationModel of(int page, int totalPages) =>
      ReportPaginationModel(
        page: page,
        limit: 20,
        total: totalPages * 2,
        totalPages: totalPages,
      );
}
