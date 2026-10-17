import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';

/// A small round button floating over a map (zoom, move, recenter, view): an
/// almost-white green fill with a green icon.
///
/// [onTap] runs once, as soon as the button is pressed. With [onHold], keeping
/// the button pressed past [holdDelay] also runs it every [holdInterval]
/// until it is released, for smooth continuous zooming and moving.
class MapControlButtonWidget extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onHold;

  /// Marks the button of the option currently in use.
  final bool selected;

  static const double size = 40;
  static const Duration holdDelay = Duration(milliseconds: 300);
  static const Duration holdInterval = Duration(milliseconds: 16);

  const MapControlButtonWidget({
    super.key,
    required this.icon,
    required this.onTap,
    this.onHold,
    this.selected = false,
  });

  @override
  State<MapControlButtonWidget> createState() => _MapControlButtonWidgetState();
}

class _MapControlButtonWidgetState extends State<MapControlButtonWidget> {
  Timer? _delay;
  Timer? _repeat;

  void _pressed() {
    widget.onTap();
    if (widget.onHold == null) return;
    _delay = Timer(MapControlButtonWidget.holdDelay, () {
      _repeat = Timer.periodic(
        MapControlButtonWidget.holdInterval,
        (_) => widget.onHold?.call(),
      );
    });
  }

  void _released() {
    _delay?.cancel();
    _repeat?.cancel();
    _delay = _repeat = null;
  }

  @override
  void dispose() {
    _released();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: widget.selected ? AppColors.primary : AppColors.mapControlFill,
      shape: CircleBorder(side: BorderSide(color: colors.border)),
      elevation: 3,
      shadowColor: colors.shadowMedium,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {},
        onTapDown: (_) => _pressed(),
        onTapUp: (_) => _released(),
        onTapCancel: _released,
        child: SizedBox(
          width: MapControlButtonWidget.size,
          height: MapControlButtonWidget.size,
          child: Icon(
            widget.icon,
            size: 22,
            color: widget.selected ? Colors.white : AppColors.primary,
          ),
        ),
      ),
    );
  }
}
