import 'package:equatable/equatable.dart';

/// User profile data shown on the settings screen.
class UserProfileModel extends Equatable {
  final String id;
  final String fullName;
  final String phone;
  final String email;
  final bool isVerified;
  final double walletBalance;

  const UserProfileModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.isVerified,
    required this.walletBalance,
  });

  String get walletLabel => '${walletBalance.toStringAsFixed(2)} ر.س';

  @override
  List<Object?> get props => [
        id,
        fullName,
        phone,
        email,
        isVerified,
        walletBalance,
      ];
}

/// A single settings menu row.
class SettingsItemModel extends Equatable {
  final String id;
  final String title;
  final String subtitle;
  final String? badge;
  final String? trailingAction;
  final bool hasToggle;
  final bool hasChevron;

  const SettingsItemModel({
    required this.id,
    required this.title,
    required this.subtitle,
    this.badge,
    this.trailingAction,
    this.hasToggle = false,
    this.hasChevron = true,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        subtitle,
        badge,
        trailingAction,
        hasToggle,
        hasChevron,
      ];
}

/// Grouped settings section.
class SettingsSectionModel extends Equatable {
  final String title;
  final List<SettingsItemModel> items;

  const SettingsSectionModel({
    required this.title,
    required this.items,
  });

  @override
  List<Object?> get props => [title, items];
}
