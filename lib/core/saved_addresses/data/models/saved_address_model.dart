import 'package:equatable/equatable.dart';
import '../../../models/picked_location_model.dart';

/// `home` / `work` / `other` — one home and one work per customer.
enum SavedAddressType {
  home('home'),
  work('work'),
  other('other');

  final String wireValue;

  const SavedAddressType(this.wireValue);

  static SavedAddressType fromWire(String? value) =>
      SavedAddressType.values.firstWhere(
        (t) => t.wireValue == value,
        orElse: () => SavedAddressType.other,
      );
}

/// A place the customer saved to order faster — swagger `SavedAddress`.
class SavedAddressModel extends Equatable {
  final int id;
  final SavedAddressType type;

  /// The customer's name for an `other` place ("Gym"); usually null for
  /// home / work, which the app names itself.
  final String? label;
  final String? address;
  final String? addressDetails;
  final double lat;
  final double lng;

  const SavedAddressModel({
    required this.id,
    required this.type,
    this.label,
    this.address,
    this.addressDetails,
    required this.lat,
    required this.lng,
  });

  factory SavedAddressModel.fromJson(Map<String, dynamic> json) {
    return SavedAddressModel(
      id: (json['id'] as num).toInt(),
      type: SavedAddressType.fromWire(json['type'] as String?),
      label: json['label'] as String?,
      address: json['address'] as String?,
      addressDetails: json['address_details'] as String?,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }

  /// Fills a pickup / drop-off point of an order. The stored [address] text is
  /// left out on purpose: it may be Google's (older versions saved it), so the
  /// name of the spot is looked up again, free when it was named within 25 m.
  PickedLocationModel toPickedLocation() => PickedLocationModel(
    latitude: lat,
    longitude: lng,
    addressDetails: addressDetails,
  );

  @override
  List<Object?> get props => [
    id,
    type,
    label,
    address,
    addressDetails,
    lat,
    lng,
  ];
}

/// `POST` result: the address, and whether it replaced the old home / work.
class SavedAddressSaveResult {
  final SavedAddressModel address;
  final bool replaced;

  const SavedAddressSaveResult({required this.address, required this.replaced});
}
