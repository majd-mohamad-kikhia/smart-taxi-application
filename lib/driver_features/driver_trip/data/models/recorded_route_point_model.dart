/// One recorded GPS sample of the trip, as sent in
/// `PUT /api/driver/rides/{id}/route` (`RoutePoint`): position plus the
/// UTC time it was recorded (ISO-8601 with a `Z` timezone).
class RecordedRoutePointModel {
  final double lat;
  final double lng;
  final DateTime recordedAt;

  RecordedRoutePointModel({
    required this.lat,
    required this.lng,
    required DateTime recordedAt,
  }) : recordedAt = recordedAt.toUtc();

  factory RecordedRoutePointModel.fromJson(Map<String, dynamic> json) {
    return RecordedRoutePointModel(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      recordedAt: DateTime.parse(json['recorded_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'lat': lat,
    'lng': lng,
    'recorded_at': recordedAt.toIso8601String(),
  };
}

/// A trip's recorded points saved on the device until the server has
/// confirmed the upload. [isFinished] is set once the ride was finished on
/// the server — only then is the route allowed to be uploaded.
class PendingRouteModel {
  final int rideId;
  final List<RecordedRoutePointModel> points;
  final bool isFinished;
  final DateTime savedAt;

  PendingRouteModel({
    required this.rideId,
    required this.points,
    required this.isFinished,
    required this.savedAt,
  });

  factory PendingRouteModel.fromJson(Map<String, dynamic> json) {
    return PendingRouteModel(
      rideId: json['ride_id'] as int,
      points: (json['points'] as List)
          .map((p) => RecordedRoutePointModel.fromJson(Map<String, dynamic>.from(p as Map)))
          .toList(),
      isFinished: json['is_finished'] as bool,
      savedAt: DateTime.parse(json['saved_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'ride_id': rideId,
    'points': points.map((p) => p.toJson()).toList(),
    'is_finished': isFinished,
    'saved_at': savedAt.toUtc().toIso8601String(),
  };
}
