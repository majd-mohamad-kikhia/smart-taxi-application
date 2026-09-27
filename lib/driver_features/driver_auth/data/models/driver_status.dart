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

  String get label => switch (this) {
        DriverStatus.pending => 'قيد المراجعة',
        DriverStatus.active => 'نشط',
        DriverStatus.suspended => 'موقوف',
        DriverStatus.rejected => 'مرفوض',
      };
}
