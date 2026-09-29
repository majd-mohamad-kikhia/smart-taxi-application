import 'package:equatable/equatable.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/models/route_point_model.dart';

/// Ride lifecycle status (`status_id` in swagger.json's `Ride` schema).
enum RideStatus {
  requested(1),
  accepted(2),
  arrived(3),
  inProgress(4),
  completed(5),
  cancelled(6);

  final int id;

  const RideStatus(this.id);

  String label(AppLocalizations l10n) => switch (this) {
        RideStatus.requested => l10n.rideStatusPending,
        RideStatus.accepted => l10n.rideStatusAcceptedHist,
        RideStatus.arrived => l10n.rideStatusArrivedHist,
        RideStatus.inProgress => l10n.rideStatusInProgressHist,
        RideStatus.completed => l10n.rideStatusCompletedHist,
        RideStatus.cancelled => l10n.rideStatusCancelledHist,
      };

  static RideStatus fromId(int id) => RideStatus.values.firstWhere(
        (s) => s.id == id,
        orElse: () => RideStatus.requested,
      );
}

/// An intermediate stop (`RideStop` schema).
class RideStopModel extends Equatable {
  final int order;
  final String? address;
  final double? feeCharged;

  const RideStopModel({required this.order, this.address, this.feeCharged});

  factory RideStopModel.fromJson(Map<String, dynamic> json) {
    return RideStopModel(
      order: json['stop_order'] as int? ?? 0,
      address: json['address'] as String?,
      feeCharged: (json['fee_charged'] as num?)?.toDouble(),
    );
  }

  @override
  List<Object?> get props => [order, address, feeCharged];
}

/// A customer ride from `GET /api/customer/rides` and
/// `GET /api/customer/rides/{id}` (`Ride` schema). [stops] and [route] are
/// only filled by the detail endpoint; lists only carry [hasRoute].
class RideHistoryModel extends Equatable {
  final int id;
  final RideStatus status;
  final String? pickupAddress;
  final String? dropoffAddress;
  final double? distanceKm;
  final int? estimatedDurationMin;
  final double price;
  final double stopsFeeTotal;
  final String requestedAt;
  final String? acceptedAt;
  final String? startedAt;
  final String? completedAt;
  final String? cancelledAt;
  final String? cancellationReason;
  final String? cancelledBy;
  final List<RideStopModel> stops;

  /// Whether the driver's driven route was uploaded for this ride.
  final bool hasRoute;

  /// The path the driver actually drove, in time order (detail only).
  final List<RoutePointModel> route;

  const RideHistoryModel({
    required this.id,
    required this.status,
    this.pickupAddress,
    this.dropoffAddress,
    this.distanceKm,
    this.estimatedDurationMin,
    required this.price,
    required this.stopsFeeTotal,
    required this.requestedAt,
    this.acceptedAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancellationReason,
    this.cancelledBy,
    this.stops = const [],
    this.hasRoute = false,
    this.route = const [],
  });

  factory RideHistoryModel.fromJson(Map<String, dynamic> json) {
    final route = (json['route'] as List<dynamic>? ?? const [])
        .map((p) => RoutePointModel(
              ((p as Map<String, dynamic>)['lat'] as num).toDouble(),
              (p['lng'] as num).toDouble(),
            ))
        .toList();
    return RideHistoryModel(
      id: json['id'] as int,
      status: RideStatus.fromId(json['status_id'] as int),
      pickupAddress: json['pickup_address'] as String?,
      dropoffAddress: json['dropoff_address'] as String?,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      estimatedDurationMin: json['estimated_duration_min'] as int?,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      stopsFeeTotal: (json['stops_fee_total'] as num?)?.toDouble() ?? 0,
      requestedAt: json['requested_at'] as String? ?? '',
      acceptedAt: json['accepted_at'] as String?,
      startedAt: json['started_at'] as String?,
      completedAt: json['completed_at'] as String?,
      cancelledAt: json['cancelled_at'] as String?,
      cancellationReason: json['cancellation_reason'] as String?,
      cancelledBy: json['cancelled_by'] as String?,
      stops: (json['stops'] as List<dynamic>? ?? const [])
          .map((s) => RideStopModel.fromJson(s as Map<String, dynamic>))
          .toList(),
      hasRoute: json['has_route'] as bool? ?? route.isNotEmpty,
      route: route,
    );
  }

  @override
  List<Object?> get props => [
        id,
        status,
        pickupAddress,
        dropoffAddress,
        distanceKm,
        estimatedDurationMin,
        price,
        stopsFeeTotal,
        requestedAt,
        acceptedAt,
        startedAt,
        completedAt,
        cancelledAt,
        cancellationReason,
        cancelledBy,
        stops,
        hasRoute,
        route,
      ];
}

/// One page of `GET /api/customer/rides` (`RideListData` schema).
class RideHistoryPage extends Equatable {
  final List<RideHistoryModel> rides;
  final int page;
  final int totalPages;

  const RideHistoryPage({
    required this.rides,
    required this.page,
    required this.totalPages,
  });

  factory RideHistoryPage.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'] as Map<String, dynamic>? ?? const {};
    return RideHistoryPage(
      rides: (json['rides'] as List<dynamic>? ?? const [])
          .map((r) => RideHistoryModel.fromJson(r as Map<String, dynamic>))
          .toList(),
      page: pagination['page'] as int? ?? 1,
      totalPages: pagination['total_pages'] as int? ?? 1,
    );
  }

  @override
  List<Object?> get props => [rides, page, totalPages];
}
