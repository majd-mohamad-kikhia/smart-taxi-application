import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/widgets/marquee_text_widget.dart';

const _long = 'abcdefghijklmnopqrstuvwxyz'; // 260 px at the test font's 10 px

Widget _app(
  String text, {
  double width = 100,
  TextDirection direction = TextDirection.ltr,
  bool reduceMotion = false,
}) => Directionality(
  textDirection: direction,
  child: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: DefaultTextStyle(
      style: const TextStyle(fontSize: 10),
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: SizedBox(
          width: width,
          child: MarqueeTextWidget(text: text),
        ),
      ),
    ),
  ),
);

double _shift(WidgetTester tester) {
  final transform = tester.widget<Transform>(
    find.descendant(
      of: find.byType(MarqueeTextWidget),
      matching: find.byType(Transform),
    ),
  );
  return transform.transform.getTranslation().x;
}

/// Builds, and lets the marquee start.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
}

void main() {
  group('text that fits', () {
    testWidgets('is a plain line: nothing animates, nothing slides', (
      tester,
    ) async {
      await tester.pumpWidget(_app('abc'));
      await _settle(tester);

      expect(find.text('abc'), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
      expect(
        find.descendant(
          of: find.byType(MarqueeTextWidget),
          matching: find.byType(Transform),
        ),
        findsNothing,
      );
    });

    testWidgets('exactly as wide as its space still just fits', (tester) async {
      await tester.pumpWidget(_app('abcdefghij', width: 100));
      await _settle(tester);

      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('text that is too long', () {
    testWidgets('keeps the whole text, clipped to its space, and animates', (
      tester,
    ) async {
      await tester.pumpWidget(_app(_long));
      await _settle(tester);

      expect(find.text(_long), findsOneWidget);
      expect(tester.hasRunningAnimations, isTrue);
      final clip = tester.getSize(
        find.descendant(
          of: find.byType(MarqueeTextWidget),
          matching: find.byType(ClipRect),
        ),
      );
      expect(clip.width, 100);
    });

    testWidgets('rests, slides to the end, rests, and slides back', (
      tester,
    ) async {
      await tester.pumpWidget(_app(_long));
      await _settle(tester);

      // Resting at the start.
      expect(_shift(tester), 0);

      // About 170 px to cover (the line is 260 px plus its letter spacing, in
      // 100 px), plus a small gap, at 36 px a second.
      var furthest = 0.0;
      var wentBack = false;
      var last = 0.0;
      for (var i = 0; i < 400; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        final shift = _shift(tester);
        expect(
          shift,
          lessThanOrEqualTo(0),
          reason: 'left-to-right slides left',
        );
        if (shift < furthest) furthest = shift;
        if (shift > last && furthest < -100) wentBack = true;
        last = shift;
      }

      expect(
        furthest,
        lessThan(-150),
        reason: 'the end of the text came into view',
      );
      expect(furthest, greaterThan(-170), reason: 'and no further than that');
      expect(wentBack, isTrue);
    });

    testWidgets('slides toward the end of an Arabic line: to the right', (
      tester,
    ) async {
      await tester.pumpWidget(_app(_long, direction: TextDirection.rtl));
      await _settle(tester);

      var furthest = 0.0;
      for (var i = 0; i < 100; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        final shift = _shift(tester);
        expect(shift, greaterThanOrEqualTo(0));
        if (shift > furthest) furthest = shift;
      }
      expect(furthest, greaterThan(100));
    });

    testWidgets('stays still when the system asks for reduced motion', (
      tester,
    ) async {
      await tester.pumpWidget(_app(_long, reduceMotion: true));
      await _settle(tester);

      expect(tester.hasRunningAnimations, isFalse);
      expect(find.text(_long), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(MarqueeTextWidget),
          matching: find.byType(Transform),
        ),
        findsNothing,
      );
    });
  });

  group('when things change', () {
    testWidgets('a text that becomes short stops the animation', (
      tester,
    ) async {
      await tester.pumpWidget(_app(_long));
      await _settle(tester);
      expect(tester.hasRunningAnimations, isTrue);

      await tester.pumpWidget(_app('abc'));
      await _settle(tester);

      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('a text that becomes long starts it', (tester) async {
      await tester.pumpWidget(_app('abc'));
      await _settle(tester);
      expect(tester.hasRunningAnimations, isFalse);

      await tester.pumpWidget(_app(_long));
      await _settle(tester);

      expect(tester.hasRunningAnimations, isTrue);
    });

    testWidgets('more room can make the text fit', (tester) async {
      await tester.pumpWidget(_app(_long, width: 100));
      await _settle(tester);
      expect(tester.hasRunningAnimations, isTrue);

      await tester.pumpWidget(_app(_long, width: 400));
      await _settle(tester);

      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('leaving the screen disposes it without a trace', (
      tester,
    ) async {
      await tester.pumpWidget(_app(_long));
      await _settle(tester);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));

      expect(tester.takeException(), isNull);
    });
  });
}
