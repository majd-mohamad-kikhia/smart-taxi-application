import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/widgets/app_snack_bar_widget.dart';

void main() {
  testWidgets('the snack bar goes away by itself', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showAppSnackBar(context, 'GPS off', type: AppSnackBarType.warning),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('GPS off'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('GPS off'), findsNothing);
  });

  testWidgets('shown from a pushed screen it goes away by itself too', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => Scaffold(
                    body: TextButton(
                      onPressed: () => showAppSnackBar(context, 'GPS off', type: AppSnackBarType.warning),
                      child: const Text('locate'),
                    ),
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('locate'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('GPS off'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('GPS off'), findsNothing);
  });

  testWidgets('tapping again while it shows replaces it, and the new one goes away', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showAppSnackBar(context, 'GPS off', type: AppSnackBarType.warning),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('go'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('go'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('go'));
    await tester.pump(const Duration(seconds: 1));

    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(seconds: 6));
    expect(find.text('GPS off'), findsNothing);
  });
}
