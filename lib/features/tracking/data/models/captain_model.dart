import 'package:equatable/equatable.dart';
import '../../../../core/l10n/generated/app_localizations.dart';

/// Model representing the assigned captain for a live trip.
class CaptainModel extends Equatable {
  final String id;
  final String name;
  final double rating;
  final int completedTrips;
  final bool isVerified;
  final String vehicleModel;
  final String vehicleColor;
  final String plateNumber;
  final String plateLetters;

  const CaptainModel({
    required this.id,
    required this.name,
    required this.rating,
    required this.completedTrips,
    required this.isVerified,
    required this.vehicleModel,
    required this.vehicleColor,
    required this.plateNumber,
    required this.plateLetters,
  });

  String get vehicleLabel => '$vehicleModel • $vehicleColor';

  String tripsLabel(AppLocalizations l10n) =>
      l10n.captainCertified('$completedTrips');

  @override
  List<Object?> get props => [
        id,
        name,
        rating,
        completedTrips,
        isVerified,
        vehicleModel,
        vehicleColor,
        plateNumber,
        plateLetters,
      ];
}
