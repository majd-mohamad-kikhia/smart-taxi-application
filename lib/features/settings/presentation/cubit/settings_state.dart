import 'package:equatable/equatable.dart';
import '../../data/models/user_profile_model.dart';

/// Immutable state for the Profile / Settings screen.
class SettingsState extends Equatable {
  final UserProfileModel profile;
  final List<SettingsSectionModel> sections;
  final bool notificationsEnabled;
  final String languageLabel;
  final String themeLabel;
  final bool isLoggingOut;

  const SettingsState({
    required this.profile,
    required this.sections,
    required this.notificationsEnabled,
    required this.languageLabel,
    required this.themeLabel,
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
              id: 'payments',
              title: 'طرق الدفع والبطاقات',
              subtitle: 'Apple Pay، مدى، Visa تنتهي بـ 4022',
            ),
            SettingsItemModel(
              id: 'favorites',
              title: 'الأماكن المفضلة والمحفوظة',
              subtitle: 'المنزل، العمل، استراحة (3 مواقع)',
            ),
          ],
        ),
        SettingsSectionModel(
          title: 'تفضيلات التطبيق',
          items: [
            SettingsItemModel(
              id: 'notifications',
              title: 'الإشعارات والتنبيهات',
              subtitle: 'حالة الرحلة، عروض مشوار',
              hasToggle: true,
              hasChevron: false,
            ),
            SettingsItemModel(
              id: 'language',
              title: 'لغة التطبيق',
              subtitle: 'العربية (السعودية)',
              trailingAction: 'تغيير',
              hasChevron: false,
            ),
            SettingsItemModel(
              id: 'theme',
              title: 'المظهر والسمة',
              subtitle: 'الوضع الفاتح الافتراضي',
            ),
          ],
        ),
        SettingsSectionModel(
          title: 'الأمان والدعم',
          items: [
            SettingsItemModel(
              id: 'safety',
              title: 'مركز الأمان والطوارئ',
              subtitle: 'مشاركة المسار تلقائياً',
              badge: 'مفعل',
            ),
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
      notificationsEnabled: true,
      languageLabel: 'العربية (السعودية)',
      themeLabel: 'الوضع الفاتح الافتراضي',
      isLoggingOut: false,
    );
  }

  SettingsState copyWith({
    UserProfileModel? profile,
    List<SettingsSectionModel>? sections,
    bool? notificationsEnabled,
    String? languageLabel,
    String? themeLabel,
    bool? isLoggingOut,
  }) {
    return SettingsState(
      profile: profile ?? this.profile,
      sections: sections ?? this.sections,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      languageLabel: languageLabel ?? this.languageLabel,
      themeLabel: themeLabel ?? this.themeLabel,
      isLoggingOut: isLoggingOut ?? this.isLoggingOut,
    );
  }

  @override
  List<Object?> get props => [
        profile,
        sections,
        notificationsEnabled,
        languageLabel,
        themeLabel,
        isLoggingOut,
      ];
}
