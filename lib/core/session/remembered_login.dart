import 'package:equatable/equatable.dart';

/// The phone and password a customer or driver asked the app to remember
/// ("Remember me"), to fill the sign-in form the next time.
class RememberedLogin extends Equatable {
  final String phone;
  final String password;

  const RememberedLogin({required this.phone, required this.password});

  @override
  List<Object?> get props => [phone, password];
}
