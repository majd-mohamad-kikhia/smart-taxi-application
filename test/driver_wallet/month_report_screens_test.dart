import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/l10n/generated/app_localizations.dart';
import 'package:mshoar/core/theme/app_palette.dart';
import 'package:mshoar/driver_features/driver_wallet/data/models/month_report_page_model.dart';
import 'package:mshoar/driver_features/driver_wallet/data/models/report_earning_model.dart';
import 'package:mshoar/driver_features/driver_wallet/data/models/report_month_model.dart';
import 'package:mshoar/driver_features/driver_wallet/data/models/report_pagination_model.dart';
import 'package:mshoar/driver_features/driver_wallet/data/models/report_reward_model.dart';
import 'package:mshoar/driver_features/driver_wallet/data/models/report_trip_model.dart';
import 'package:mshoar/driver_features/driver_wallet/presentation/cubit/month_report_cubit.dart';
import 'package:mshoar/driver_features/driver_wallet/presentation/screens/driver_earnings_report_screen.dart';
import 'package:mshoar/driver_features/driver_wallet/presentation/screens/driver_rewards_report_screen.dart';
import 'package:mshoar/driver_features/driver_wallet/presentation/screens/driver_trips_report_screen.dart';
import 'package:mshoar/driver_features/driver_wallet/presentation/widgets/wallet_stat_card_widget.dart';
import 'package:mshoar/core/injection/injection.dart';

const _pagination = ReportPaginationModel(
  page: 1,
  limit: 20,
  total: 1,
  totalPages: 1,
);

const _trip = ReportTripModel(
  id: 192,
  requestedAt: '2026-10-10 17:23:23',
  startedAt: '2026-10-10 17:23:35',
  completedAt: '2026-10-10 17:44:39',
  pickupAddress: 'شارع عمر بن الخطاب، اللاذقية، سوريا — بجانب المركز الثقافي',
  dropoffAddress: 'الزويكلي للحلويات، اللاذقية',
  distanceKm: 3.4,
  durationMin: 21,
  vehicleTypeName: 'بلاتينيوم (VIP)',
  customerFirstName: 'Ahmad',
  orderSource: ReportOrderSource.app,
  price: 220,
  isPaid: true,
  paidAt: '2026-10-10 17:44:40',
  rating: 5,
);

const _earning = ReportEarningModel(
  id: 192,
  completedAt: '2026-10-10 17:44:39',
  pickupAddress: 'شارع عمر بن الخطاب، اللاذقية',
  dropoffAddress: 'الزويكلي للحلويات، اللاذقية',
  price: 220,
  priceIsFixed: true,
  commissionRate: 5,
  commissionAmount: 11,
  driverEarning: 209,
  fees: ReportFeesModel(distanceFare: 200, waitingFee: 20),
  isPaid: true,
);

const _reward = ReportRewardModel(
  id: 9,
  amount: 1000,
  description: 'Top driver of the week',
  balanceAfter: 5000,
  createdAt: '2026-10-12 08:00:00',
);

Widget _app(Locale locale, Widget home, {double textScale = 1}) => MaterialApp(
  locale: locale,
  theme: ThemeData(extensions: [AppPalette.light]),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: home,
);

void main() {
  setUp(() async {
    await sl.reset();
  });

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  for (final locale in const [Locale('ar'), Locale('en')]) {
    for (final scale in const [1.0, 1.4]) {
      final label = '${locale.languageCode} x$scale';

      testWidgets('trips list and the trip details fit a phone ($label)', (
        tester,
      ) async {
        phone(tester);
        sl.registerFactory<
          MonthReportCubit<ReportTripModel, TripsSummaryModel>
        >(
          () => MonthReportCubit(
            ({required year, required month, required page}) async =>
                const MonthReportPageModel(
                  summary: TripsSummaryModel(
                    ordersCount: 10,
                    totalDistanceKm: 42.7,
                    ordersTotalAmount: 2320,
                  ),
                  items: [_trip, _trip],
                  pagination: _pagination,
                ),
          ),
        );
        await tester.pumpWidget(
          _app(
            locale,
            DriverTripsReportScreen(month: ReportMonthModel.current()),
            textScale: scale,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(Scrollable), findsWidgets);
        // Open the first trip's details.
        await _openFirstRow(tester);
        await tester.pumpAndSettle();
        expect(find.textContaining('192'), findsWidgets);
        expect(tester.takeException(), isNull);
      });

      testWidgets('earnings list and the split fit a phone ($label)', (
        tester,
      ) async {
        phone(tester);
        sl.registerFactory<
          MonthReportCubit<ReportEarningModel, EarningsSummaryModel>
        >(
          () => MonthReportCubit(
            ({required year, required month, required page}) async =>
                const MonthReportPageModel(
                  summary: EarningsSummaryModel(
                    ordersCount: 10,
                    ordersTotalAmount: 2320,
                    driverEarnings: 2204,
                    managerEarnings: 116,
                    avgCommissionRate: 5,
                  ),
                  items: [_earning],
                  pagination: _pagination,
                ),
          ),
        );
        await tester.pumpWidget(
          _app(
            locale,
            DriverEarningsReportScreen(month: ReportMonthModel.current()),
            textScale: scale,
          ),
        );
        await tester.pumpAndSettle();
        await _openFirstRow(tester);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('rewards list fits a phone ($label)', (tester) async {
        phone(tester);
        sl.registerFactory<
          MonthReportCubit<ReportRewardModel, RewardsSummaryModel>
        >(
          () => MonthReportCubit(
            ({required year, required month, required page}) async =>
                const MonthReportPageModel(
                  summary: RewardsSummaryModel(
                    rewardsCount: 2,
                    rewardsTotal: 1500,
                  ),
                  items: [_reward],
                  pagination: _pagination,
                ),
          ),
        );
        await tester.pumpWidget(
          _app(
            locale,
            DriverRewardsReportScreen(month: ReportMonthModel.current()),
            textScale: scale,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Top driver of the week'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('a stat card with a long amount fits a phone ($label)', (
        tester,
      ) async {
        phone(tester);
        await tester.pumpWidget(
          _app(
            locale,
            const Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16),
                child: WalletStatCardWidget(
                  label: 'إجمالي دخل الشهر',
                  value: '14,988,400 ل.س جديدة',
                  subValue: '1,498,840,000 ل.س قديمة',
                  icon: Icons.payments_rounded,
                  onTap: _noop,
                ),
              ),
            ),
            textScale: scale,
          ),
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('an empty month says so', (tester) async {
    phone(tester);
    sl.registerFactory<MonthReportCubit<ReportTripModel, TripsSummaryModel>>(
      () => MonthReportCubit(
        ({required year, required month, required page}) async =>
            const MonthReportPageModel(
              summary: TripsSummaryModel(
                ordersCount: 0,
                totalDistanceKm: 0,
                ordersTotalAmount: 0,
              ),
              items: [],
              pagination: ReportPaginationModel(
                page: 1,
                limit: 20,
                total: 0,
                totalPages: 1,
              ),
            ),
      ),
    );
    await tester.pumpWidget(
      _app(
        const Locale('en'),
        DriverTripsReportScreen(month: ReportMonthModel.current()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No completed trips this month'), findsOneWidget);
  });
}

void _noop() {}

/// Taps the first row of the list. Rows are built lazily, so the list is
/// scrolled until one is on screen.
Future<void> _openFirstRow(WidgetTester tester) async {
  final rows = find.byIcon(Icons.trip_origin_rounded).hitTestable();
  for (var i = 0; i < 10 && rows.evaluate().isEmpty; i++) {
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
    await tester.pump();
  }
  await tester.tap(rows.first);
  await tester.pumpAndSettle();
}
