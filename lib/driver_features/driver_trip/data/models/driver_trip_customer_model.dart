import 'package:equatable/equatable.dart';
import '../../../../core/models/order_offer_model.dart';

/// The rider on a single-ride reply (`DriverRide.customer`): who to call at
/// pickup, and who gets the bill of an office order.
class DriverTripCustomerModel extends Equatable {
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;

  const DriverTripCustomerModel({this.firstName, this.lastName, this.phoneNumber});

  static DriverTripCustomerModel? fromParent(Map<String, dynamic> ride) {
    final customer = ride['customer'];
    if (customer is! Map) return null;
    return DriverTripCustomerModel(
      firstName: OrderOfferModel.textOrNull(customer['first_name']),
      lastName: OrderOfferModel.textOrNull(customer['last_name']),
      phoneNumber: OrderOfferModel.textOrNull(customer['phone_number']),
    );
  }

  String? get fullName {
    final name = [?firstName, ?lastName].join(' ');
    return name.isEmpty ? null : name;
  }

  @override
  List<Object?> get props => [firstName, lastName, phoneNumber];
}
