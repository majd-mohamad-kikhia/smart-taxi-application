import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/theme/app_palette.dart';
import 'package:mshoar/core/widgets/auth_primary_button_widget.dart';

Widget _app(Widget button, {TextDirection direction = TextDirection.ltr}) =>
    MaterialApp(
      theme: ThemeData(extensions: [AppPalette.light]),
      builder: (context, child) =>
          Directionality(textDirection: direction, child: child!),
      home: Scaffold(body: Center(child: button)),
    );

void main() {
  for (final direction in TextDirection.values) {
    testWidgets('is only its label, no arrow or icon ($direction)', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(
          AuthPrimaryButtonWidget(
            label: 'Search',
            isLoading: false,
            onPressed: () => taps++,
          ),
          direction: direction,
        ),
      );

      expect(find.text('Search'), findsOneWidget);
      expect(find.byType(Icon), findsNothing);

      await tester.tap(find.byType(ElevatedButton));
      expect(taps, 1);
    });
  }

  testWidgets('the label is centered in the button', (tester) async {
    await tester.pumpWidget(
      _app(
        AuthPrimaryButtonWidget(
          label: 'Search',
          isLoading: false,
          onPressed: () {},
        ),
      ),
    );

    final button = tester.getCenter(find.byType(ElevatedButton));
    final label = tester.getCenter(find.text('Search'));
    expect(label.dx, closeTo(button.dx, 0.5));
  });

  testWidgets('loading shows a spinner and ignores taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _app(
        AuthPrimaryButtonWidget(
          label: 'Search',
          isLoading: true,
          onPressed: () => taps++,
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Search'), findsNothing);
    await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
    expect(taps, 0);
  });

  testWidgets('without an action it is disabled', (tester) async {
    await tester.pumpWidget(
      _app(
        const AuthPrimaryButtonWidget(
          label: 'Search',
          isLoading: false,
          onPressed: null,
        ),
      ),
    );

    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );
  });
}
