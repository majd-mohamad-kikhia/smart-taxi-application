import 'package:flutter/foundation.dart';

/// Which map the app draws, as the server says (`GET /api/app/map-provider`).
/// Google Maps until the server says `osm`; `AppMapWidget` listens to
/// [useOsm] and swaps maps when it changes. Set only by `MapProviderService`.
class MapBackend {
  MapBackend._();

  static final ValueNotifier<bool> useOsm = ValueNotifier<bool>(false);
}
