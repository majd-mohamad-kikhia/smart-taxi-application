import 'dart:ui' as ui;
import 'package:flutter/painting.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../theme/app_colors.dart';

/// The top-view yellow taxi used for every live-tracked car on the maps.
///
/// Drawn with a canvas (no bitmap asset), facing north so a flat marker's
/// `rotation` can point it along the direction of travel. The icon is
/// rendered once and shared by all maps.
class TaxiMarkerIcon {
  TaxiMarkerIcon._();

  static const double _logicalWidth = 28;
  static const double _logicalHeight = 56;
  static const double _renderScale = 4;

  static Future<BitmapDescriptor>? _icon;

  static Future<BitmapDescriptor> load() => _icon ??= _render();

  static Future<BitmapDescriptor> _render() async {
    const width = _logicalWidth * _renderScale;
    const height = _logicalHeight * _renderScale;

    final recorder = ui.PictureRecorder();
    _paintTaxi(Canvas(recorder), const Size(width, height));
    final image = await recorder.endRecording().toImage(width.round(), height.round());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      width: _logicalWidth,
      height: _logicalHeight,
    );
  }

  static void _paintTaxi(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    Rect box(double l, double t, double r, double b) => Rect.fromLTRB(l * w, t * h, r * w, b * h);
    RRect round(Rect rect, double radius) => RRect.fromRectAndRadius(rect, Radius.circular(radius * w));

    final fill = Paint()..style = PaintingStyle.fill;
    final body = round(box(0.10, 0.03, 0.90, 0.97), 0.26);

    // Soft drop shadow so the car lifts off the dark map.
    canvas.drawRRect(
      body.shift(Offset(0, 0.012 * h)),
      fill..color = AppColors.black.withValues(alpha: 0.35),
    );

    // Body and outline.
    canvas.drawRRect(body, fill..color = AppColors.primaryYellow);
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.05 * w
        ..color = AppColors.darkGray,
    );

    // Side mirrors.
    fill.color = AppColors.darkGray;
    canvas.drawRRect(round(box(0.01, 0.27, 0.12, 0.33), 0.05), fill);
    canvas.drawRRect(round(box(0.88, 0.27, 0.99, 0.33), 0.05), fill);

    // Windscreen, roof, rear window.
    final windscreen = Path()
      ..moveTo(0.22 * w, 0.26 * h)
      ..quadraticBezierTo(0.5 * w, 0.20 * h, 0.78 * w, 0.26 * h)
      ..lineTo(0.82 * w, 0.40 * h)
      ..lineTo(0.18 * w, 0.40 * h)
      ..close();
    canvas.drawPath(windscreen, fill..color = AppColors.darkGray);
    canvas.drawRect(box(0.18, 0.40, 0.82, 0.62), fill..color = AppColors.orangeGold);
    canvas.drawRRect(round(box(0.20, 0.62, 0.80, 0.74), 0.08), fill..color = AppColors.darkGray);

    // Taxi sign on the roof.
    canvas.drawRRect(round(box(0.33, 0.47, 0.67, 0.55), 0.06), fill..color = AppColors.white);

    // Headlights and tail lights.
    fill.color = AppColors.white;
    canvas.drawRRect(round(box(0.17, 0.045, 0.37, 0.085), 0.04), fill);
    canvas.drawRRect(round(box(0.63, 0.045, 0.83, 0.085), 0.04), fill);
    fill.color = AppColors.error;
    canvas.drawRRect(round(box(0.17, 0.915, 0.37, 0.955), 0.04), fill);
    canvas.drawRRect(round(box(0.63, 0.915, 0.83, 0.955), 0.04), fill);
  }
}
