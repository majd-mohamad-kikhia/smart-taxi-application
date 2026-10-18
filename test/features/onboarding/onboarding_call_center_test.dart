import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/l10n/generated/app_localizations.dart';
import 'package:mshoar/core/theme/app_palette.dart';
import 'package:mshoar/features/onboarding/data/models/onboarding_step.dart';
import 'package:mshoar/features/onboarding/presentation/widgets/onboarding_page_widget.dart';
import 'package:mshoar/features/onboarding/presentation/widgets/onboarding_photo_fallback_widget.dart';

Widget _page(Locale locale) => MaterialApp(
  locale: locale,
  theme: ThemeData(extensions: [AppPalette.light]),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: const Scaffold(
    body: OnboardingPageWidget(step: OnboardingStep.callCenter),
  ),
);

void main() {
  test('the last onboarding page is the call center', () {
    expect(OnboardingStep.count, 4);
    expect(OnboardingStep.values.last, OnboardingStep.callCenter);
    expect(
      OnboardingStep.callCenter.imageAsset,
      'assets/images/onboarding/onboarding_call_center.jpg',
    );
  });

  test('the photo is bundled', () {
    expect(File(OnboardingStep.callCenter.imageAsset).existsSync(), isTrue);
  });

  testWidgets('English page says it, with the photo and no fallback', (
    tester,
  ) async {
    await tester.pumpWidget(_page(const Locale('en')));
    await tester.pumpAndSettle();
    expect(find.text('The best call center, at your service'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(OnboardingPhotoFallbackWidget), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the fallback shows the step icon instead of a hole', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OnboardingPhotoFallbackWidget(step: OnboardingStep.callCenter),
        ),
      ),
    );
    expect(find.byIcon(Icons.support_agent_rounded), findsOneWidget);
  });

  testWidgets('Arabic page says it', (tester) async {
    await tester.pumpWidget(_page(const Locale('ar')));
    await tester.pumpAndSettle();
    expect(find.text('أفضل مركز اتصال في خدمتك'), findsOneWidget);
  });
}
