import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/routing/app_router.dart';
import 'package:mshoar/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MshoarApp(initialRoute: AppRouter.roleSelection),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
