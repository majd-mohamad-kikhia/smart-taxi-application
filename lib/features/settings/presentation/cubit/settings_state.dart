import 'package:equatable/equatable.dart';
import '../../data/models/user_profile_model.dart';

class SettingsState extends Equatable {
  final UserProfileModel profile;
  final bool isLoggingOut;

  const SettingsState({required this.profile, required this.isLoggingOut});

  factory SettingsState.initial() {
    return const SettingsState(
      profile: UserProfileModel(
        id: 'u1',
        fullName: 'أحمد بن خالد السبيعي',
        phone: '+966 50 123 4567',
        email: 'ahmed.khalid@domain.com',
        isVerified: true,
      ),
      isLoggingOut: false,
    );
  }

  SettingsState copyWith({UserProfileModel? profile, bool? isLoggingOut}) {
    return SettingsState(
      profile: profile ?? this.profile,
      isLoggingOut: isLoggingOut ?? this.isLoggingOut,
    );
  }

  @override
  List<Object?> get props => [profile, isLoggingOut];
}
