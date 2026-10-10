import 'package:equatable/equatable.dart';

/// How a driver's ratings add up: the average (null with no ratings yet), how
/// many there are, and how many of each star — for the bars.
class DriverRatingsSummaryModel extends Equatable {
  final double? average;
  final int count;

  /// Stars (1–5) to how many ratings gave them; every star is present.
  final Map<int, int> distribution;

  const DriverRatingsSummaryModel({
    this.average,
    this.count = 0,
    this.distribution = const {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
  });

  factory DriverRatingsSummaryModel.fromJson(Map<String, dynamic> json) {
    final raw = json['distribution'];
    int countFor(int star) =>
        raw is Map ? (raw['$star'] as num?)?.toInt() ?? 0 : 0;
    return DriverRatingsSummaryModel(
      average: (json['average'] as num?)?.toDouble(),
      count: (json['count'] as num?)?.toInt() ?? 0,
      distribution: {for (var star = 1; star <= 5; star++) star: countFor(star)},
    );
  }

  /// The share (0–1) of ratings that gave [star] stars.
  double shareOf(int star) =>
      count == 0 ? 0 : (distribution[star] ?? 0) / count;

  @override
  List<Object?> get props => [average, count, distribution];
}

/// One rating a customer gave this driver.
class DriverRatingItemModel extends Equatable {
  final int rideId;
  final int stars;
  final String? comment;
  final String? ratedAt;
  final String? pickupAddress;
  final String? dropoffAddress;

  /// First name only — the server never sends more.
  final String? customerFirstName;

  const DriverRatingItemModel({
    required this.rideId,
    required this.stars,
    this.comment,
    this.ratedAt,
    this.pickupAddress,
    this.dropoffAddress,
    this.customerFirstName,
  });

  factory DriverRatingItemModel.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'];
    final comment = json['comment'];
    return DriverRatingItemModel(
      rideId: (json['ride_id'] as num).toInt(),
      stars: ((json['rating'] as num?)?.toInt() ?? 0).clamp(0, 5),
      comment: comment is String && comment.trim().isNotEmpty ? comment.trim() : null,
      ratedAt: json['rated_at'] as String?,
      pickupAddress: json['pickup_address'] as String?,
      dropoffAddress: json['dropoff_address'] as String?,
      customerFirstName: customer is Map ? customer['first_name'] as String? : null,
    );
  }

  @override
  List<Object?> get props => [
    rideId,
    stars,
    comment,
    ratedAt,
    pickupAddress,
    dropoffAddress,
    customerFirstName,
  ];
}

/// One page of `GET /api/driver/ratings`.
class DriverRatingsPageModel extends Equatable {
  final DriverRatingsSummaryModel summary;
  final List<DriverRatingItemModel> ratings;
  final int page;
  final int totalPages;

  const DriverRatingsPageModel({
    required this.summary,
    required this.ratings,
    required this.page,
    required this.totalPages,
  });

  factory DriverRatingsPageModel.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'];
    final pagination = json['pagination'];
    return DriverRatingsPageModel(
      summary: summary is Map
          ? DriverRatingsSummaryModel.fromJson(Map<String, dynamic>.from(summary))
          : const DriverRatingsSummaryModel(),
      ratings: [
        for (final item in (json['ratings'] as List? ?? const []))
          if (item is Map)
            DriverRatingItemModel.fromJson(Map<String, dynamic>.from(item)),
      ],
      page: pagination is Map ? (pagination['page'] as num?)?.toInt() ?? 1 : 1,
      totalPages: pagination is Map
          ? (pagination['total_pages'] as num?)?.toInt() ?? 1
          : 1,
    );
  }

  bool get hasMore => page < totalPages;

  @override
  List<Object?> get props => [summary, ratings, page, totalPages];
}

/// Socket `driver:rating_received`: a customer just rated this driver.
class DriverRatingReceivedModel extends Equatable {
  final int rideId;
  final int stars;

  /// The driver's new average, when the server sent it.
  final double? average;
  final int? count;

  const DriverRatingReceivedModel({
    required this.rideId,
    required this.stars,
    this.average,
    this.count,
  });

  /// Null for an event that doesn't carry usable stars.
  static DriverRatingReceivedModel? tryParse(Map<String, dynamic> json) {
    final stars = json['rating'];
    if (stars is! num || stars < 1 || stars > 5) return null;
    return DriverRatingReceivedModel(
      rideId: (json['ride_id'] as num?)?.toInt() ?? 0,
      stars: stars.toInt(),
      average: (json['average'] as num?)?.toDouble(),
      count: (json['count'] as num?)?.toInt(),
    );
  }

  @override
  List<Object?> get props => [rideId, stars, average, count];
}
