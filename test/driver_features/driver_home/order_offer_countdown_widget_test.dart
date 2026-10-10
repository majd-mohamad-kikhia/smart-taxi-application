import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/l10n/generated/app_localizations.dart';
import 'package:mshoar/driver_features/driver_home/presentation/widgets/order_offer_countdown_widget.dart';

void main() {
  Future<void> show(WidgetTester tester, DateTime expiresAt) =>
      tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: OrderOfferCountdownWidget(
              expiresAt: expiresAt,
              totalSeconds: 10,
            ),
          ),
        ),
      );

  testWidgets('shows the seconds left, rounded up', (tester) async {
    await show(
      tester,
      DateTime.now().toUtc().add(const Duration(milliseconds: 9500)),
    );
    expect(find.text('10 s left'), findsOneWidget);
  });

  testWidgets('a shorter time left shows fewer seconds', (tester) async {
    await show(
      tester,
      DateTime.now().toUtc().add(const Duration(milliseconds: 2500)),
    );
    expect(find.text('3 s left'), findsOneWidget);
  });

  testWidgets('stops at zero once the turn is over', (tester) async {
    await show(
      tester,
      DateTime.now().toUtc().subtract(const Duration(seconds: 2)),
    );
    expect(find.text('0 s left'), findsOneWidget);
  });
}
