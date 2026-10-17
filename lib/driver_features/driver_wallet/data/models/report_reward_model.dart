import 'package:equatable/equatable.dart';
import 'report_json.dart';

/// The month's numbers for the "rewards" card — `summary` of
/// `GET /api/driver/financial-report/rewards`.
class RewardsSummaryModel extends Equatable {
  final int rewardsCount;
  final double rewardsTotal;

  const RewardsSummaryModel({
    required this.rewardsCount,
    required this.rewardsTotal,
  });

  factory RewardsSummaryModel.fromJson(Map<String, dynamic> json) {
    return RewardsSummaryModel(
      rewardsCount: json['rewards_count'] as int? ?? 0,
      rewardsTotal: reportNum(json['rewards_total']),
    );
  }

  @override
  List<Object?> get props => [rewardsCount, rewardsTotal];
}

/// One reward added to the wallet (`rewards[]`). [createdAt] is UTC text.
class ReportRewardModel extends Equatable {
  final int id;
  final double amount;

  /// The manager's note; null when there is none.
  final String? description;
  final double balanceAfter;
  final String? createdAt;

  const ReportRewardModel({
    required this.id,
    required this.amount,
    this.description,
    required this.balanceAfter,
    this.createdAt,
  });

  factory ReportRewardModel.fromJson(Map<String, dynamic> json) {
    return ReportRewardModel(
      id: json['id'] as int,
      amount: reportNum(json['amount']),
      description: reportText(json['description']),
      balanceAfter: reportNum(json['balance_after']),
      createdAt: reportText(json['created_at']),
    );
  }

  @override
  List<Object?> get props => [id, amount, description, balanceAfter, createdAt];
}
