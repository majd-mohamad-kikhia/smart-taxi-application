import 'package:equatable/equatable.dart';

/// User profile data shown on the settings screen.
class UserProfileModel extends Equatable {
  final String id;
  final String fullName;
  final String phone;
  final String email;
  final String? photoUrl;
  final bool isVerified;
  final double walletBalance;

  const UserProfileModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    this.photoUrl,
    required this.isVerified,
    required this.walletBalance,
  });

  UserProfileModel copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? email,
    String? photoUrl,
    bool? isVerified,
    double? walletBalance,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      isVerified: isVerified ?? this.isVerified,
      walletBalance: walletBalance ?? this.walletBalance,
    );
  }

  @override
  List<Object?> get props => [
    id,
    fullName,
    phone,
    email,
    photoUrl,
    isVerified,
    walletBalance,
  ];
}

/// A single settings menu row. Its title/subtitle are looked up by [id] in
/// the presentation layer so they follow the active language.
class SettingsItemModel extends Equatable {
  final String id;
  final String? badge;
  final String? trailingAction;
  final bool hasToggle;
  final bool hasChevron;

  const SettingsItemModel({
    required this.id,
    this.badge,
    this.trailingAction,
    this.hasToggle = false,
    this.hasChevron = true,
  });

  @override
  List<Object?> get props => [id, badge, trailingAction, hasToggle, hasChevron];
}

/// Grouped settings section. Its heading is looked up by [id] in the
/// presentation layer so it follows the active language.
class SettingsSectionModel extends Equatable {
  final String id;
  final List<SettingsItemModel> items;

  const SettingsSectionModel({required this.id, required this.items});

  @override
  List<Object?> get props => [id, items];
}
