import 'package:equatable/equatable.dart';

/// One vehicle type with its price quote for the requested trip, as
/// returned in `vehicle_types[]` by `POST /api/customer/rides/locations`.
///
/// The price is the server's, shown as it came: the app never works one out.
/// The server charges a flat price per distance band, so `price_per_km` and
/// `base_fare` in the response are not rates to multiply by a distance and
/// are deliberately not read here.
class VehicleTypeQuoteModel extends Equatable {
  final int vehicleTypeId;
  final String name;
  final String? description;

  /// The car's picture as a path on the server (`image_url`, for example
  /// `/uploads/vehicle-types/economy.webp`); null when none is set.
  final String? imageUrl;
  final bool available;

  /// The server's `estimated_price` for this trip; null when the type is not
  /// available (or the server could not quote one).
  final double? price;
  final double stopsFeeTotal;

  /// This car's fee for a pickup or drop-off in a listed area, already
  /// inside [price]. 0 when the car has none here. Shown, never added.
  final double locationFee;

  /// How much of [price] the customer's wallet would cover (an estimate: the
  /// final price at the end of the trip decides). 0 when the wallet is empty
  /// or the type has no price.
  final double walletUsed;

  /// [price] minus [walletUsed]: the cash the customer would pay. Null when
  /// the type has no price.
  final double? priceAfterWallet;

  const VehicleTypeQuoteModel({
    required this.vehicleTypeId,
    required this.name,
    this.description,
    this.imageUrl,
    required this.available,
    this.price,
    required this.stopsFeeTotal,
    this.locationFee = 0,
    this.walletUsed = 0,
    this.priceAfterWallet,
  });

  factory VehicleTypeQuoteModel.fromJson(Map<String, dynamic> json) {
    final available = json['available'] as bool? ?? false;
    final price = available
        ? ((json['estimated_price'] ?? json['price']) as num?)?.toDouble()
        : null;
    final walletUsed = price == null
        ? 0.0
        : ((json['wallet_used'] as num?)?.toDouble() ?? 0);
    return VehicleTypeQuoteModel(
      vehicleTypeId: json['vehicle_type_id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: _textOrNull(json['image_url']),
      available: available,
      price: price,
      walletUsed: walletUsed,
      priceAfterWallet: price == null
          ? null
          : ((json['price_after_wallet'] as num?)?.toDouble() ??
                (price - walletUsed).clamp(0, double.infinity).toDouble()),
      stopsFeeTotal: (json['stops_fee_total'] as num?)?.toDouble() ?? 0,
      locationFee: available
          ? (json['location_fee'] as num?)?.toDouble() ?? 0
          : 0,
    );
  }

  @override
  List<Object?> get props => [
    vehicleTypeId,
    name,
    description,
    imageUrl,
    available,
    price,
    stopsFeeTotal,
    locationFee,
    walletUsed,
    priceAfterWallet,
  ];

  /// The wallet covers part of the price.
  bool get hasWalletDiscount => price != null && walletUsed > 0;

  /// What the customer pays in cash: the price after the wallet, or the
  /// whole [price] when the wallet covers nothing.
  double? get payablePrice => hasWalletDiscount ? priceAfterWallet : price;

  static String? _textOrNull(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
