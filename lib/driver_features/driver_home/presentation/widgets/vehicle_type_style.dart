import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// The colour and icon a car type is drawn with on an order card, so the
/// driver tells the types apart by sight before reading the name.
///
/// The manager writes the names, so the four known kinds are recognised by
/// their wording (platinum / VIP, private tourist, public tourist, economy);
/// any other name gets a stable colour of its own from its id.
class VehicleTypeStyle {
  final Color background;
  final Color foreground;
  final IconData icon;

  const VehicleTypeStyle(this.background, this.foreground, this.icon);

  // Yellow and orange take dark text (white on them is under 3:1); blue and
  // red take white.
  static const _vip = VehicleTypeStyle(
    Color(0xFFDC2626),
    Colors.white,
    Icons.workspace_premium_rounded,
  );
  static const _privateTourist = VehicleTypeStyle(
    Color(0xFF2563EB),
    Colors.white,
    Icons.airport_shuttle_rounded,
  );
  static const _publicTourist = VehicleTypeStyle(
    Color(0xFFF97316),
    AppColors.textOnWarning,
    Icons.tour_rounded,
  );
  static const _economy = VehicleTypeStyle(
    Color(0xFFFACC15),
    AppColors.textOnWarning,
    Icons.local_taxi_rounded,
  );

  /// For a type that is none of the four: one colour per id, always the same.
  static const _others = [
    VehicleTypeStyle(Color(0xFF0F766E), Colors.white, Icons.directions_car_rounded),
    VehicleTypeStyle(Color(0xFF7C3AED), Colors.white, Icons.directions_car_rounded),
    VehicleTypeStyle(Color(0xFFDB2777), Colors.white, Icons.directions_car_rounded),
    VehicleTypeStyle(Color(0xFF475569), Colors.white, Icons.directions_car_rounded),
  ];

  static VehicleTypeStyle of({required String name, required int typeId}) {
    final n = name.toLowerCase();
    if (n.contains('vip') || n.contains('بلاتين')) return _vip;
    final tourist = n.contains('سياح');
    if (tourist && n.contains('خاص')) return _privateTourist;
    if (tourist) return _publicTourist;
    if (n.contains('اقتصاد') || n.contains('economy')) return _economy;
    return _others[typeId.abs() % _others.length];
  }
}
