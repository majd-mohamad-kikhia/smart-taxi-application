import 'package:equatable/equatable.dart';
import '../models/privacy_policy_model.dart';

enum PrivacyPolicyLoadStatus { loading, success, failure }

class PrivacyPolicyState extends Equatable {
  final PrivacyPolicyLoadStatus status;
  final PrivacyPolicyModel? policy;
  final String? errorMessage;

  const PrivacyPolicyState({
    this.status = PrivacyPolicyLoadStatus.loading,
    this.policy,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, policy, errorMessage];
}
