import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/l10n/generated/app_localizations.dart';
import 'package:mshoar/core/theme/app_palette.dart';
import 'package:mshoar/core/widgets/sos_button_widget.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class _FakeLauncher extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  final List<String> opened = [];

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    opened.add(url);
    return true;
  }
}

Widget _app(Locale locale) => MaterialApp(
  locale: locale,
  theme: ThemeData(extensions: [AppPalette.light]),
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: const Scaffold(body: Center(child: SosButtonWidget())),
);

void main() {
  late _FakeLauncher launcher;

  setUp(() {
    launcher = _FakeLauncher();
    UrlLauncherPlatform.instance = launcher;
  });

  testWidgets('one tap dials the emergency number, nothing to confirm', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const Locale('en')));
    expect(find.text('SOS'), findsOneWidget);

    await tester.tap(find.byType(SosButtonWidget));
    await tester.pump();

    expect(launcher.opened, ['tel:0989003300']);
  });

  testWidgets('says الطوارئ in Arabic', (tester) async {
    await tester.pumpWidget(_app(const Locale('ar')));
    expect(find.text('الطوارئ'), findsOneWidget);
  });
}
