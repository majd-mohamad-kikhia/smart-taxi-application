import 'package:equatable/equatable.dart';

/// Model representing a past or ongoing trip.
class TripModel extends Equatable {
  final String id;
  final String destinationName;
  final String? destinationDetail;
  final double price;
  final String? terminal;

  const TripModel({
    required this.id,
    required this.destinationName,
    this.destinationDetail,
    required this.price,
    this.terminal,
  });

  String get fullDestinationName {
    if (destinationDetail != null) {
      return '$destinationName ($destinationDetail)';
    }
    return destinationName;
  }

  @override
  List<Object?> get props => [
        id,
        destinationName,
        destinationDetail,
        price,
        terminal,
      ];
}
