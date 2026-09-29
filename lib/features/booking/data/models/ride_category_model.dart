import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../../core/l10n/generated/app_localizations.dart';

/// Available ride category tiers shown on the booking screen.
enum RideCategoryType { economy, comfort, familyXl }

/// Model representing a selectable ride category with price & ETA.
class RideCategoryModel extends Equatable {
  final String id;
  final RideCategoryType type;
  final String name;
  final String? badge;
  final int etaMinutes;
  final double price;
  final int? passengerCapacity;
  final IconData icon;

  const RideCategoryModel({
    required this.id,
    required this.type,
    required this.name,
    this.badge,
    required this.etaMinutes,
    required this.price,
    this.passengerCapacity,
    required this.icon,
  });

  String etaLabel(AppLocalizations l10n) {
    if (passengerCapacity != null) {
      return l10n.bookingCapacityEta('$passengerCapacity', '$etaMinutes');
    }
    return l10n.bookingEtaMinutes('$etaMinutes');
  }

  String priceLabel(AppLocalizations l10n) =>
      l10n.priceSyp(price.toStringAsFixed(0));

  @override
  List<Object?> get props => [
    id,
    type,
    name,
    badge,
    etaMinutes,
    price,
    passengerCapacity,
    icon,
  ];
}
