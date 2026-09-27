import 'package:equatable/equatable.dart';

/// Model representing a promotional offer shown on the home screen.
class OfferModel extends Equatable {
  final String id;
  final String badgeLabel;
  final String title;
  final String description;
  final String promoCode;
  final int discountPercent;

  const OfferModel({
    required this.id,
    required this.badgeLabel,
    required this.title,
    required this.description,
    required this.promoCode,
    required this.discountPercent,
  });

  @override
  List<Object?> get props => [
        id,
        badgeLabel,
        title,
        description,
        promoCode,
        discountPercent,
      ];
}
