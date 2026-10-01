import 'package:equatable/equatable.dart';

/// Lifecycle of a driver's account-deletion request (swagger
/// `DriverDeletionRequest.status`).
enum DriverDeletionStatus { pending, approved, rejected, cancelled }

/// The driver's latest account-deletion request — see
/// `/api/driver/account/deletion-request` in swagger.json.
class DriverDeletionRequestModel extends Equatable {
  final int id;
  final DriverDeletionStatus status;
  final String? reason;

  /// The manager's note, present on a rejected request.
  final String? reviewNote;

  const DriverDeletionRequestModel({
    required this.id,
    required this.status,
    this.reason,
    this.reviewNote,
  });

  factory DriverDeletionRequestModel.fromJson(Map<String, dynamic> json) {
    return DriverDeletionRequestModel(
      id: json['id'] as int,
      status: DriverDeletionStatus.values.byName(json['status'] as String),
      reason: json['reason'] as String?,
      reviewNote: json['review_note'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, status, reason, reviewNote];
}
