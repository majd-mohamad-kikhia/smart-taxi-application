import 'package:equatable/equatable.dart';

/// A calendar month the wallet reports are read for, with the stepping rules
/// of the month arrows: never before the first month the server accepts and
/// never after the current one.
class ReportMonthModel extends Equatable {
  /// The earliest year the financial-report endpoints accept.
  static const int firstYear = 2020;

  final int year;
  final int month;

  const ReportMonthModel(this.year, this.month);

  factory ReportMonthModel.current() {
    final now = DateTime.now();
    return ReportMonthModel(now.year, now.month);
  }

  /// `DateTime` rolls the year over correctly in both directions.
  ReportMonthModel shifted(int months) {
    final moved = DateTime(year, month + months);
    return ReportMonthModel(moved.year, moved.month);
  }

  bool get canGoBack => year > firstYear || (year == firstYear && month > 1);

  bool get canGoForward {
    final now = ReportMonthModel.current();
    return year < now.year || (year == now.year && month < now.month);
  }

  @override
  List<Object?> get props => [year, month];
}
