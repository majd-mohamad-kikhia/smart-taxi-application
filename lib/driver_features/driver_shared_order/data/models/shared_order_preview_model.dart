import 'package:equatable/equatable.dart';
import '../../../../core/models/order_offer_model.dart';
import '../../../../core/utils/parse_utc_date.dart';

/// Whether this driver can take an office order, as the API words it in
/// `availability` (preview) or `errors.availability` (failed accept).
enum SharedOrderAvailability {
  available('available'),
  scheduled('scheduled'),
  busy('busy'),
  wrongVehicleType('wrong_vehicle_type'),
  noVehicle('no_vehicle'),
  notActive('not_active'),
  blocked('blocked'),
  yours('yours'),
  taken('taken'),
  cancelled('cancelled'),

  /// A value this app version doesn't know yet.
  unknown('');

  final String wireValue;

  const SharedOrderAvailability(this.wireValue);

  static SharedOrderAvailability fromWire(Object? value) {
    for (final availability in values) {
      if (availability != unknown && availability.wireValue == value) {
        return availability;
      }
    }
    return unknown;
  }

  /// Nobody can take the order any more.
  bool get isClosed => this == taken || this == cancelled;
}

/// `GET /api/driver/rides/shared/{token}` — an office order opened from
/// its WhatsApp link, and whether this driver may accept it. Has no
/// customer name or phone: those come with the accepted ride.
class SharedOrderPreviewModel extends Equatable {
  final SharedOrderAvailability availability;
  final bool canAccept;

  /// When a scheduled order can be accepted (UTC); set only while
  /// [availability] is `scheduled`.
  final DateTime? opensAt;

  final OrderOfferModel order;
  final String? vehicleTypeName;

  /// Addresses of the stops between pickup and drop-off, in order.
  final List<String> stops;

  /// Pickup time of a scheduled order, as the API sent it (UTC).
  final String? scheduledAt;

  const SharedOrderPreviewModel({
    required this.availability,
    required this.canAccept,
    required this.order,
    this.opensAt,
    this.vehicleTypeName,
    this.stops = const [],
    this.scheduledAt,
  });

  int get rideId => order.rideId;

  factory SharedOrderPreviewModel.fromJson(Map<String, dynamic> json) {
    final order = Map<String, dynamic>.from(json['order'] as Map);
    final opensAt = json['opens_at'];
    return SharedOrderPreviewModel(
      availability: SharedOrderAvailability.fromWire(json['availability']),
      canAccept: json['can_accept'] == true,
      opensAt: opensAt is String ? parseUtcDateTime(opensAt) : null,
      order: _orderFrom(order),
      vehicleTypeName: OrderOfferModel.textOrNull(order['vehicle_type_name']),
      stops: _stopsFrom(order['stops']),
      scheduledAt: OrderOfferModel.textOrNull(order['scheduled_at']),
    );
  }

  /// The same order with another availability — after a failed accept
  /// told us what changed.
  SharedOrderPreviewModel withAvailability(
    SharedOrderAvailability availability, {
    DateTime? opensAt,
  }) {
    return SharedOrderPreviewModel(
      availability: availability,
      canAccept: availability == SharedOrderAvailability.available,
      opensAt: opensAt ?? this.opensAt,
      order: order,
      vehicleTypeName: vehicleTypeName,
      stops: stops,
      scheduledAt: scheduledAt,
    );
  }

  static OrderOfferModel _orderFrom(Map<String, dynamic> json) {
    final requestedAt = json['requested_at'];
    return OrderOfferModel(
      rideId: (json['ride_id'] as num).toInt(),
      vehicleTypeId: (json['vehicle_type_id'] as num?)?.toInt() ?? 0,
      pickupLat: (json['pickup_lat'] as num).toDouble(),
      pickupLng: (json['pickup_lng'] as num).toDouble(),
      pickupAddress: json['pickup_address'] as String? ?? '',
      dropoffLat: (json['dropoff_lat'] as num).toDouble(),
      dropoffLng: (json['dropoff_lng'] as num).toDouble(),
      dropoffAddress: json['dropoff_address'] as String? ?? '',
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
      estimatedDurationMin: (json['estimated_duration_min'] as num?)?.toInt() ?? 0,
      estimatedPrice: (json['estimated_price'] as num?)?.toDouble() ?? 0,
      priceIsEstimate: json['price_is_estimate'] as bool? ?? true,
      requestedAt: (requestedAt is String ? parseUtcDateTime(requestedAt) : null) ??
          DateTime.now().toUtc(),
      distanceToPickupKm: 0,
      pickupAddressDetails: OrderOfferModel.textOrNull(json['pickup_address_details']),
      dropoffAddressDetails: OrderOfferModel.textOrNull(json['dropoff_address_details']),
      note: OrderOfferModel.textOrNull(json['note']),
      passengersCount: OrderOfferModel.countOrNull(json['passengers_count']),
    );
  }

  static List<String> _stopsFrom(Object? raw) {
    if (raw is! List) return const [];
    final stops = raw.whereType<Map>().toList()
      ..sort((a, b) => ((a['stop_order'] as num?) ?? 0).compareTo((b['stop_order'] as num?) ?? 0));
    return [
      for (final stop in stops) ?OrderOfferModel.textOrNull(stop['address']),
    ];
  }

  @override
  List<Object?> get props => [
        availability,
        canAccept,
        opensAt,
        order,
        vehicleTypeName,
        stops,
        scheduledAt,
      ];
}
