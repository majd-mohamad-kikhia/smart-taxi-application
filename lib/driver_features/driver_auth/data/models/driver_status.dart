import '../../../../core/l10n/generated/app_localizations.dart';

/// Driver account status — mirrors `Driver.status_id` in swagger.json.
enum DriverStatus {
  pending,
  active,
  suspended,
  rejected;

  static DriverStatus fromId(int id) => switch (id) {
        1 => DriverStatus.pending,
        2 => DriverStatus.active,
        3 => DriverStatus.suspended,
        4 => DriverStatus.rejected,
        _ => DriverStatus.pending,
      };

  String label(AppLocalizations l10n) => switch (this) {
        DriverStatus.pending => l10n.driverStatusPending,
        DriverStatus.active => l10n.driverStatusActive,
        DriverStatus.suspended => l10n.driverStatusSuspended,
        DriverStatus.rejected => l10n.driverStatusRejected,
      };
}
