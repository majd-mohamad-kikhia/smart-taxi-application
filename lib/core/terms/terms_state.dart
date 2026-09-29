import 'package:equatable/equatable.dart';
import '../models/terms_model.dart';

enum TermsLoadStatus { loading, success, failure }

class TermsState extends Equatable {
  final TermsLoadStatus status;
  final TermsModel? terms;
  final String? errorMessage;

  const TermsState({
    this.status = TermsLoadStatus.loading,
    this.terms,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, terms, errorMessage];
}
