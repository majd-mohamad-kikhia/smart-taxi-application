import 'package:equatable/equatable.dart';
import '../../../enums/user_role.dart';

/// Which side of the platform the list is asked for. The wire value is what
/// `GET /api/contact-numbers?app=` expects.
enum ContactUsApp {
  customer,
  driver;

  String get wireValue => name;

  static ContactUsApp fromRole(UserRole role) => switch (role) {
    UserRole.rider => ContactUsApp.customer,
    UserRole.driver => ContactUsApp.driver,
  };
}

/// How a number is reached. Unknown values map to [phone] so an older app
/// never crashes if the server adds a new type.
enum ContactType { phone, whatsapp }

/// One "Contact us" number — `GET /api/contact-numbers`
/// (`ContactNumberPublic` schema). [label] is already in the requested
/// language and [url] (`tel:…` / `https://wa.me/…`) is ready to open as is.
class ContactNumberModel extends Equatable {
  final int id;
  final ContactType type;
  final String label;
  final String phoneNumber;
  final String url;

  const ContactNumberModel({
    required this.id,
    required this.type,
    required this.label,
    required this.phoneNumber,
    required this.url,
  });

  factory ContactNumberModel.fromJson(Map<String, dynamic> json) {
    return ContactNumberModel(
      id: json['id'] as int,
      type: json['type'] == 'whatsapp' ? ContactType.whatsapp : ContactType.phone,
      label: json['label'] as String? ?? '',
      phoneNumber: json['phone_number'] as String? ?? '',
      url: json['url'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [id, type, label, phoneNumber, url];
}
