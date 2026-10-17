import 'package:equatable/equatable.dart';

/// The `pagination` block of the monthly report lists.
class ReportPaginationModel extends Equatable {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const ReportPaginationModel({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory ReportPaginationModel.fromJson(Map<String, dynamic> json) {
    return ReportPaginationModel(
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
      total: json['total'] as int? ?? 0,
      totalPages: json['total_pages'] as int? ?? 1,
    );
  }

  @override
  List<Object?> get props => [page, limit, total, totalPages];
}
