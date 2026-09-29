import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Circular badge showing an icon that fits a vehicle type.
///
/// Vehicle types are defined by the backend admin (`economy`, `comfort`,
/// `VIP`, …) and the API carries no icon for them, so the icon is chosen
/// from the type's [name] — English or Arabic. An unrecognised name falls
/// back to a taxi.
class VehicleTypeIconWidget extends StatelessWidget {
  final String name;
  final double size;

  const VehicleTypeIconWidget({super.key, required this.name, this.size = 44});

  static final List<_VehicleStyle> _styles = [
    _VehicleStyle(
      RegExp(r'vip|luxury|premium|business|first|فاخر|مميز|اعمال|أعمال'),
      Icons.workspace_premium_rounded,
      AppColors.accent,
    ),
    _VehicleStyle(
      RegExp(r'family|xl|van|bus|suv|group|7 ?seat|عائل|فان|باص|ركاب'),
      Icons.airport_shuttle_rounded,
      AppColors.primary,
    ),
    _VehicleStyle(
      RegExp(r'comfort|plus|مريح|كومفورت'),
      Icons.airline_seat_recline_extra_rounded,
      AppColors.primary,
    ),
    _VehicleStyle(
      RegExp(r'bike|motor|scooter|دراج|موتور|سكوتر'),
      Icons.two_wheeler_rounded,
      AppColors.primary,
    ),
    _VehicleStyle(
      RegExp(r'delivery|cargo|truck|pickup|shipping|شحن|توصيل|نقل|شاحن'),
      Icons.local_shipping_rounded,
      AppColors.primary,
    ),
    _VehicleStyle(
      RegExp(r'economy|eco|standard|basic|اقتصاد|عادي'),
      Icons.directions_car_rounded,
      AppColors.primary,
    ),
  ];

  static final _fallback = _VehicleStyle(
    RegExp(''),
    Icons.local_taxi_rounded,
    AppColors.primary,
  );

  /// The icon [name] maps to — exposed for tests and other pickers.
  static IconData iconFor(String name) => _styleFor(name).icon;

  static _VehicleStyle _styleFor(String name) {
    final normalized = name.toLowerCase();
    for (final style in _styles) {
      if (style.pattern.hasMatch(normalized)) return style;
    }
    return _fallback;
  }

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(name);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(style.icon, color: style.color, size: size * 0.5),
    );
  }
}

class _VehicleStyle {
  final RegExp pattern;
  final IconData icon;
  final Color color;

  _VehicleStyle(this.pattern, this.icon, this.color);
}
