// import 'dart:async';
// import 'package:flutter/widgets.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:mshoar/core/floating_bubble/data/floating_bubble_overlay.dart';
// import 'package:mshoar/core/floating_bubble/data/floating_bubble_store.dart';
// import 'package:mshoar/core/floating_bubble/floating_bubble_coordinator.dart';

// class _FakeOverlay extends FloatingBubbleOverlay {
//   final tapController = StreamController<void>.broadcast();
//   bool permitted = true;
//   int shown = 0;
//   int closed = 0;
//   int broughtToFront = 0;

//   @override
//   Future<bool> hasPermission() async => permitted;

//   @override
//   Future<void> show() async => shown++;

//   @override
//   Future<void> close() async => closed++;

//   @override
//   Future<void> bringAppToFront() async => broughtToFront++;

//   @override
//   Stream<void> get taps => tapController.stream;
// }

// class _FakeStore extends FloatingBubbleStore {
//   bool enabled = true;

//   @override
//   Future<bool> isEnabled() async => enabled;
// }

// void main() {
//   late _FakeOverlay overlay;
//   late _FakeStore store;
//   late FloatingBubbleCoordinator coordinator;

//   setUp(() {
//     overlay = _FakeOverlay();
//     store = _FakeStore();
//     coordinator = FloatingBubbleCoordinator(overlay, store)..start();
//   });

//   tearDown(() async {
//     await coordinator.stop();
//   });

//   test('shows the bubble when the driver leaves the app, online or not', () async {
//     await coordinator.onLifecycleChanged(AppLifecycleState.paused);
//     expect(overlay.shown, 1);
//   });

//   test('shows it once however often the app is paused', () async {
//     await coordinator.onLifecycleChanged(AppLifecycleState.paused);
//     await coordinator.onLifecycleChanged(AppLifecycleState.paused);
//     expect(overlay.shown, 1);
//   });

//   test('shows nothing when the switch is off or the permission is missing', () async {
//     store.enabled = false;
//     await coordinator.onLifecycleChanged(AppLifecycleState.paused);
//     store.enabled = true;
//     overlay.permitted = false;
//     await coordinator.onLifecycleChanged(AppLifecycleState.paused);
//     expect(overlay.shown, 0);
//   });

//   test('closes the bubble when the app comes back', () async {
//     await coordinator.onLifecycleChanged(AppLifecycleState.paused);
//     await coordinator.onLifecycleChanged(AppLifecycleState.resumed);
//     expect(overlay.closed, 1);
//   });

//   test('a notification shade pull (inactive) does not show the bubble', () async {
//     await coordinator.onLifecycleChanged(AppLifecycleState.inactive);
//     expect(overlay.shown, 0);
//   });

//   test('a tap brings the app back and closes the bubble', () async {
//     await coordinator.onLifecycleChanged(AppLifecycleState.paused);
//     overlay.tapController.add(null);
//     await Future<void>.delayed(Duration.zero);
//     expect(overlay.broughtToFront, 1);
//     expect(overlay.closed, 1);
//   });

//   test('can be stopped and started again (logout, login)', () async {
//     await coordinator.stop();
//     coordinator.start();
//     await coordinator.onLifecycleChanged(AppLifecycleState.paused);
//     expect(overlay.shown, 1);
//   });
// }
