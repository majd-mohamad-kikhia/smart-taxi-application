import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';

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
      isAccent: true,
    ),
    _VehicleStyle(
      RegExp(r'family|xl|van|bus|suv|group|7 ?seat|عائل|فان|باص|ركاب'),
      Icons.airport_shuttle_rounded,
    ),
    _VehicleStyle(
      RegExp(r'comfort|plus|مريح|كومفورت'),
      Icons.airline_seat_recline_extra_rounded,
    ),
    _VehicleStyle(
      RegExp(r'bike|motor|scooter|دراج|موتور|سكوتر'),
      Icons.two_wheeler_rounded,
    ),
    _VehicleStyle(
      RegExp(r'delivery|cargo|truck|pickup|shipping|شحن|توصيل|نقل|شاحن'),
      Icons.local_shipping_rounded,
    ),
    _VehicleStyle(
      RegExp(r'economy|eco|standard|basic|اقتصاد|عادي'),
      Icons.directions_car_rounded,
    ),
  ];

  static final _fallback = _VehicleStyle(RegExp(''), Icons.local_taxi_rounded);

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
    // The accent for premium types; otherwise the brand green, deepened on
    // the light theme so it reads on white.
    final color = style.isAccent
        ? AppColors.accent
        : context.colors.primaryContent;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(style.icon, color: color, size: size * 0.5),
    );
  }
}

class _VehicleStyle {
  final RegExp pattern;
  final IconData icon;
  final bool isAccent;

  _VehicleStyle(this.pattern, this.icon, {this.isAccent = false});
}
