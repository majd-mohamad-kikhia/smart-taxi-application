import 'package:equatable/equatable.dart';

/// The `driver` object pushed alongside a `customer:ride_accepted` /
/// `customer:active_ride` event (see docs/socket.md).
class RideDriverModel extends Equatable {
  final int id;
  final String fullName;
  final String? photoUrl;
  final String phoneNumber;
  final double? rating;

  const RideDriverModel({
    required this.id,
    required this.fullName,
    this.photoUrl,
    required this.phoneNumber,
    this.rating,
  });

  factory RideDriverModel.fromJson(Map<String, dynamic> json) {
    return RideDriverModel(
      id: (json['id'] as num).toInt(),
      fullName: '${json['first_name']} ${json['last_name']}',
      photoUrl: json['photo_url'] as String?,
      phoneNumber: json['phone_number'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble(),
    );
  }

  @override
  List<Object?> get props => [id, fullName, photoUrl, phoneNumber, rating];
}
