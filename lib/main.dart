import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/injection/injection.dart';
import 'core/l10n/generated/app_localizations.dart';
import 'core/localization/l10n_context_extension.dart';
import 'core/localization/locale_cubit.dart';
import 'core/routing/app_router.dart';
import 'core/services/push_notification_service.dart';
import 'core/theme/app_theme.dart';
import 'driver_features/driver_auth/data/repositories/driver_repository.dart';
import 'driver_features/driver_auth/presentation/cubit/driver_auth_cubit.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (API keys, etc.)
  await dotenv.load(fileName: '.env');

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Force portrait mode
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar — light icons for the app's dark theme.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  // Register all dependencies
  setupInjection();

  // Restore the saved language before the first frame.
  await sl<LocaleCubit>().load();

  // Not awaited: the permission prompt shouldn't hold back the first frame.
  unawaited(sl<PushNotificationService>().initialize());

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
    return BlocProvider<LocaleCubit>.value(
      value: sl<LocaleCubit>(),
      child: BlocSelector<LocaleCubit, Locale, Locale>(
        selector: (locale) => locale,
        builder: (context, locale) => MaterialApp(
          onGenerateTitle: (context) => context.l10n.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,

          // ── Localization ───────────────────────────────────
          // Text direction follows the locale (Arabic → RTL, English →
          // LTR) through the Material/Widgets localization delegates, so
          // no global Directionality override is needed.
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,

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
            return [
              AppRouter.onGenerateRoute(RouteSettings(name: initialRouteName)),
            ];
          },
        ),
      ),
    );
  }
}
