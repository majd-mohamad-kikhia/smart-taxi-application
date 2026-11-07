import 'package:flutter/widgets.dart';
import 'map_provider_service.dart';

/// Asks the server which map to draw each time the app comes back to the
/// foreground.
class MapProviderRefresherWidget extends StatefulWidget {
  final MapProviderService service;
  final Widget child;

  const MapProviderRefresherWidget({
    super.key,
    required this.service,
    required this.child,
  });

  @override
  State<MapProviderRefresherWidget> createState() =>
      _MapProviderRefresherWidgetState();
}

class _MapProviderRefresherWidgetState extends State<MapProviderRefresherWidget>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) widget.service.refresh();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
