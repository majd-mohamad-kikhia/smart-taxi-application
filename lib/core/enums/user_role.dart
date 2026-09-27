/// The two account kinds the app serves.
///
/// Lives in `core` (rather than the auth feature) because it is a
/// cross-cutting concept: the networking layer needs it to build
/// role-specific endpoints, and other features may need it later to
/// tailor navigation or UI to the signed-in account kind.
enum UserRole {
  rider,
  driver;

  String get label => switch (this) {
        UserRole.rider => 'راكب',
        UserRole.driver => 'كابتن',
      };

  String get description => switch (this) {
        UserRole.rider => 'احجز رحلاتك وتنقّل بسهولة وأمان',
        UserRole.driver => 'انضم كسائق وابدأ استقبال الرحلات',
      };
}
