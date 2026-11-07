import 'package:flutter/foundation.dart';
import '../services/map_backend.dart';
import 'map_provider_remote_data_source.dart';

/// Keeps [MapBackend] in step with the map the manager picked in the
/// dashboard. Asked at launch and whenever the app returns to the
/// foreground. A failed call changes nothing: the app keeps drawing what it
/// drew before (Google when it never heard from the server).
class MapProviderService {
  final MapProviderRemoteDataSource _remote;
  Future<void>? _inFlight;

  MapProviderService(this._remote);

  /// The call in progress, if any; completes at once when there is none.
  Future<void> get pending => _inFlight ?? Future<void>.value();

  Future<void> refresh() {
    return _inFlight ??= _load().whenComplete(() => _inFlight = null);
  }

  Future<void> _load() async {
    try {
      final provider = await _remote.fetchProvider();
      if (provider == 'osm') {
        MapBackend.useOsm.value = true;
      } else if (provider == 'google') {
        MapBackend.useOsm.value = false;
      }
    } catch (e) {
      debugPrint('MapProviderService: keeping the current map ($e)');
    }
  }
}
