import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/widgets/size_reporter_widget.dart';

void main() {
  testWidgets('reports the size, and again when the child changes by itself', (
    tester,
  ) async {
    final heights = ValueNotifier<double>(40);
    final reported = <Size>[];
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizeReporterWidget(
            onSize: reported.add,
            // The height changes without the reporter being rebuilt.
            child: ValueListenableBuilder<double>(
              valueListenable: heights,
              builder: (_, height, _) => SizedBox(width: 100, height: height),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(reported, [const Size(100, 40)]);

    heights.value = 90;
    await tester.pump();
    await tester.pump();

    expect(reported, [const Size(100, 40), const Size(100, 90)]);
  });

  testWidgets('says nothing again while the size stays the same', (
    tester,
  ) async {
    final reported = <Size>[];
    Widget app() => Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topLeft,
        child: SizeReporterWidget(
          onSize: reported.add,
          child: const SizedBox(width: 50, height: 20),
        ),
      ),
    );
    await tester.pumpWidget(app());
    await tester.pump();
    await tester.pumpWidget(app());
    await tester.pump();

    expect(reported, [const Size(50, 20)]);
  });
}
