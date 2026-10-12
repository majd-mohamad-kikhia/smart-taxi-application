import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/splash/splash_signal.dart';
import 'package:mshoar/core/widgets/app_splash_widget.dart';
import 'package:mshoar/core/widgets/splash_video_widget.dart';

void main() {
  group('SplashSignal', () {
    test(
      'is not finished until it is told, and finishing twice is fine',
      () async {
        final signal = SplashSignal();
        expect(signal.isFinished, isFalse);

        var done = false;
        signal.finished.then((_) => done = true);
        await Future<void>.delayed(Duration.zero);
        expect(done, isFalse);

        signal
          ..finish()
          ..finish();
        await Future<void>.delayed(Duration.zero);
        expect(done, isTrue);
        expect(signal.isFinished, isTrue);
      },
    );
  });

  group('SplashVideoWidget', () {
    testWidgets(
      'a video that cannot play finishes the splash and shows the logo splash',
      (tester) async {
        // No video platform exists in tests, so the player fails to start.
        final signal = SplashSignal();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: SplashVideoWidget(signal: signal)),
          ),
        );
        await tester.pumpAndSettle();

        expect(signal.isFinished, isTrue);
        expect(find.byType(AppSplashWidget), findsOneWidget);
      },
    );

    testWidgets('a tap skips the video', (tester) async {
      final signal = SplashSignal();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SplashVideoWidget(signal: signal)),
        ),
      );
      // Before the failed start has been processed, the splash is waiting.
      await tester.tap(find.byType(SplashVideoWidget), warnIfMissed: false);
      expect(signal.isFinished, isTrue);
      await tester.pumpAndSettle();
    });

    test('the video is a declared asset', () {
      expect(SplashVideoWidget.asset, 'assets/videos/splash.mp4');
    });
  });
}
