import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/l10n/generated/app_localizations.dart';
import 'package:mshoar/features/auth/presentation/widgets/terms_checkbox_field_widget.dart';

void main() {
  final formKey = GlobalKey<FormState>();
  var opened = 0;

  setUp(() => opened = 0);

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Form(
          key: formKey,
          child: TermsCheckboxFieldWidget(onOpenTerms: () => opened++),
        ),
      ),
    ),
  );

  testWidgets('the form is invalid until the terms are accepted', (tester) async {
    await pump(tester);

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(
      find.text('You need to accept the terms and conditions to create an account'),
      findsOneWidget,
    );

    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    expect(formKey.currentState!.validate(), isTrue);
    await tester.pump();
    expect(
      find.text('You need to accept the terms and conditions to create an account'),
      findsNothing,
    );
  });

  testWidgets('tapping the coloured text opens the terms, not the checkbox', (tester) async {
    await pump(tester);

    await tester.tapAt(
      tester.getCenter(find.byType(Text).first) + const Offset(60, 0),
    );
    await tester.pump();

    expect(opened, 1);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
  });
}
