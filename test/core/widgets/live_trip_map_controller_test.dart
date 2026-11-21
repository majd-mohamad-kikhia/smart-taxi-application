import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mshoar/core/widgets/app_map/app_map_controller.dart';
import 'package:mshoar/core/widgets/live_trip_map_controller.dart';
import 'package:mshoar/core/widgets/map_controls_widget.dart';

class _FakeMap extends Fake implements AppMapController {
  int moves = 0;

  @override
  Future<void> animateCamera(CameraUpdate update) async => moves++;

  @override
  Future<void> moveCamera(CameraUpdate update) async => moves++;
}

void main() {
  late LiveTripMapController controller;

  setUp(() {
    controller = LiveTripMapController()
      ..attach(_FakeMap())
      ..updateCar(const LatLng(35.5, 35.8));
  });

  tearDown(() => controller.dispose());

  test('the map reporting its own set-up does not stop the following', () {
    controller.cameraMoveStarted();
    expect(controller.isFollowing, isTrue);
  });

  test('a move the app just made is not the driver dragging', () {
    controller.follow();
    controller.cameraMoveStarted();
    expect(controller.isFollowing, isTrue);
  });

  test('the driver dragging the map stops the following, until he recenters', () async {
    controller.follow();
    await Future<void>.delayed(const Duration(milliseconds: 600));

    controller.cameraMoveStarted();
    expect(controller.isFollowing, isFalse);

    controller.recenter();
    expect(controller.isFollowing, isTrue);
  });

  test('zoom buttons keep following, nudge buttons stop it', () async {
    controller.zoomIn();
    controller.cameraMoveStarted();
    expect(controller.isFollowing, isTrue);

    controller.nudge(MapNudge.up);
    expect(controller.isFollowing, isFalse);
  });
}
