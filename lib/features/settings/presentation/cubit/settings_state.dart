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
          title: 'الحساب والمدفوعات',
          items: [
            SettingsItemModel(
              id: 'favorites',
              title: 'الأماكن المفضلة والمحفوظة',
              subtitle: 'المنزل، العمل، استراحة (3 مواقع)',
            ),
          ],
        ),
        SettingsSectionModel(
          title: 'الأمان والدعم',
          items: [
            SettingsItemModel(
              id: 'support',
              title: 'المساعدة والدعم الفني',
              subtitle: 'محادثة مباشرة أو اتصال على مدار الساعة',
            ),
            SettingsItemModel(
              id: 'terms',
              title: 'الشروط والخصوصية',
              subtitle: 'سياسة الاستخدام وحماية البيانات',
            ),
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
