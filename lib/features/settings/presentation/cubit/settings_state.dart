import 'package:equatable/equatable.dart';
import '../../data/models/user_profile_model.dart';

/// Immutable state for the Profile / Settings screen.
class SettingsState extends Equatable {
  final UserProfileModel profile;
  final List<SettingsSectionModel> sections;
  final bool isLoggingOut;

  const SettingsState({
    required this.profile,
    required this.sections,
    required this.isLoggingOut,
  });

  factory SettingsState.initial() {
    return const SettingsState(
      profile: UserProfileModel(
        id: 'u1',
        fullName: 'أحمد بن خالد السبيعي',
        phone: '+966 50 123 4567',
        email: 'ahmed.khalid@domain.com',
        isVerified: true,
        walletBalance: 120,
      ),
      sections: [
        SettingsSectionModel(
          id: 'account',
          items: [SettingsItemModel(id: 'favorites')],
        ),
        SettingsSectionModel(
          id: 'safety',
          items: [
            SettingsItemModel(id: 'support'),
            SettingsItemModel(id: 'terms'),
          ],
        ),
      ],
      isLoggingOut: false,
    );
  }

  SettingsState copyWith({
    UserProfileModel? profile,
    List<SettingsSectionModel>? sections,
    bool? isLoggingOut,
  }) {
    return SettingsState(
      profile: profile ?? this.profile,
      sections: sections ?? this.sections,
      isLoggingOut: isLoggingOut ?? this.isLoggingOut,
    );
  }

  @override
  List<Object?> get props => [
        profile,
        sections,
        isLoggingOut,
      ];
}
