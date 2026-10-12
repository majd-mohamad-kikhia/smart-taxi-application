import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/widgets/entrance_animation_widget.dart';
import 'package:mshoar/core/widgets/paginated_list_widget.dart';

double _opacityOf(WidgetTester tester, Finder child) => tester
    .widget<Opacity>(
      find.ancestor(of: child, matching: find.byType(Opacity)).first,
    )
    .opacity;

Widget _host(Widget child, {bool disableAnimations = false}) => MediaQuery(
  data: MediaQueryData(disableAnimations: disableAnimations),
  child: Directionality(textDirection: TextDirection.ltr, child: child),
);

void main() {
  testWidgets(
    'a row starts hidden, then fades in to full and settles in place',
    (tester) async {
      await tester.pumpWidget(
        _host(const EntranceAnimationWidget(child: Text('row'))),
      );
      expect(_opacityOf(tester, find.text('row')), lessThan(0.05));

      await tester.pump(const Duration(milliseconds: 200));
      final mid = _opacityOf(tester, find.text('row'));
      expect(mid, greaterThan(0.05));
      expect(mid, lessThan(1));

      await tester.pumpAndSettle();
      expect(_opacityOf(tester, find.text('row')), 1);
      final offset = tester.widget<Transform>(
        find
            .ancestor(of: find.text('row'), matching: find.byType(Transform))
            .first,
      );
      expect(offset.transform.getTranslation().y, 0);
    },
  );

  testWidgets('the first rows follow one another', (tester) async {
    await tester.pumpWidget(
      _host(
        const Column(
          children: [
            EntranceAnimationWidget(index: 0, child: Text('a')),
            EntranceAnimationWidget(index: 3, child: Text('b')),
          ],
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 150));
    expect(
      _opacityOf(tester, find.text('a')),
      greaterThan(_opacityOf(tester, find.text('b'))),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('rows past the staggered ones do not wait', (tester) async {
    await tester.pumpWidget(
      _host(
        const Column(
          children: [
            EntranceAnimationWidget(index: 0, child: Text('first')),
            EntranceAnimationWidget(index: 30, child: Text('late')),
          ],
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      _opacityOf(tester, find.text('late')),
      closeTo(_opacityOf(tester, find.text('first')), 0.001),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('play: false, or reduced motion, shows the row at once', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const EntranceAnimationWidget(play: false, child: Text('row'))),
    );
    expect(_opacityOf(tester, find.text('row')), 1);

    await tester.pumpWidget(
      _host(
        const EntranceAnimationWidget(key: Key('b'), child: Text('row')),
        disableAnimations: true,
      ),
    );
    expect(_opacityOf(tester, find.text('row')), 1);
  });

  testWidgets('a rebuild of the same row does not restart it', (tester) async {
    Widget row(String text) =>
        _host(EntranceAnimationWidget(child: Text(text)));
    await tester.pumpWidget(row('one'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(row('two'));
    expect(_opacityOf(tester, find.text('two')), 1);
  });

  group('PaginatedListWidget.animateItems', () {
    Widget list({required bool animate, List<int> items = const [1, 2, 3]}) =>
        MaterialApp(
          home: Scaffold(
            body: PaginatedListWidget<int>(
              items: items,
              animateItems: animate,
              itemBuilder: (_, item, _) =>
                  SizedBox(height: 80, child: Text('item $item')),
            ),
          ),
        );

    testWidgets('rows fade in when animating, and are shown at once when not', (
      tester,
    ) async {
      await tester.pumpWidget(list(animate: true));
      expect(find.byType(EntranceAnimationWidget), findsNWidgets(3));
      expect(_opacityOf(tester, find.text('item 3')), lessThan(0.05));
      await tester.pumpAndSettle();
      expect(_opacityOf(tester, find.text('item 3')), 1);

      await tester.pumpWidget(list(animate: false, items: const [7]));
      await tester.pumpAndSettle();
      expect(find.byType(EntranceAnimationWidget), findsNothing);
    });

    testWidgets('a row scrolled away and back does not play again', (
      tester,
    ) async {
      await tester.pumpWidget(
        list(animate: true, items: List.generate(30, (i) => i)),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -2000));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, 2000));
      await tester.pump();

      expect(_opacityOf(tester, find.text('item 0')), 1);
      await tester.pumpAndSettle();
    });
  });
}
