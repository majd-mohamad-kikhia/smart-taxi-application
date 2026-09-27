import 'package:equatable/equatable.dart';

/// Enum representing the type of a saved destination.
enum DestinationType { home, work, favorite, custom }

/// Model representing a user's saved destination address.
class SavedDestinationModel extends Equatable {
  final String id;
  final String name;
  final String address;
  final String? gate;
  final DestinationType type;
  final int estimatedMinutes;

  const SavedDestinationModel({
    required this.id,
    required this.name,
    required this.address,
    this.gate,
    required this.type,
    required this.estimatedMinutes,
  });

  @override
  List<Object?> get props => [id, name, address, gate, type, estimatedMinutes];
}
