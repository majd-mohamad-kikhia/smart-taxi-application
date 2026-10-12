import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The Google Maps style that goes with a theme: the dark style (a bundled
/// JSON, read once for the whole app) in the dark theme, and Google's default
/// map in the light one.
class AppMapStyle {
  AppMapStyle._();

  static const _darkAsset = 'assets/map_styles/dark_map_style.json';
  static Future<String>? _dark;

  /// The style JSON for [brightness]; null means the default (light) map.
  static Future<String?> forBrightness(Brightness brightness) async {
    if (brightness == Brightness.light) return null;
    return _dark ??= rootBundle.loadString(_darkAsset);
  }
}

/// For the state of a widget that shows a `GoogleMap`: keeps [mapStyle] in
/// step with the active theme (loaded when the widget appears and again when
/// the theme changes), repainting the map when it does. Pass [mapStyle] to
/// `GoogleMap(style: …)`. [mapStyleReady] is false until the first style has
/// been resolved — for a map that must not be built before it.
mixin MapStyleMixin<T extends StatefulWidget> on State<T> {
  String? mapStyle;
  bool mapStyleReady = false;
  Brightness? _styleFor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMapStyle();
  }

  Future<void> _syncMapStyle() async {
    final brightness = Theme.of(context).brightness;
    if (_styleFor == brightness) return;
    _styleFor = brightness;
    final style = await AppMapStyle.forBrightness(brightness);
    if (!mounted || _styleFor != brightness) return;
    setState(() {
      mapStyle = style;
      mapStyleReady = true;
    });
  }
}
