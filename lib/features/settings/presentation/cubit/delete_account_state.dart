import 'package:equatable/equatable.dart';

enum DeleteAccountStatus { idle, submitting, success, failure }

class DeleteAccountState extends Equatable {
  final DeleteAccountStatus status;
  final String? errorMessage;

  const DeleteAccountState({required this.status, this.errorMessage});

  const DeleteAccountState.initial() : this(status: DeleteAccountStatus.idle);

  bool get isSubmitting => status == DeleteAccountStatus.submitting;

  @override
  List<Object?> get props => [status, errorMessage];
}
