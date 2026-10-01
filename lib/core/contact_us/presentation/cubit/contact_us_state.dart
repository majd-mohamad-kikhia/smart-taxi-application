import 'package:equatable/equatable.dart';
import '../../data/models/contact_number_model.dart';

sealed class ContactUsState extends Equatable {
  const ContactUsState();

  @override
  List<Object?> get props => const [];
}

class ContactUsLoading extends ContactUsState {
  const ContactUsLoading();
}

class ContactUsLoaded extends ContactUsState {
  final List<ContactNumberModel> numbers;

  const ContactUsLoaded(this.numbers);

  @override
  List<Object?> get props => [numbers];
}

class ContactUsError extends ContactUsState {
  final String message;

  const ContactUsError(this.message);

  @override
  List<Object?> get props => [message];
}
