import 'package:flutter/material.dart';
import 'live_trip_map_controller.dart';
import 'map_control_button_widget.dart';

/// Helper buttons over a map, laid out in one row: on the left the four
/// arrows that nudge the view up, down, left and right; on the right the
/// zoom in / out buttons (and, only when [onRecenter] is given, a button that
/// brings the view back to where it was following). With [onViewChanged],
/// two more buttons switch between the top-down and the angled look.
///
/// Zoom and arrow buttons keep acting while held when the matching `*Hold`
/// callback is given.
///
/// The arrows are real map directions and the sides are physical, so the
/// layout is the same in right-to-left languages.
class MapControlsWidget extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final ValueChanged<MapNudge> onNudge;
  final VoidCallback? onZoomInHold;
  final VoidCallback? onZoomOutHold;
  final ValueChanged<MapNudge>? onNudgeHold;
  final VoidCallback? onRecenter;

  /// False hides the four arrows (the view is locked on the car).
  final bool showArrows;
  final TripMapView view;
  final ValueChanged<TripMapView>? onViewChanged;

  const MapControlsWidget({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onNudge,
    this.onZoomInHold,
    this.onZoomOutHold,
    this.onNudgeHold,
    this.onRecenter,
    this.showArrows = true,
    this.view = TripMapView.topDown,
    this.onViewChanged,
  });

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 8);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: showArrows
            ? MainAxisAlignment.spaceBetween
            : MainAxisAlignment.end,
        children: [
          if (showArrows)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _arrow(Icons.keyboard_arrow_up_rounded, MapNudge.up),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _arrow(Icons.keyboard_arrow_left_rounded, MapNudge.left),
                    const SizedBox(width: MapControlButtonWidget.size),
                    _arrow(Icons.keyboard_arrow_right_rounded, MapNudge.right),
                  ],
                ),
                const SizedBox(height: 4),
                _arrow(Icons.keyboard_arrow_down_rounded, MapNudge.down),
              ],
            ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onViewChanged != null) ...[
                MapControlButtonWidget(
                  icon: Icons.map_rounded,
                  selected: view == TripMapView.topDown,
                  onTap: () => onViewChanged!(TripMapView.topDown),
                ),
                gap,
                MapControlButtonWidget(
                  icon: Icons.navigation_rounded,
                  selected: view == TripMapView.angled,
                  onTap: () => onViewChanged!(TripMapView.angled),
                ),
                gap,
              ],
              if (onRecenter != null) ...[
                MapControlButtonWidget(
                  icon: Icons.my_location_rounded,
                  onTap: onRecenter!,
                ),
                gap,
              ],
              MapControlButtonWidget(
                icon: Icons.add_rounded,
                onTap: onZoomIn,
                onHold: onZoomInHold,
              ),
              gap,
              MapControlButtonWidget(
                icon: Icons.remove_rounded,
                onTap: onZoomOut,
                onHold: onZoomOutHold,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _arrow(IconData icon, MapNudge nudge) => MapControlButtonWidget(
    icon: icon,
    onTap: () => onNudge(nudge),
    onHold: onNudgeHold == null ? null : () => onNudgeHold!(nudge),
  );
}

/// A small step of the map view, in screen directions.
enum MapNudge {
  up(Offset(0, -1)),
  down(Offset(0, 1)),
  left(Offset(-1, 0)),
  right(Offset(1, 0));

  /// Unit step on screen: x grows to the right, y grows downwards.
  final Offset direction;

  const MapNudge(this.direction);
}
