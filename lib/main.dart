import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/injection/injection.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait mode
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // Register all dependencies
  setupInjection();

  runApp(const MshoarApp());
}

class MshoarApp extends StatelessWidget {
  const MshoarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مشوار',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // ── RTL Arabic localization ────────────────────────
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [
        Locale('ar', 'SA'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // ── Force RTL text direction globally ─────────────
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),

      // ── Navigation ─────────────────────────────────────
      initialRoute: AppRouter.home,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
