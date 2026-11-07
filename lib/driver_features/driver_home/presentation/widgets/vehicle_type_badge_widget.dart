import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import 'vehicle_type_style.dart';

/// The car type the customer asked for ("اقتصادي", "بلاتينيوم"…), on its own
/// line at the top of an order card. A solid badge, big and bold so it reads
/// at a glance; each type has its own colour and icon ([VehicleTypeStyle]).
class VehicleTypeBadgeWidget extends StatelessWidget {
  final String name;
  final int typeId;

  const VehicleTypeBadgeWidget({super.key, required this.name, required this.typeId});

  @override
  Widget build(BuildContext context) {
    final style = VehicleTypeStyle.of(name: name, typeId: typeId);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 22, color: style.foreground),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: style.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
