import '../l10n/generated/app_localizations.dart';

/// The two account kinds the app serves.
///
/// Lives in `core` (rather than the auth feature) because it is a
/// cross-cutting concept: the networking layer needs it to build
/// role-specific endpoints, and other features may need it later to
/// tailor navigation or UI to the signed-in account kind.
enum UserRole {
  customer,
  driver;

  String label(AppLocalizations l10n) => switch (this) {
        UserRole.customer => l10n.roleCustomer,
        UserRole.driver => l10n.roleDriver,
      };

  String description(AppLocalizations l10n) => switch (this) {
        UserRole.customer => l10n.roleCustomerDescription,
        UserRole.driver => l10n.roleDriverDescription,
      };
}
