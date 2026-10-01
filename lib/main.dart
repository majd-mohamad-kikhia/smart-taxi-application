import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/app_version/presentation/cubit/app_version_cubit.dart';
import 'core/app_version/presentation/cubit/app_version_state.dart';
import 'core/app_version/presentation/widgets/app_version_gate_widget.dart';
import 'core/injection/injection.dart';
import 'core/l10n/generated/app_localizations.dart';
import 'core/localization/l10n_context_extension.dart';
import 'core/localization/locale_cubit.dart';
import 'core/routing/app_router.dart';
import 'core/services/push_notification_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_splash_widget.dart';
import 'driver_features/driver_auth/data/repositories/driver_repository.dart';
import 'driver_features/driver_auth/presentation/cubit/driver_auth_cubit.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar — light icons for the app's dark theme.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppColors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  // The first frame is the splash with the taxi animation, shown at once and
  // for as long as the startup work below takes; `_launch` then replaces it
  // with the real app.
  runApp(const _SplashApp());

  await _start();
}

/// Everything the app needs before its first real screen: settings, Firebase,
/// the saved session and the version check.
Future<void> _start() async {
  await dotenv.load(fileName: '.env');

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  setupInjection();

  // Restore the saved language before the first frame.
  await sl<LocaleCubit>().load();

  // Not awaited: the permission prompt shouldn't hold back the first frame.
  unawaited(sl<PushNotificationService>().initialize());

  // Skip the auth flow entirely if a session was already saved locally
  // (customer or driver — a device is only ever logged into one at a time).
  //
  // A restored session is first checked against the server: if it rejects
  // the token (expired, or the account was deleted) the session is dropped
  // and the user lands on role selection. Offline, the check is skipped and
  // the user stays signed in.
  final customerRepository = sl<AuthRepository>();
  final restoredCustomer = await customerRepository.restoreSession();
  if (restoredCustomer != null) {
    if (await customerRepository.isSessionRejected()) {
      await customerRepository.logout();
    } else {
      sl<AuthCubit>().hydrate(restoredCustomer);
      await _launch(AppRouter.home);
      return;
    }
  }

  final driverRepository = sl<DriverRepository>();
  final restoredDriver = await driverRepository.restoreSession();
  if (restoredDriver != null) {
    if (await driverRepository.isSessionRejected()) {
      await driverRepository.logout();
    } else {
      sl<DriverAuthCubit>().hydrate(restoredDriver);
      await _launch(AppRouter.driverHome);
      return;
    }
  }

  await _launch(AppRouter.roleSelection);
}

/// Asks the server whether this version may run — the splash stays up while
/// waiting (the cubit gives up and lets the user in after a few seconds) —
/// then starts the app on [initialRoute], or on the force-update /
/// maintenance screen when the server says so.
Future<void> _launch(String initialRoute) async {
  final versionCubit = sl<AppVersionCubit>();
  await versionCubit.check();

  switch (versionCubit.state) {
    case AppVersionForceUpdate(:final info):
      runApp(
        MshoarApp(
          initialRoute: AppRouter.forceUpdate,
          initialArguments: info,
        ),
      );
    case AppVersionMaintenance(:final info):
      runApp(
        MshoarApp(
          initialRoute: AppRouter.maintenance,
          initialArguments: info,
        ),
      );
    case AppVersionAllowed() || AppVersionChecking():
      runApp(MshoarApp(initialRoute: initialRoute));
  }
}

/// The app shown while it starts up: just the splash, in the dark theme. It
/// has no navigator routes or localization because it has no text.
class _SplashApp extends StatelessWidget {
  const _SplashApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const Scaffold(
        backgroundColor: AppColors.black,
        body: AppSplashWidget(),
      ),
    );
  }
}

class MshoarApp extends StatelessWidget {
  final String initialRoute;
  final Object? initialArguments;

  const MshoarApp({
    super.key,
    required this.initialRoute,
    this.initialArguments,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LocaleCubit>.value(value: sl<LocaleCubit>()),
        BlocProvider<AppVersionCubit>.value(value: sl<AppVersionCubit>()),
      ],
      child: BlocSelector<LocaleCubit, Locale, Locale>(
        selector: (locale) => locale,
        builder: (context, locale) => MaterialApp(
          navigatorKey: AppRouter.navigatorKey,
          builder: (context, child) =>
              AppVersionGateWidget(child: child ?? const SizedBox.shrink()),
          onGenerateTitle: (context) => context.l10n.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,

          // Text direction follows the locale (Arabic → RTL, English →
          // LTR) through the Material/Widgets localization delegates, so
          // no global Directionality override is needed.
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,

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
              AppRouter.onGenerateRoute(
                RouteSettings(
                  name: initialRouteName,
                  arguments: initialArguments,
                ),
              ),
            ];
          },
        ),
      ),
    );
  }
}
