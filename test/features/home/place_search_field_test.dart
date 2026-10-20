import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/l10n/generated/app_localizations.dart';
import 'package:mshoar/core/theme/app_palette.dart';
import 'package:mshoar/features/home/presentation/widgets/place_search_field_widget.dart';

void main() {
  late List<String> changed;
  late List<String> submitted;

  Future<void> pump(WidgetTester tester) async {
    changed = [];
    submitted = [];
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [AppPalette.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: PlaceSearchFieldWidget(
            controller: controller,
            isSearching: false,
            onChanged: changed.add,
            onSubmitted: submitted.add,
            onClear: () {},
          ),
        ),
      ),
    );
  }

  testWidgets('typing reports the text but submits nothing', (tester) async {
    await pump(tester);

    await tester.enterText(find.byType(TextField), 'مطار');

    expect(changed, ['مطار']);
    expect(submitted, isEmpty);
  });

  testWidgets('the keyboard\'s search key submits what was typed', (
    tester,
  ) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField), 'مطار');

    await tester.testTextInput.receiveAction(TextInputAction.search);

    expect(submitted, ['مطار']);
    expect(
      tester.widget<TextField>(find.byType(TextField)).textInputAction,
      TextInputAction.search,
    );
  });

  testWidgets('the search icon submits what was typed', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField), 'مطار');

    await tester.tap(find.byIcon(Icons.search_rounded));

    expect(submitted, ['مطار']);
  });
}
