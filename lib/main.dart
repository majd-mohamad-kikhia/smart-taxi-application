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
import 'core/deep_links/shared_order_link_handler.dart';
import 'core/injection/injection.dart';
import 'core/l10n/generated/app_localizations.dart';
import 'core/localization/l10n_context_extension.dart';
import 'core/localization/locale_cubit.dart';
import 'core/routing/app_router.dart';
import 'core/services/push_notification_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'core/splash/splash_signal.dart';
import 'core/widgets/splash_video_widget.dart';
import 'driver_features/driver_auth/data/repositories/driver_repository.dart';
import 'driver_features/driver_auth/presentation/cubit/driver_auth_cubit.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/onboarding/data/datasources/onboarding_local_data_source.dart';
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

  // The first frame is the splash video, shown at once. `_launch` replaces it
  // with the real app once the startup work below is done AND the video has
  // ended (or was skipped with a tap).
  final splash = SplashSignal();
  runApp(_SplashApp(signal: splash));

  await _start(splash);
}

/// Everything the app needs before its first real screen: settings, Firebase,
/// the saved session and the version check.
Future<void> _start(SplashSignal splash) async {
  await dotenv.load(fileName: '.env');

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  setupInjection();

  // Restore the saved language before the first frame.
  await sl<LocaleCubit>().load();
  await sl<ThemeCubit>().load();

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
      await _launch(AppRouter.home, splash);
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
      await _launch(AppRouter.driverHome, splash);
      return;
    }
  }

  // Nobody is signed in: a first-time visitor gets the onboarding before
  // choosing a role; everyone after that goes straight to role selection.
  final onboardingSeen = await sl<OnboardingLocalDataSource>().hasSeen();
  await _launch(
    onboardingSeen ? AppRouter.roleSelection : AppRouter.onboarding,
    splash,
  );
}

/// Asks the server whether this version may run — the splash stays up while
/// waiting (the cubit gives up and lets the user in after a few seconds) —
/// then starts the app on [initialRoute], or on the force-update /
/// maintenance screen when the server says so.
Future<void> _launch(String initialRoute, SplashSignal splash) async {
  final versionCubit = sl<AppVersionCubit>();
  await versionCubit.check();

  // The splash video plays to its end (or until it is tapped); a safety
  // limit keeps a stuck video from holding the app back.
  await splash.finished.timeout(const Duration(seconds: 15), onTimeout: () {});

  switch (versionCubit.state) {
    case AppVersionForceUpdate(:final info):
      runApp(
        MshoarApp(initialRoute: AppRouter.forceUpdate, initialArguments: info),
      );
    case AppVersionMaintenance(:final info):
      runApp(
        MshoarApp(initialRoute: AppRouter.maintenance, initialArguments: info),
      );
    case AppVersionAllowed() || AppVersionChecking():
      runApp(MshoarApp(initialRoute: initialRoute));
  }

  // After the app's navigator exists: the link that opened the app (if
  // any) is read here, then every link tapped while it runs.
  unawaited(sl<SharedOrderLinkHandler>().start());
}

/// The app shown while it starts up: just the splash video, in the dark
/// theme. It has no navigator routes or localization.
class _SplashApp extends StatelessWidget {
  final SplashSignal signal;

  const _SplashApp({required this.signal});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: Scaffold(
        backgroundColor: AppColors.black,
        body: SplashVideoWidget(signal: signal),
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
        BlocProvider<ThemeCubit>.value(value: sl<ThemeCubit>()),
        BlocProvider<AppVersionCubit>.value(value: sl<AppVersionCubit>()),
      ],
      child: BlocSelector<LocaleCubit, Locale, Locale>(
        selector: (locale) => locale,
        builder: (context, locale) =>
            BlocSelector<ThemeCubit, ThemeMode, ThemeMode>(
              selector: (mode) => mode,
              builder: (context, themeMode) => MaterialApp(
                navigatorKey: AppRouter.navigatorKey,
                builder: (context, child) =>
                    AnnotatedRegion<SystemUiOverlayStyle>(
                      // Status bar icons that read on the active theme's page.
                      value: AppTheme.overlayStyleFor(
                        Theme.of(context).brightness,
                      ),
                      child: AppVersionGateWidget(
                        child: child ?? const SizedBox.shrink(),
                      ),
                    ),
                onGenerateTitle: (context) => context.l10n.appName,
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: themeMode,

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
      ),
    );
  }
}
