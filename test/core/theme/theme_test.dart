import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/l10n/generated/app_localizations.dart';
import 'package:mshoar/core/theme/app_colors.dart';
import 'package:mshoar/core/theme/app_palette.dart';
import 'package:mshoar/core/theme/app_theme.dart';
import 'package:mshoar/core/theme/theme_cubit.dart';
import 'package:mshoar/core/theme/theme_local_data_source.dart';
import 'package:mshoar/core/widgets/theme_switch_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

double _luminance(Color c) => c.computeLuminance();

double _contrast(Color a, Color b) {
  final l1 = _luminance(a), l2 = _luminance(b);
  return (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('palettes', () {
    for (final entry in {
      'dark': AppPalette.dark,
      'light': AppPalette.light,
    }.entries) {
      final p = entry.value;
      test(
        '${entry.key}: body text is readable on the page, surfaces and washes',
        () {
          for (final bg in [
            p.backgroundGray,
            p.backgroundWhite,
            p.backgroundMuted,
          ]) {
            expect(
              _contrast(p.textPrimary, bg),
              greaterThanOrEqualTo(7),
              reason: 'primary on $bg',
            );
            expect(
              _contrast(p.textSecondary, bg),
              greaterThanOrEqualTo(4.5),
              reason: 'secondary on $bg',
            );
            expect(
              _contrast(p.textTertiary, bg),
              greaterThanOrEqualTo(4.5),
              reason: 'tertiary on $bg',
            );
          }
        },
      );

      test('${entry.key}: brand text and error text read on a surface', () {
        expect(
          _contrast(p.primaryContent, p.backgroundWhite),
          greaterThanOrEqualTo(3),
        );
        expect(
          _contrast(p.textLink, p.backgroundWhite),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(p.errorText, p.backgroundWhite),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(p.errorText, p.errorSurface),
          greaterThanOrEqualTo(4.5),
        );
      });

      test(
        '${entry.key}: the elevation ladder is kept (page, surface, muted differ)',
        () {
          expect({
            p.backgroundGray,
            p.backgroundWhite,
            p.backgroundMuted,
          }, hasLength(3));
        },
      );
    }

    test(
      'the dark page is darker than its surface, the light page is not lighter',
      () {
        expect(
          _luminance(AppPalette.dark.backgroundGray),
          lessThan(_luminance(AppPalette.dark.backgroundWhite)),
        );
        expect(
          _luminance(AppPalette.light.backgroundGray),
          lessThanOrEqualTo(_luminance(AppPalette.light.backgroundWhite)),
        );
      },
    );

    test('label on the brand green stays readable in both themes', () {
      expect(
        _contrast(AppColors.textOnPrimary, AppColors.primary),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('dark text is readable on both ends of the brand gradient', () {
      for (final end in AppColors.primaryGradient.colors) {
        expect(
          _contrast(AppColors.textOnPrimary, end),
          greaterThanOrEqualTo(4.5),
          reason: '$end',
        );
      }
    });

    test(
      'a disabled button\'s label reads on its dimmed gradient, in both themes',
      () {
        for (final entry in {
          AppPalette.dark: AppPalette.dark.backgroundGray,
          AppPalette.light: AppPalette.light.backgroundGray,
        }.entries) {
          // The 40% gradient blended over the page, then the label (with its own alpha) over that.
          final dimmed = AppColors.primaryGradientDisabled.colors.map(
            (c) => Color.alphaBlend(c, entry.value),
          );
          for (final bg in dimmed) {
            final label = Color.alphaBlend(entry.key.textOnPrimaryDisabled, bg);
            expect(
              _contrast(label, bg),
              greaterThanOrEqualTo(3),
              reason: 'on $bg',
            );
          }
        }
      },
    );

    test('lerp blends the two palettes', () {
      final mid = AppPalette.dark.lerp(AppPalette.light, 0.5);
      expect(
        mid.textPrimary,
        Color.lerp(
          AppPalette.dark.textPrimary,
          AppPalette.light.textPrimary,
          0.5,
        ),
      );
    });
  });

  // The real themes (`AppTheme.dark` / `light`) load fonts over the network,
  // which tests cannot; these stand-ins carry the same palettes.
  ThemeData themeFor(AppPalette palette, Brightness brightness) => ThemeData(
    brightness: brightness,
    scaffoldBackgroundColor: palette.backgroundGray,
    extensions: [palette],
  );

  group('AppTheme', () {
    test('status bar icons are light on dark and dark on light', () {
      expect(
        AppTheme.overlayStyleFor(Brightness.dark).statusBarIconBrightness,
        Brightness.light,
      );
      expect(
        AppTheme.overlayStyleFor(Brightness.light).statusBarIconBrightness,
        Brightness.dark,
      );
    });

    testWidgets(
      'context.colors follows the theme and falls back under a plain one',
      (tester) async {
        late BuildContext context;
        Widget host(ThemeData theme) => MaterialApp(
          theme: theme,
          home: Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
        );
        await tester.pumpWidget(
          host(themeFor(AppPalette.light, Brightness.light)),
        );
        await tester.pumpAndSettle(); // the theme animates between palettes
        expect(context.colors.backgroundGray, AppPalette.light.backgroundGray);
        await tester.pumpWidget(
          host(themeFor(AppPalette.dark, Brightness.dark)),
        );
        await tester.pumpAndSettle(); // the theme animates between palettes
        expect(context.colors.backgroundGray, AppPalette.dark.backgroundGray);
        await tester.pumpWidget(host(ThemeData.light()));
        await tester.pumpAndSettle(); // the theme animates between palettes
        expect(context.colors.backgroundGray, AppPalette.light.backgroundGray);
        await tester.pumpWidget(host(ThemeData.dark()));
        await tester.pumpAndSettle(); // the theme animates between palettes
        expect(context.colors.backgroundGray, AppPalette.dark.backgroundGray);
      },
    );

    testWidgets(
      'a widget repaints with the new palette when the theme changes',
      (tester) async {
        Widget host(ThemeMode mode) => MaterialApp(
          theme: themeFor(AppPalette.light, Brightness.light),
          darkTheme: themeFor(AppPalette.dark, Brightness.dark),
          themeMode: mode,
          home: Builder(
            builder: (context) => ColoredBox(
              key: const Key('box'),
              color: context.colors.backgroundWhite,
            ),
          ),
        );
        Color box() =>
            tester.widget<ColoredBox>(find.byKey(const Key('box'))).color;

        await tester.pumpWidget(host(ThemeMode.dark));
        expect(box(), AppPalette.dark.backgroundWhite);
        await tester.pumpWidget(host(ThemeMode.light));
        await tester.pumpAndSettle();
        expect(box(), AppPalette.light.backgroundWhite);
      },
    );
  });

  group('ThemeCubit', () {
    test('is dark until the user chooses', () {
      expect(ThemeCubit(const ThemeLocalDataSource()).state, ThemeMode.dark);
    });

    test('a chosen theme is saved and restored on the next start', () async {
      final cubit = ThemeCubit(const ThemeLocalDataSource());
      await cubit.setMode(ThemeMode.light);
      expect(cubit.state, ThemeMode.light);

      final next = ThemeCubit(const ThemeLocalDataSource());
      await next.load();
      expect(next.state, ThemeMode.light);
    });

    test('an unknown saved value keeps the default', () async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': 'sepia'});
      final cubit = ThemeCubit(const ThemeLocalDataSource());
      await cubit.load();
      expect(cubit.state, ThemeMode.dark);
    });

    test('choosing the same theme, or "system", changes nothing', () async {
      final cubit = ThemeCubit(const ThemeLocalDataSource());
      final states = <ThemeMode>[];
      final sub = cubit.stream.listen(states.add);
      await cubit.setMode(ThemeMode.dark);
      await cubit.setMode(ThemeMode.system);
      await Future<void>.delayed(Duration.zero);
      expect(states, isEmpty);
      await sub.cancel();
    });
  });

  testWidgets('the settings switch changes the whole app theme', (
    tester,
  ) async {
    final cubit = ThemeCubit(const ThemeLocalDataSource());
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, mode) => MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: themeFor(AppPalette.light, Brightness.light),
            darkTheme: themeFor(AppPalette.dark, Brightness.dark),
            themeMode: mode,
            home: const Scaffold(body: ThemeSwitchWidget()),
          ),
        ),
      ),
    );
    Color page() =>
        Theme.of(tester.element(find.byType(Scaffold))).scaffoldBackgroundColor;
    expect(page(), AppPalette.dark.backgroundGray);

    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(cubit.state, ThemeMode.light);
    expect(page(), AppPalette.light.backgroundGray);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(page(), AppPalette.dark.backgroundGray);
    await cubit.close();
  });
}
