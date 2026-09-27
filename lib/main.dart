import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/injection/injection.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'driver_features/driver_auth/data/repositories/driver_repository.dart';
import 'driver_features/driver_auth/presentation/cubit/driver_auth_cubit.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';

Future<void> main() async {
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

  // Skip the auth flow entirely if a session was already saved locally
  // (rider or driver — a device is only ever logged into one at a time).
  final restoredRider = await sl<AuthRepository>().restoreSession();
  if (restoredRider != null) {
    sl<AuthCubit>().hydrate(restoredRider);
    runApp(const MshoarApp(initialRoute: AppRouter.home));
    return;
  }

  final restoredDriver = await sl<DriverRepository>().restoreSession();
  if (restoredDriver != null) {
    sl<DriverAuthCubit>().hydrate(restoredDriver);
    runApp(const MshoarApp(initialRoute: AppRouter.driverHome));
    return;
  }

  runApp(const MshoarApp(initialRoute: AppRouter.roleSelection));
}

class MshoarApp extends StatelessWidget {
  final String initialRoute;

  const MshoarApp({super.key, required this.initialRoute});

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
      initialRoute: initialRoute,
      onGenerateRoute: AppRouter.onGenerateRoute,
      // Route names with a nested path (e.g. `/driver/home`) would
      // otherwise have Flutter's default initial-route handling split
      // them into one route per path segment (`/driver`, then
      // `/driver/home`), silently pushing an extra unmatched-route
      // fallback screen underneath the real one. Building a single route
      // straight from the full name avoids that.
      onGenerateInitialRoutes: (initialRouteName) {
        return [AppRouter.onGenerateRoute(RouteSettings(name: initialRouteName))];
      },
    );
  }
}
