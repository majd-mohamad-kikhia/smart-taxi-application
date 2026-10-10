import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/l10n/generated/app_localizations.dart';
import 'package:mshoar/core/widgets/account_deletion_notice_dialog_widget.dart';

void main() {
  var continued = 0;

  Future<void> openNotice(WidgetTester tester, {Locale? locale}) async {
    continued = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: locale ?? const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showAccountDeletionNoticeDialog(
                  context,
                  onContinue: () => continued++,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    // The shared dialog's icon pulses forever, so settle by hand.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  testWidgets('says the deletion takes about 7 days', (tester) async {
    await openNotice(tester);
    expect(find.text('Account deletion in progress'), findsOneWidget);
    expect(find.textContaining('7 days'), findsOneWidget);
  });

  testWidgets('is shown in Arabic too', (tester) async {
    await openNotice(tester, locale: const Locale('ar'));
    expect(find.text('جارٍ حذف حسابك'), findsOneWidget);
    expect(find.textContaining('7 أيام'), findsOneWidget);
  });

  testWidgets('Continue closes it and hands over to the caller once', (
    tester,
  ) async {
    await openNotice(tester);
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(continued, 1);
    expect(find.text('Account deletion in progress'), findsNothing);
  });

  testWidgets('cannot be dismissed by tapping outside it', (tester) async {
    await openNotice(tester);
    await tester.tapAt(const Offset(4, 4));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Account deletion in progress'), findsOneWidget);
    expect(continued, 0);
  });
}
