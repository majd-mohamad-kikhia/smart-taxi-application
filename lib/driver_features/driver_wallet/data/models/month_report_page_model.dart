import 'package:equatable/equatable.dart';
import 'report_pagination_model.dart';

/// One page of a monthly report list (`financial-report/trips`, `/earnings`
/// or `/rewards`): the month's [summary] (the numbers of the wallet card it
/// belongs to), this page's [items] and the paging info. The three replies
/// share this shape and differ only in their list key and item fields.
class MonthReportPageModel<Item, Summary> extends Equatable {
  final Summary summary;
  final List<Item> items;
  final ReportPaginationModel pagination;

  const MonthReportPageModel({
    required this.summary,
    required this.items,
    required this.pagination,
  });

  /// [listKey] is the reply's list field (`trips`, `earnings`, `rewards`).
  factory MonthReportPageModel.fromJson(
    Map<String, dynamic> json, {
    required String listKey,
    required Summary Function(Map<String, dynamic>) summary,
    required Item Function(Map<String, dynamic>) item,
  }) {
    return MonthReportPageModel(
      summary: summary(json['summary'] as Map<String, dynamic>),
      items: [
        for (final e in json[listKey] as List? ?? const [])
          item(e as Map<String, dynamic>),
      ],
      pagination: ReportPaginationModel.fromJson(
        json['pagination'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  @override
  List<Object?> get props => [summary, items, pagination];
}
