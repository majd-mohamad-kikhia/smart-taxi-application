import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/paginated_list_widget.dart';
import '../../data/models/report_month_model.dart';
import '../cubit/month_report_cubit.dart';
import '../cubit/month_report_state.dart';
import 'wallet_month_stepper_widget.dart';

/// The shared body of the wallet's month detail screens: the month stepper,
/// then the month's summary card scrolling together with its paged list of
/// rows. It starts on [initialMonth] (the one on the wallet screen) and
/// reloads when the customer steps to another. Needs a
/// [MonthReportCubit] of the same types above it.
class MonthReportViewWidget<Item, Summary> extends StatefulWidget {
  final String title;
  final ReportMonthModel initialMonth;
  final Widget Function(BuildContext context, Summary summary) summaryBuilder;
  final Widget Function(BuildContext context, Item item) itemBuilder;
  final String emptyMessage;
  final IconData emptyIcon;

  const MonthReportViewWidget({
    super.key,
    required this.title,
    required this.initialMonth,
    required this.summaryBuilder,
    required this.itemBuilder,
    required this.emptyMessage,
    required this.emptyIcon,
  });

  @override
  State<MonthReportViewWidget<Item, Summary>> createState() =>
      _MonthReportViewWidgetState<Item, Summary>();
}

class _MonthReportViewWidgetState<Item, Summary>
    extends State<MonthReportViewWidget<Item, Summary>> {
  /// Widest the list grows on tablets and desktop windows.
  static const double _maxContentWidth = 720;

  late ReportMonthModel _month = widget.initialMonth;

  MonthReportCubit<Item, Summary> get _cubit =>
      context.read<MonthReportCubit<Item, Summary>>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _cubit.load(year: _month.year, month: _month.month);

  void _changeMonth(ReportMonthModel month) {
    setState(() => _month = month);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.backgroundGray,
      appBar: AppBar(title: Text(widget.title)),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxContentWidth),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: AppConstants.paddingS),
                child: WalletMonthStepperWidget(
                  month: _month,
                  onChanged: _changeMonth,
                ),
              ),
              Expanded(
                child:
                    BlocBuilder<
                      MonthReportCubit<Item, Summary>,
                      MonthReportState<Item, Summary>
                    >(builder: (context, state) => _list(context, state)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _list(BuildContext context, MonthReportState<Item, Summary> state) {
    final summary = state.summary;
    // The summary is the list's first row, so it scrolls away and leaves the
    // room to the trips; an empty month shows only the empty message.
    final rows = <Object>[
      if (summary != null && state.items.isNotEmpty) summary as Object,
      for (final item in state.items) item as Object,
    ];
    final cubit = context.read<MonthReportCubit<Item, Summary>>();
    return PaginatedListWidget<Object>(
      items: rows,
      isLoading: state.isLoading,
      isLoadingMore: state.isLoadingMore,
      hasMore: state.hasMore,
      errorMessage: state.errorMessage,
      emptyMessage: widget.emptyMessage,
      emptyIcon: widget.emptyIcon,
      padding: const EdgeInsets.fromLTRB(
        AppConstants.paddingL,
        AppConstants.paddingS,
        AppConstants.paddingL,
        AppConstants.paddingL,
      ),
      separator: const SizedBox(height: AppConstants.paddingM),
      onRetry: _load,
      onRefresh: cubit.refresh,
      onLoadMore: cubit.loadMore,
      itemBuilder: (context, row, _) => row is Item
          ? widget.itemBuilder(context, row as Item)
          : widget.summaryBuilder(context, row as Summary),
    );
  }
}
