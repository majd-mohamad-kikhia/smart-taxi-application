# Smart Taxi (codename "Mshoar") — Developer Guide

> **Internal document.** This is a closed-source, client-owned app. This README is for the people
> who build and maintain it, not for end users. Read it first when you come back to the project
> after a break.

Companion docs in the repo root:

| File | What's in it |
| --- | --- |
| [CLAUDE.md](CLAUDE.md) | The project's coding rules (architecture, naming, DI, error handling, networking). Every change must follow them. |
| [PRODUCT.md](PRODUCT.md) | Who the users are, what the product does, product principles. |
| [DESIGN.md](DESIGN.md) | Design system: colors, typography, components, do's and don'ts. |
| [UNUSED_APIS.md](UNUSED_APIS.md) | Backend endpoints the app doesn't call yet. **Partly out of date**, see [Gotchas](#14-gotchas--known-todos). |
| [lib/features/auth/data/swagger.json](lib/features/auth/data/swagger.json) | **The API contract.** Source of truth for every endpoint, body and response. |

---

## Table of contents

1. [What the app is](#1-what-the-app-is)
2. [Setup from a fresh clone](#2-setup-from-a-fresh-clone)
3. [Tech stack & packages](#3-tech-stack--packages)
4. [Architecture](#4-architecture)
5. [App startup & navigation](#5-app-startup--navigation)
6. [Dependency injection](#6-dependency-injection)
7. [Networking: REST, errors, sockets](#7-networking-rest-errors-sockets)
8. [Cross-cutting core modules](#8-cross-cutting-core-modules)
9. [Business flows](#9-business-flows)
10. [Local storage](#10-local-storage)
11. [File-by-file reference](#11-file-by-file-reference)
12. [Tests](#12-tests)
13. [Release checklist](#13-release-checklist)
14. [Gotchas & known TODOs](#14-gotchas--known-todos)
15. [Recipes: common changes](#15-recipes-common-changes)

---

## 1. What the app is

- **Product name:** Smart Taxi. **Codebase name:** Mshoar (`pubspec.yaml` → `name: mshoar`, root widget `MshoarApp`).
- **Package / applicationId:** `com.ma.smarttaxi` (Android). Play Store: `https://play.google.com/store/apps/details?id=com.ma.smarttaxi`.
- **Business:** a company-operated taxi fleet (not a marketplace). One operator/manager sets the rules
  (free waiting minutes then a per-minute fee, commissions, bonuses, fines) and can cancel trips or block accounts.
- **One app, two roles:**
  - **Customer:** requests a ride, tracks the driver live, pays cash, sees trip history.
  - **Driver:** goes online, receives ride offers, runs the trip (arrived → start → pause/resume → finish → confirm payment), checks the wallet.
  - A device is signed in as one role at a time. Managers/admins use a separate dashboard (not this app).
- **Languages:** Arabic (default, RTL) and English (LTR). Currency shown as SYP. Default map center is Latakia, Syria.
- **Platforms:** Android is the target (iOS is configured but has no App Store listing yet). Portrait-only. One dark theme.
- **Backend:** `https://smart-taxi.ma-core.net`, with REST under `/api/...` and Socket.IO on the same host.

---

## 2. Setup from a fresh clone

### Toolchain

| Tool | Version |
| --- | --- |
| Flutter | 3.44.x stable (last used: 3.44.3) |
| Dart SDK | `^3.11.4` (from `pubspec.yaml`) |
| Java | 17 (set in `android/app/build.gradle.kts`; core-library desugaring is on, which `flutter_local_notifications` needs) |

### Secret / machine-local files (git-ignored, so **you must recreate them**)

Keep copies of these somewhere safe outside the repo (password manager, private drive). Never commit them, and never paste their values into docs.

| File | Contains | Used by | What breaks without it |
| --- | --- | --- | --- |
| `.env` | `GOOGLE_MAPS_API_KEY=...` | Listed under `assets:` in `pubspec.yaml`; loaded by `dotenv.load()` in [lib/main.dart](lib/main.dart) | **The build fails** (missing asset). No code reads `dotenv.env` today, but the file must exist. |
| `android/local.properties` | `sdk.dir`, `flutter.sdk` (auto-generated) **plus** `GOOGLE_MAPS_API_KEY=...` (added by hand) | `android/app/build.gradle.kts` → manifest placeholder `${GOOGLE_MAPS_API_KEY}` | Google Maps shows a blank/grey map on Android |
| `android/key.properties` | `storePassword`, `keyPassword`, `keyAlias`, `storeFile` | Release signing config in `android/app/build.gradle.kts` | Release builds can't be signed |
| the upload keystore (`*.keystore` / `*.jks`) | The signing key that `storeFile` points to | Release signing | **Lose this and you can't update the Play Store app.** Back it up. |
| `ios/Flutter/Secrets.xcconfig` | `GOOGLE_MAPS_API_KEY = ...` | Included by `Debug.xcconfig`/`Release.xcconfig` → `Info.plist` → `AppDelegate.swift` (`GMSServices.provideAPIKey`) | Maps don't load on iOS |

The Google Maps key lives in three places (`.env`, `android/local.properties`, `ios/Flutter/Secrets.xcconfig`). When you rotate it, update all three.

### Firebase (committed, no action needed)

- `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist` and [lib/firebase_options.dart](lib/firebase_options.dart) are in git.
- Firebase project id is **`samrt-taxi`** (the typo is the real id).
- `firebase.json` is the FlutterFire CLI config. To regenerate: `flutterfire configure`.
- Firebase is used only for **Cloud Messaging (push notifications)**.

### Everyday commands

```bash
flutter pub get                          # install packages
flutter gen-l10n                         # regenerate localization after editing .arb files (also runs on build)
flutter analyze                          # static analysis (flutter_lints), run before every commit
flutter test                             # unit + widget tests
flutter run                              # run on a connected device

dart run flutter_launcher_icons          # regenerate app icons from assets/icons/app_logo_icons/icon-master-1024.png
dart run flutter_native_splash:create    # regenerate the native splash screen
```

---

## 3. Tech stack & packages

### Packages (`pubspec.yaml`)

| Package | Why we use it | Where |
| --- | --- | --- |
| `flutter_bloc` | State management. **Cubits only** (no Blocs with events). | Every `presentation/cubit/` folder |
| `equatable` | Value equality for states and models, so identical states aren't re-emitted. | All states and models |
| `get_it` | Service locator / DI (`sl`). | [lib/core/injection/injection.dart](lib/core/injection/injection.dart) |
| `dio` | The only HTTP client. Central instance with interceptors. | [lib/core/network/api_client.dart](lib/core/network/api_client.dart); also a separate plain `Dio` in the OSRM and Photon clients |
| `socket_io_client` | Realtime: ride offers, live driver location, ride status, account blocks. | [lib/core/network/socket_client.dart](lib/core/network/socket_client.dart) plus 3 socket services |
| `google_maps_flutter` | All maps (pickup, live trip, route tab, ride history map, location picker). | `*_map_widget.dart`, `location_picker_screen.dart` |
| `geolocator` | GPS position, permission, "is GPS on" checks, distances. | Location services, the driver GPS guard, and the driver location ticker |
| `shared_preferences` | Local persistence (sessions, language, offline route data). | `*_local_data_source.dart`; see [Local storage](#10-local-storage) |
| `firebase_core` + `firebase_messaging` | FCM push notifications (pinned to exact versions `4.14.0` / `16.6.0`). | [lib/core/services/push_notification_service.dart](lib/core/services/push_notification_service.dart) |
| `flutter_local_notifications` | Shows FCM pushes as system notifications while the app is in the foreground. Android channel id: `mshoar_notifications`. | [lib/core/services/local_notification_service.dart](lib/core/services/local_notification_service.dart) |
| `flutter_localizations` + `intl` | ar/en localization (gen-l10n), date and number formatting. | `lib/core/l10n/`, `lib/core/utils/format_*.dart` |
| `google_fonts` | **Tajawal** font for all text (good Arabic + Latin). | [lib/core/theme/app_theme.dart](lib/core/theme/app_theme.dart) |
| `lottie` | The yellow taxi loading animation (`assets/loader/taxi_loader_yellow.json`). | [lib/core/widgets/app_loader_widget.dart](lib/core/widgets/app_loader_widget.dart) |
| `flutter_dotenv` | Loads `.env` at startup (currently loaded but unused, see Gotchas). | [lib/main.dart](lib/main.dart) |
| `flutter_markdown_plus` | Renders the privacy policy, which the server returns as Markdown. | [lib/core/widgets/privacy_policy_markdown_widget.dart](lib/core/widgets/privacy_policy_markdown_widget.dart) |
| `package_info_plus` | Reads the installed app version for the server version check. | [lib/core/app_version/data/repositories/app_version_repository.dart](lib/core/app_version/data/repositories/app_version_repository.dart) |
| `url_launcher` | Opens the store page, `tel:` links and WhatsApp (`wa.me`). | [lib/core/utils/open_store.dart](lib/core/utils/open_store.dart), [lib/core/utils/open_external_url.dart](lib/core/utils/open_external_url.dart) |
| **dev:** `flutter_lints` | Lint rules (`analysis_options.yaml` includes `flutter.yaml`). | |
| **dev:** `flutter_launcher_icons` | Generates launcher icons (config at the bottom of `pubspec.yaml`). | |
| **dev:** `flutter_native_splash` | Generates the native splash: black background, with a padded logo variant for Android 12. | |

> CLAUDE.md rule: **don't add a new dependency without agreeing on it first.**

### External services

| Service | Used for | Notes |
| --- | --- | --- |
| Smart Taxi backend `https://smart-taxi.ma-core.net` | REST API + Socket.IO | URL hard-coded in `api_client.dart` **and** `socket_client.dart` |
| Firebase Cloud Messaging | Push notifications (both roles) | The device token is sent with login/signup (`PushNotificationService.deviceTokenFields`) |
| Google Maps SDK | Map tiles | API key setup: see [Setup](#2-setup-from-a-fresh-clone). A dark style is loaded from `assets/map_styles/dark_map_style.json`. |
| OSRM `https://router.project-osrm.org` | Road route between two points (planned route line on live maps) | **Public demo server with no SLA**; point `AppConstants.routingBaseUrl` at your own instance for production. Uses a separate `Dio` so the auth token is never sent to it. |
| Photon `https://photon.komoot.io` | Place search-as-you-type and reverse geocoding in the location picker | Free, keyless, best-effort. Separate `Dio`, not `ApiClient`. |

---

## 4. Architecture

### Folder map

```
lib/
├── main.dart                 # entry point: splash → init → session restore → version check → MshoarApp
├── firebase_options.dart     # generated by FlutterFire, don't edit
├── core/                     # app-wide code; may NOT import a feature (except injection + routing, which wire everything)
├── features/                 # CUSTOMER side, one folder per feature
│   ├── auth/                 #   role selection, customer sign in / sign up (+ swagger.json lives here)
│   ├── home/                 #   "create request": pick pickup/dropoff, vehicle quotes, place order
│   ├── tracking/             #   live ride tracking over the socket
│   ├── trips/                #   ride history + ride details
│   ├── settings/             #   profile, edit profile, complaints, delete account
│   └── notifications/        #   in-app notification list (bell)
└── driver_features/          # DRIVER side, a parallel "app" with the same sub-feature layout
    ├── driver_main_wrapper_screen.dart   # driver bottom-nav shell (5 tabs)
    ├── driver_auth/          #   driver sign in, driver session; the "shared foundation" of the driver side
    ├── driver_gps_guard/     #   blocks driver screens while phone GPS is off
    ├── driver_home/          #   online/offline toggle, live location ticker, ride offers (socket)
    ├── driver_trip/          #   active ride: arrived/start/pause/finish/payment + route recording/upload
    ├── driver_route/         #   private on-device "route" tab (a meter with no server involvement)
    ├── driver_wallet/        #   monthly financial report, wallet transactions, fines
    ├── driver_profile/       #   read-only profile + vehicle card
    └── driver_settings/      #   search radius, complaints, account-deletion request
```

> **Why `driver_features/` is top-level** (and not `features/driver/`): the driver side is treated as a
> parallel app. It's a deliberate deviation from CLAUDE.md's `core/` + `features/` layout. New driver
> work goes in its own sub-feature folder under `lib/driver_features/<name>/`. Other driver sub-features
> may import `driver_auth`'s `DriverAuthCubit`/`DriverUserModel`; that's the one allowed exception.

### Layers inside every feature

```
<feature>/
├── data/
│   ├── datasources/   # *_remote_data_source.dart (Dio calls) / *_local_data_source.dart (SharedPreferences)
│   ├── models/        # *_model.dart: fromJson, Equatable, no translated text
│   └── repositories/  # *_repository.dart: wraps data sources, turns failures into ApiException / *Exception
└── presentation/
    ├── cubit/         # *_cubit.dart + *_state.dart: logic + immutable state
    ├── screens/       # *_screen.dart: provides the cubit (BlocProvider(create: sl<...>)), lays out widgets
    └── widgets/       # *_widget.dart: pure UI pieces
```

### Data flow

```
Screen / Widget ──calls──▶ Cubit ──calls──▶ Repository ──calls──▶ RemoteDataSource ──▶ ApiClient.dio
      ▲                      │                    │                                   │ interceptors:
      │                      │ emit(state)        │ catches ApiException,             │  1. token (Bearer)
      └──BlocBuilder/────────┘                    │ rethrows a structured error       │  2. error → ApiException
         BlocSelector                             │                                   │  3. LogInterceptor
                                                  ▼                                   ▼
                                       LocalDataSource (prefs)               https://smart-taxi.ma-core.net
```

Realtime features replace `RemoteDataSource` with a `*SocketService` that exposes Dart `Stream`s to the cubit.

### Rules that matter most (full list in [CLAUDE.md](CLAUDE.md))

- **No cross-feature imports.** If two features need something, move it to `core/`.
- **Swagger first.** Check `swagger.json` for the exact path, method, body and response before touching any API code. Never guess field names.
- **All endpoints** in [lib/core/network/api_endpoints.dart](lib/core/network/api_endpoints.dart); **all DI** in [lib/core/injection/injection.dart](lib/core/injection/injection.dart).
- No API calls in widgets or cubits. Widgets never `new` a repository; they use `sl<...>()` / `context.read`.
- Every async UI shows **loading, success and error** states.
- Naming: `*Screen`, `*Widget`, `*Cubit`, `*State`, snake_case files.
- **Reuse before you build:** check `lib/core/widgets/` and the feature's `widgets/` first; extract anything reusable.
- Say **"customer"**, not "rider", in code and strings.

### How features talk without importing each other

| Mechanism | Example |
| --- | --- |
| **`SessionCubit`** (core): who is signed in. Each role's auth cubit is the only writer; anyone can read it or call `logout()`. | Settings reads the user's name; any screen can log out. `logout()` dispatches to the handler registered per `UserRole` in `injection.dart`. |
| **Route arguments classes** in `app_router.dart` | `RideTrackingRouteArgs` (home → tracking), `DriverTripRouteArgs` (driver_home → driver_trip). Navigate by route name; never import another feature's screen. |
| **Stream wiring in `injection.dart`** | On session change: start/stop the account-block socket, refresh the unread-notifications count, sync the stored customer profile. On role chosen: tell `AppVersionCubit`. |
| **Shared models in `core/models/`** | `RideModel`, `OrderOfferModel`, `PickedLocationModel`, fare/waiting/pause models. |

---

## 5. App startup & navigation

### Startup sequence ([lib/main.dart](lib/main.dart))

1. Lock to portrait, set a transparent status bar with light icons.
2. `runApp(_SplashApp)`: the logo + taxi animation shows **immediately**, while the rest runs.
3. `dotenv.load('.env')`
4. `Firebase.initializeApp` + register the FCM background handler.
5. `setupInjection()`: register everything in `sl`.
6. `LocaleCubit.load()`: restore the saved language **before** the first real frame.
7. `PushNotificationService.initialize()`: **not awaited**, so the permission prompt doesn't block startup.
8. **Restore session**, customer first, then driver:
   - if a saved session exists, `isSessionRejected()` probes the server ([token_check.dart](lib/core/network/token_check.dart)).
     **Only an explicit 401** logs the user out; offline or timeout (5 s) keeps them signed in.
   - customer → `AppRouter.home`, driver → `AppRouter.driverHome`, nobody → `AppRouter.roleSelection`.
9. `_launch()`: `AppVersionCubit.check()` asks the server whether this version may run, then
   `runApp(MshoarApp(initialRoute: ...))`, or the **force-update** / **maintenance** screen instead.

`MshoarApp` wraps every route in `AppVersionGateWidget` (via `MaterialApp.builder`), so a force update,
maintenance or optional update can appear on top of any screen, and it re-checks when the app returns to the foreground.

> `onGenerateInitialRoutes` is overridden on purpose. Without it, Flutter splits `/driver/home` into
> `/driver` + `/driver/home` and silently pushes a fallback screen underneath.

### Routes ([lib/core/routing/app_router.dart](lib/core/routing/app_router.dart))

| Route constant | Path | Screen | Arguments |
| --- | --- | --- | --- |
| `roleSelection` | `/role-selection` | `RoleSelectionScreen` | |
| `signIn` | `/sign-in` | `SignInScreen` (customer) | |
| `signUp` | `/sign-up` | `SignUpScreen` (customer) | |
| `driverSignIn` | `/driver/sign-in` | `DriverSignInScreen` | |
| `home` | `/` | `MainWrapperScreen` (customer shell) | |
| `rideTracking` | `/ride-tracking` | `RideTrackingScreen` | `RideTrackingRouteArgs` |
| `rideDetails` | `/trips/details` | `RideDetailsScreen` | `int` rideId |
| `settings` | `/settings` | `SettingsScreen` | |
| `editProfile` | `/settings/edit-profile` | `EditProfileScreen` | |
| `notifications` | `/notifications` | `NotificationsScreen` | |
| `contactUs` | `/contact-us` | `ContactUsScreen` | `UserRole` |
| `driverHome` | `/driver/home` | `DriverGpsGuardWidget(DriverMainWrapperScreen)` | |
| `driverTrip` | `/driver/trip` | `DriverGpsGuardWidget(DriverTripScreen)` | `DriverTripRouteArgs` |
| `forceUpdate` | `/app-version/force-update` | `ForceUpdateScreen` | `AppVersionModel` |
| `maintenance` | `/app-version/maintenance` | `MaintenanceScreen` | `AppVersionModel` |
| *(unknown)* | | falls back to `MainWrapperScreen` | |

`LocationPickerScreen` is the one screen pushed directly with `Navigator.push` (it returns a value and lives inside `home`).

### The two shells (bottom navigation, `IndexedStack` so tabs stay alive)

| Shell | Tabs |
| --- | --- |
| **Customer:** [main_wrapper_screen.dart](lib/core/routing/main_wrapper_screen.dart) | Create request (`HomeScreen`) · My requests (`TripsScreen`) · Settings (`SettingsScreen`) |
| **Driver:** [driver_main_wrapper_screen.dart](lib/driver_features/driver_main_wrapper_screen.dart) | Home · Route · Wallet · Profile · Settings |

The driver shell also does two things when it opens: it uploads any trip routes still waiting to be uploaded
(`DriverTripRouteRepository.uploadPending()`), and asks `GET /api/driver/rides/active`. If the
driver was mid-ride when the app closed, it pushes them straight back to `DriverTripScreen`.

---

## 6. Dependency injection

Everything is registered in [lib/core/injection/injection.dart](lib/core/injection/injection.dart) as the global `sl` (`GetIt.instance`).
It's grouped by section comments (`// ─── Auth Feature ───`, etc.), so adding a feature means adding a section there.

| Registration | Use when | Examples |
| --- | --- | --- |
| `registerLazySingleton` | One shared instance: data sources, repositories, and cubits that must **survive navigation or tab switches** | `ApiClient`, all repositories, `SessionCubit`, `LocaleCubit`, `AppVersionCubit`, `AuthCubit` (keeps the selected role across role-selection → sign in), `DriverAuthCubit`, `DriverPresenceCubit` + `DriverOrdersCubit` (share **one** `DriverSocketService`), `GpsStatusCubit`, `UnreadNotificationsCubit` |
| `registerFactory` | A fresh cubit per screen | `HomeCubit`, `TripsCubit`, `SettingsCubit`, `EditProfileCubit`, `NotificationsCubit`, `PrivacyPolicyCubit`, `RouteTrackerCubit`, `CustomerRideSocketService` (fresh socket per tracking screen) |
| `registerFactoryParam` | A per-screen cubit that needs constructor data | `DriverTripCubit(order, resume)`, `RideTrackingCubit(RideTrackingCubitArgs)`, `RideDetailsCubit(rideId)`, `DriverWalletCubit(transactionType?)` |
| `instanceName:` | Same type, different configuration | `ComplaintCubit` → `'customer'` / `'driver'`; `ContactUs*` → one per `ContactUsApp.wireValue` |

Typical use in a screen:

```dart
BlocProvider(create: (_) => sl<TripsCubit>()..load(), child: ...)
sl<ComplaintCubit>(instanceName: 'driver')
sl<DriverTripCubit>(param1: order, param2: resume)
```

---

## 7. Networking: REST, errors, sockets

### `ApiClient` ([api_client.dart](lib/core/network/api_client.dart))

- Base URL `https://smart-taxi.ma-core.net`, JSON, 15 s connect/receive timeouts.
- Interceptors, in order:
  1. **Token:** adds `Authorization: Bearer <ApiClient.authToken>`. The static `authToken` is set by the auth repositories on login/restore and cleared on logout.
  2. **Error:** converts every `DioException` into one whose `.error` is a structured `ApiException`.
  3. **Log:** `LogInterceptor` with request/response bodies. `_enableLogging = true` is **always on, including release builds**.
- `ApiClient.resolveMediaUrl(path)` turns relative `photo_url` values (`/uploads/...`) into full URLs.

### Errors: `ApiErrorHandler` → `ApiException`

- [api_exception.dart](lib/core/network/api_exception.dart): `message` (already translated), `statusCode`, `fieldErrors` (per-field messages for 409/422).
- [api_error_handler.dart](lib/core/network/api_error_handler.dart) **never shows the server's raw English text**. Messages are resolved in this order:
  1. a field reason that **exactly** matches a literal documented in swagger → its translation
  2. a single failing field with known constraints → spell out the rule (e.g. password requirements)
  3. known user-facing fields → "Check: phone, password…"
  4. a top-level `message` that exactly matches a documented literal
  5. a fallback by status code **and endpoint** (e.g. 401 on login = wrong credentials, elsewhere = session expired; 409 on signup = account exists, elsewhere = action unavailable)
- The lookup tables live in [api_error_messages.dart](lib/core/network/api_error_messages.dart). **When the backend adds a new error string, add it there** (and to both .arb files).
- Status code constants are in [status_code.dart](lib/core/network/status_code.dart). Use `StatusCode.unauthorized`, not `401`.

API envelope (from swagger): success → `{ "success": true, "data": ... }`, error → `{ "success": false, "message": "...", "errors": { "field": "reason" } }`.

### REST endpoints ([api_endpoints.dart](lib/core/network/api_endpoints.dart), injected as an instance, not static)

| Group | Endpoints |
| --- | --- |
| **Public** | `GET /api/privacy-policy?lang=` · `GET /api/contact-numbers?app=&lang=` · `GET /api/app/version-check` |
| **Customer auth** | `POST /api/customer/auth/signup` · `POST .../login` · `POST .../logout` |
| **Customer profile** | `GET/PUT /api/customer/profile` (DELETE = delete account) · `PUT /api/customer/profile/language` |
| **Customer complaints** | `POST /api/customer/complaints` |
| **Customer notifications** | `GET /api/customer/notifications` · mark one read · mark all read |
| **Customer rides** | `GET /api/customer/rides` (history, paginated) · `GET /api/customer/rides/{id}` · `POST /api/customer/rides/locations` (step 1: quote) · `POST /api/customer/rides/choose-vehicle` (step 2: create ride) · `POST /api/customer/rides/{id}/cancel` |
| **Driver auth** | `POST /api/driver/auth/login` · `POST .../logout` · `POST .../signup` (defined, unused) · `PUT /api/driver/language` |
| **Driver rides** | `GET /api/driver/rides/active` · `POST /api/driver/rides/{id}/` + `accept` (unused, accept goes via socket) / `pickup` / `start` / `pause` / `resume` / `finish` / `cancel` / `confirm-payment` · `PUT /api/driver/rides/{id}/route` |
| **Driver other** | `PUT /api/driver/search-radius` · `GET /api/driver/wallet` · `GET /api/driver/financial-report` · `POST /api/driver/complaints` · `/api/driver/account/deletion-request` (GET latest / POST request / DELETE cancel) · `GET /api/driver/vehicle` |

Check `api_endpoints.dart` for the exact methods; the table above is a map, not the contract.

### Socket.IO

- Created by `createSocket(token)` in [socket_client.dart](lib/core/network/socket_client.dart): websocket transport, path `/socket.io/`, auth `{token}`, auto-reconnect (20 attempts, 1 s), **no auto-connect** (the caller connects).
- Three separate connections:

| Service | Lifetime | Listens to | Sends |
| --- | --- | --- | --- |
| [DriverSocketService](lib/driver_features/driver_home/data/datasources/driver_socket_service.dart) | Singleton while the driver is online, shared by presence + orders cubits | `driver:orders_snapshot`, `driver:order_offer`, `driver:order_remove`, `driver:ride_cancelled` | `driver:location {lat,lng}` (periodic, from `LocationTicker`), `driver:order_accept {ride_id}` **with ack** `{ok, error}` |
| [CustomerRideSocketService](lib/features/tracking/data/datasources/customer_ride_socket_service.dart) | Fresh per tracking screen | `customer:ride_accepted`, `customer:driver_location`, `customer:ride_status`, `customer:ride_pause_update`, `customer:ride_paid`, `customer:active_ride` | `customer:ride_cancel {ride_id, cancellation_reason?}` **with ack** |
| [AccountBlockSocketService](lib/core/account_block/account_block_socket_service.dart) | Always on while anyone is signed in | `customer:block_status` / `driver:block_status` (manager's ride block), `app:version_changed` (triggers a version re-check) | |

> Several files mention `docs/socket.md`, but **that file isn't in the repo**. The event contract above is taken from the code.
> Ask the backend team for the socket doc if you need payload details.

---

## 8. Cross-cutting core modules

**Session** ([lib/core/session/](lib/core/session/)): `SessionCubit` holds `AppUser?` (id, name, phone, email, photo, role). Written only by `AuthCubit` (customer) and `DriverAuthCubit` (driver). `logout()` routes to the handler registered per role. The driver handler first goes offline, then logs out.

**Account block** ([lib/core/account_block/](lib/core/account_block/)): a manager can block an account from rides until a date. `AccountBlockCubit` listens on the always-on socket; `AccountBlockGateWidget` swaps the order button (customer) or ride offers (driver) for `AccountBlockedWidget` while blocked.

**App version gate** ([lib/core/app_version/](lib/core/app_version/)): `GET /api/app/version-check?app=customer|driver` (role-specific; before sign-in it uses the role picked on role selection). Server statuses: `ok`, `optionalUpdate` (dialog with Update/Later; "Later" is remembered per version), `forceUpdate` (full-screen, only way out is the store), `maintenance` (full-screen with message, "back at" time, and Try again). It's checked at launch, on app resume, and when the socket emits `app:version_changed`. If the check takes too long, the user is let in.

**Localization** ([lib/core/localization/](lib/core/localization/) + [lib/core/l10n/](lib/core/l10n/)):
- Strings: `lib/core/l10n/app_en.arb` (template) and `app_ar.arb`. Generated code goes to `lib/core/l10n/generated/` (committed; config in `l10n.yaml`).
- In widgets: `context.l10n.key` (import `l10n_context_extension.dart`), which rebuilds on language change.
- Without a context (cubits, repos, error handler, validators, notifications): `AppStrings.current.key`. Never inside `build()`.
- `LocaleCubit` persists the choice locally **and** tells the server (`LanguageRepository`), so pushes arrive in the right language.
- Direction (RTL/LTR) comes from the locale. In layout code use `EdgeInsetsDirectional`, `AlignmentDirectional` and `PositionedDirectional`, and auto-mirroring arrow icons.
- Models never hold translated text; they expose `label(AppLocalizations l10n)`. Numbers and prices are passed into strings pre-formatted (`formatPrice`) so they stay Latin digits.

**Privacy policy** ([lib/core/privacy_policy/](lib/core/privacy_policy/)): public endpoint, Markdown, shown in a dialog from sign-up (required checkbox) and both settings screens.

**Contact us** ([lib/core/contact_us/](lib/core/contact_us/)): the manager's phone and WhatsApp numbers per app. The data source caches with an **ETag** (that's why it's a singleton per app).

**Complaints** ([lib/core/complaints/](lib/core/complaints/) + `core/widgets/complaint_dialog_widget.dart`): one shared cubit and dialog. Each role injects its own submit function (named instances `'customer'` / `'driver'`).

**Notifications**:
- *Push:* `PushNotificationService` gets the FCM token (sent with login), shows foreground pushes through `LocalNotificationService`, and handles background pushes in `firebaseMessagingBackgroundHandler`, which runs in **a separate isolate, so no `sl` is available there**. It also exposes a `rideCancelled` stream that the driver trip cubit listens to.
- *In-app list (customer only):* `features/notifications`, plus `UnreadNotificationsCubit` (core) for the bell badge.

**Location & routes** ([lib/core/services/](lib/core/services/)): `CurrentLocationService` (one-off position + permission handling), `RouteService` (OSRM call), `PlannedRouteLoader` (loads the planned route once per trip and caches it; the line never re-routes while driving).

**Theme** ([lib/core/theme/](lib/core/theme/)): `AppColors` holds **every** color as a named token (don't use raw `Color(0x...)` in widgets). `AppTheme.darkTheme` is the only theme. Brand is yellow on near-black. Font: Tajawal. Spacing, radius and animation constants are in `AppConstants`. See [DESIGN.md](DESIGN.md).

**Validators** ([lib/core/validators/](lib/core/validators/)): phone and password rules matching swagger. `PhoneInputFormatter` converts Arabic-Indic/Persian digits to ASCII.

---

## 9. Business flows

### Ride status lifecycle (`status_id`)

```
1 requested ──▶ 2 accepted ──▶ 3 arrived (optional) ──▶ 4 in progress ──▶ 5 completed
     └───────────────┴──────────────────┴────────────────────┴──────────▶ 6 cancelled (by customer, driver or manager)
```

### Fare model

`final_price = base_fare + distance_fare + stops_fee_total + waiting_fee + pause_fee_total`

- **Waiting** (`RideWaitingModel`) starts when the driver taps "arrived". A number of free minutes, then a per-minute fee.
- **Pause** (`RidePauseModel`) is a mid-trip stop (e.g. a coffee). Included time, then a fee.
- **The server measures time and computes every fee; the apps only display it.** Live timers count *up* from the
  server's `elapsed_seconds` using the phone's stopwatch, so a wrong phone clock or timezone doesn't matter. `SecondTickerWidget` repaints only the timer.
- Payment is **cash to the driver**. The driver confirms it (`confirm-payment`); the server deducts the commission from the driver's wallet.

### Customer flow

1. **Role selection** → **sign up / sign in** (`features/auth`). Sign-up requires accepting the privacy policy.
2. **Create request tab** (`features/home`): pick *From* and *To* in `LocationPickerScreen` (map + Photon search) →
   `POST rides/locations` returns distance, ETA and a **price per vehicle type** → `VehicleTypeSheetWidget` → `POST rides/choose-vehicle` creates the ride.
3. Navigate to **`RideTrackingScreen`** (`features/tracking`): the socket pushes driver accepted → live driver location → status changes →
   waiting/pause timers → completed → **payment-due dialog** → `customer:ride_paid` closes it. Back is blocked until the ride ends. The customer can cancel with a reason.
4. **My requests tab** (`features/trips`): paginated history with a status filter → ride details (route map of the driven path, bill, timestamps).
5. **Settings** (`features/settings`): profile card + edit profile, language, privacy policy, contact us, complaint, delete account (password-confirmed), logout.
6. **Notifications**: the bell in the top bar (`AppBrandBarWidget`, with an unread badge) opens `NotificationsScreen`.

### Driver flow

1. **Sign in** only (drivers are onboarded outside the app; there's no sign-up screen). Login is rejected (403) for pending, suspended or rejected accounts.
2. Every driver screen is wrapped in **`DriverGpsGuardWidget`**: if GPS is off, a non-dismissable dialog blocks the screen until it's back on.
3. **Home tab** (`driver_home`): status card + **online toggle**. Going online opens the socket and starts `LocationTicker`, which emits
   `driver:location` periodically. Offers arrive as `orders_snapshot`/`order_offer`/`order_remove`. **Accept** = `driver:order_accept` with ack.
4. **Trip screen** (`driver_trip`): pickup map → "I've arrived" (optional; starts the waiting timer) → **Start** → Pause/Resume → **Finish**
   → **fare dialog** (what to collect, the driver's share) → **Confirm payment**. Cancel with a reason is possible before the trip starts.
   The GPS path is recorded during the trip, saved on the device, and uploaded with `PUT rides/{id}/route` after finishing. Failed uploads retry the next time the shell opens.
   A cancellation can arrive by socket **or** by push; both end the screen.
5. **Route tab** (`driver_route`): a **private, on-device-only** meter (arrived → start → stops → finish, with distance and timers). Nothing is sent to the server.
6. **Wallet tab** (`driver_wallet`): monthly financial report (earnings, commissions, rewards, fines, compensations, net income, balance), month picker, and a fines drill-down (wallet transactions filtered to `penalty`).
7. **Profile tab** (`driver_profile`): read-only info from login + vehicle card (`GET /api/driver/vehicle`).
8. **Settings tab** (`driver_settings`): search radius slider (1–10 km), language, contact us, complaint, privacy policy, **account deletion request** (pending/approved/rejected, can be cancelled), logout.

---

## 10. Local storage

All in `SharedPreferences`:

| Key | Owner | Contents |
| --- | --- | --- |
| `auth_session` | [auth_local_data_source.dart](lib/features/auth/data/datasources/auth_local_data_source.dart) | Customer session (tokens + profile). Legacy role value `'rider'` is mapped to `customer` on read; keep that mapping. |
| `driver_session` | [driver_local_data_source.dart](lib/driver_features/driver_auth/data/datasources/driver_local_data_source.dart) | Driver session (tokens + driver + vehicle) |
| `app_language_code` | [locale_local_data_source.dart](lib/core/localization/locale_local_data_source.dart) | `ar` / `en` |
| `driver_trip_route_ids` (+ one entry per ride) | [driver_trip_route_local_data_source.dart](lib/driver_features/driver_trip/data/datasources/driver_trip_route_local_data_source.dart) | Recorded trip routes not yet uploaded |
| `driver_route_session` | [route_session_local_data_source.dart](lib/driver_features/driver_route/data/datasources/route_session_local_data_source.dart) | The private route tab's current route |
| skipped update version | [app_version_local_datasource.dart](lib/core/app_version/data/datasources/app_version_local_datasource.dart) | The version the user dismissed with "Later" (per app) |

---

## 11. File-by-file reference

Generated files are **not** listed one by one. Don't edit them by hand:
- `lib/core/l10n/generated/*`: regenerate with `flutter gen-l10n`.
- `lib/firebase_options.dart`: regenerate with `flutterfire configure`.

### `lib/` root

- [main.dart](lib/main.dart): entry point, startup sequence, `MshoarApp` (MaterialApp, locale, theme, router, version gate).

### `lib/core/`

**account_block/**: manager-imposed ride block
- [account_block_cubit.dart](lib/core/account_block/account_block_cubit.dart): app-wide "is this account blocked" state; started on sign-in, stopped on logout.
- [account_block_socket_service.dart](lib/core/account_block/account_block_socket_service.dart): always-on socket for `*:block_status` and `app:version_changed`.
- [account_block_state.dart](lib/core/account_block/account_block_state.dart): state holding the current block (or none).

**app_version/**: force update / maintenance / optional update
- [data/datasources/app_version_local_datasource.dart](lib/core/app_version/data/datasources/app_version_local_datasource.dart): remembers the version dismissed with "Later".
- [data/datasources/app_version_remote_datasource.dart](lib/core/app_version/data/datasources/app_version_remote_datasource.dart): `GET /api/app/version-check`.
- [data/models/app_version_model.dart](lib/core/app_version/data/models/app_version_model.dart): `AppVersionApp` (customer/driver), `AppVersionStatus`, server response model.
- [data/repositories/app_version_repository.dart](lib/core/app_version/data/repositories/app_version_repository.dart): combines installed version (package_info) + server check + skipped version.
- [presentation/cubit/app_version_cubit.dart](lib/core/app_version/presentation/cubit/app_version_cubit.dart): runs the check at launch, resume, role choice and socket event; manual re-check.
- [presentation/cubit/app_version_state.dart](lib/core/app_version/presentation/cubit/app_version_state.dart): sealed states `Checking` / `Allowed(optional?)` / `ForceUpdate` / `Maintenance`.
- [presentation/screens/force_update_screen.dart](lib/core/app_version/presentation/screens/force_update_screen.dart): full-screen "update required"; only exit is the store.
- [presentation/screens/maintenance_screen.dart](lib/core/app_version/presentation/screens/maintenance_screen.dart): full-screen maintenance message with "back at" time and Try again.
- [presentation/widgets/app_version_blocked_layout_widget.dart](lib/core/app_version/presentation/widgets/app_version_blocked_layout_widget.dart): shared body of the two blocking screens.
- [presentation/widgets/app_version_gate_widget.dart](lib/core/app_version/presentation/widgets/app_version_gate_widget.dart): sits above the whole app; reacts to state changes and app resume.
- [presentation/widgets/app_version_retry_button_widget.dart](lib/core/app_version/presentation/widgets/app_version_retry_button_widget.dart): "Try again" with spinner.
- [presentation/widgets/app_version_update_button_widget.dart](lib/core/app_version/presentation/widgets/app_version_update_button_widget.dart): "Update" button that opens the store.
- [presentation/widgets/maintenance_recheck_button_widget.dart](lib/core/app_version/presentation/widgets/maintenance_recheck_button_widget.dart): maintenance "Try again" that reports what it found.
- [presentation/widgets/optional_update_dialog_widget.dart](lib/core/app_version/presentation/widgets/optional_update_dialog_widget.dart): "new version available" dialog (Update / Later).

**complaints/**: shared complaint submission
- [complaint_cubit.dart](lib/core/complaints/complaint_cubit.dart): submits via an injected role-specific `ComplaintSubmitter`.
- [complaint_exception.dart](lib/core/complaints/complaint_exception.dart): structured complaint failure.
- [complaint_state.dart](lib/core/complaints/complaint_state.dart): idle / submitting / success / failure.

**constants/**
- [app_constants.dart](lib/core/constants/app_constants.dart): app version footer string, logo path, default map center (Latakia), store URLs, OSRM URL, spacing/radius/animation constants.

**contact_us/**: manager's contact numbers
- [data/datasources/contact_us_remote_datasource.dart](lib/core/contact_us/data/datasources/contact_us_remote_datasource.dart): `GET /api/contact-numbers` with ETag caching.
- [data/models/contact_number_model.dart](lib/core/contact_us/data/models/contact_number_model.dart): `ContactUsApp`, `ContactType` (phone/whatsapp), number model.
- [data/repositories/contact_us_repository.dart](lib/core/contact_us/data/repositories/contact_us_repository.dart): repository wrapper.
- [presentation/cubit/contact_us_cubit.dart](lib/core/contact_us/presentation/cubit/contact_us_cubit.dart): loads numbers for the screen.
- [presentation/cubit/contact_us_state.dart](lib/core/contact_us/presentation/cubit/contact_us_state.dart): loading / loaded / error.
- [presentation/screens/contact_us_screen.dart](lib/core/contact_us/presentation/screens/contact_us_screen.dart): list of numbers for the given role's app.
- [presentation/widgets/contact_number_tile_widget.dart](lib/core/contact_us/presentation/widgets/contact_number_tile_widget.dart): one number; tap to call or open WhatsApp.
- [presentation/widgets/contact_us_error_widget.dart](lib/core/contact_us/presentation/widgets/contact_us_error_widget.dart): error + retry.

**enums/**
- [user_role.dart](lib/core/enums/user_role.dart): `UserRole { customer, driver }` with localized label/description.

**injection/**
- [injection.dart](lib/core/injection/injection.dart): `sl` + `setupInjection()`; all registrations and cross-feature stream wiring.

**l10n/**
- `app_en.arb` (template), `app_ar.arb`: all UI strings. `generated/` is the gen-l10n output.

**localization/**
- [app_locales.dart](lib/core/localization/app_locales.dart): supported locales, native names, code → Locale.
- [app_strings.dart](lib/core/localization/app_strings.dart): `AppStrings.current`, context-free access to the active translations.
- [l10n_context_extension.dart](lib/core/localization/l10n_context_extension.dart): `context.l10n` extension.
- [language_remote_data_source.dart](lib/core/localization/language_remote_data_source.dart): tells the server the account's language (per role).
- [language_repository.dart](lib/core/localization/language_repository.dart): repository + `LanguageException`.
- [locale_cubit.dart](lib/core/localization/locale_cubit.dart): active `Locale`; load, set, change (server + local).
- [locale_local_data_source.dart](lib/core/localization/locale_local_data_source.dart): persists the language code.

**models/**: models shared by several features
- [account_block_model.dart](lib/core/models/account_block_model.dart): block payload (until when, reason).
- [order_offer_model.dart](lib/core/models/order_offer_model.dart): a ride offer for the driver (socket only, no REST list).
- [picked_location_model.dart](lib/core/models/picked_location_model.dart): a location picked on the map (pickup/dropoff).
- [privacy_policy_model.dart](lib/core/models/privacy_policy_model.dart): policy in one language (Markdown).
- [ride_fare_breakdown_model.dart](lib/core/models/ride_fare_breakdown_model.dart): bill lines of a finished ride.
- [ride_model.dart](lib/core/models/ride_model.dart): a ride from `choose-vehicle` / cancel.
- [ride_pause_model.dart](lib/core/models/ride_pause_model.dart): pause info + live count-up snapshot.
- [ride_waiting_model.dart](lib/core/models/ride_waiting_model.dart): waiting-at-pickup info + live count-up snapshot.
- [route_point_model.dart](lib/core/models/route_point_model.dart): plain lat/lng route vertex (map-SDK independent).

**network/**
- [api_client.dart](lib/core/network/api_client.dart): the Dio instance, base URL, interceptors, `authToken`, `resolveMediaUrl`.
- [api_endpoints.dart](lib/core/network/api_endpoints.dart): every REST path.
- [api_error_handler.dart](lib/core/network/api_error_handler.dart): `DioException` → translated `ApiException`.
- [api_error_messages.dart](lib/core/network/api_error_messages.dart): exact-match tables, swagger error literal → l10n message.
- [api_exception.dart](lib/core/network/api_exception.dart): the structured error model.
- [socket_client.dart](lib/core/network/socket_client.dart): `createSocket(token)` factory.
- [status_code.dart](lib/core/network/status_code.dart): HTTP status constants.
- [token_check.dart](lib/core/network/token_check.dart): `isTokenRejected()`, the startup 401 probe.

**notifications/**
- [unread_notifications_cubit.dart](lib/core/notifications/unread_notifications_cubit.dart): unread count for the bell badge.

**privacy_policy/**
- [privacy_policy_cubit.dart](lib/core/privacy_policy/privacy_policy_cubit.dart): loads the policy for the dialog.
- [privacy_policy_remote_data_source.dart](lib/core/privacy_policy/privacy_policy_remote_data_source.dart): `GET /api/privacy-policy`.
- [privacy_policy_repository.dart](lib/core/privacy_policy/privacy_policy_repository.dart): repository + `PrivacyPolicyException`.
- [privacy_policy_state.dart](lib/core/privacy_policy/privacy_policy_state.dart): loading / success / failure.

**routing/**
- [app_router.dart](lib/core/routing/app_router.dart): route names, `onGenerateRoute`, route-args classes, `navigatorKey`.
- [main_wrapper_screen.dart](lib/core/routing/main_wrapper_screen.dart): customer bottom-nav shell.

**services/**
- [current_location_service.dart](lib/core/services/current_location_service.dart): one-off GPS position with permission/failure reasons.
- [local_notification_service.dart](lib/core/services/local_notification_service.dart): shows system notifications (channel setup).
- [planned_route_loader.dart](lib/core/services/planned_route_loader.dart): loads + caches a trip's planned route once.
- [push_notification_service.dart](lib/core/services/push_notification_service.dart): FCM init, token, foreground display, background handler, `rideCancelled` stream.
- [route_service.dart](lib/core/services/route_service.dart): OSRM driving route between two points.

**session/**
- [app_user.dart](lib/core/session/app_user.dart): signed-in user's basic profile + role.
- [session_cubit.dart](lib/core/session/session_cubit.dart): who is signed in + per-role logout dispatch.

**theme/**
- [app_colors.dart](lib/core/theme/app_colors.dart): every color token.
- [app_theme.dart](lib/core/theme/app_theme.dart): `AppTheme.darkTheme` (Tajawal text theme, component themes).

**utils/**
- [format_date.dart](lib/core/utils/format_date.dart): "Today, 1:00 PM" style dates in the active language.
- [format_price.dart](lib/core/utils/format_price.dart): `25,000` style prices with Latin digits.
- [open_external_url.dart](lib/core/utils/open_external_url.dart): open `tel:` / WhatsApp / web links.
- [open_store.dart](lib/core/utils/open_store.dart): open the store page (server URL or built-in fallback).

**validators/**
- [auth_validators.dart](lib/core/validators/auth_validators.dart): phone / login password / signup password rules.
- [phone_input_formatter.dart](lib/core/validators/phone_input_formatter.dart): normalizes typed/pasted phone digits to ASCII.

**widgets/**: shared UI (check here before building anything new)
- [account_blocked_widget.dart](lib/core/widgets/account_blocked_widget.dart): "account blocked until …" panel.
- [account_block_gate_widget.dart](lib/core/widgets/account_block_gate_widget.dart): swaps its child for the blocked panel while blocked.
- [app_animated_dialog.dart](lib/core/widgets/app_animated_dialog.dart): `showAppDialog()`, the branded dialog shell with tones (destructive/primary/success/warning).
- [app_bottom_nav_widget.dart](lib/core/widgets/app_bottom_nav_widget.dart): bottom nav used by both shells (`AppNavItem` list).
- [app_brand_bar_widget.dart](lib/core/widgets/app_brand_bar_widget.dart): top bar with logo + name (optional notifications bell).
- [app_choice_chip_widget.dart](lib/core/widgets/app_choice_chip_widget.dart): single-choice pill (e.g. cancel reasons).
- [app_destructive_button_widget.dart](lib/core/widgets/app_destructive_button_widget.dart): full-width red action button with loading state.
- [app_dialog_layout_widget.dart](lib/core/widgets/app_dialog_layout_widget.dart): keeps dialog bodies centered, above the keyboard, scrollable.
- [app_loader_widget.dart](lib/core/widgets/app_loader_widget.dart): the Lottie taxi loader for full-screen/section loading.
- [app_logo_widget.dart](lib/core/widgets/app_logo_widget.dart): rounded logo tile.
- [app_neutral_button_widget.dart](lib/core/widgets/app_neutral_button_widget.dart): outlined neutral button ("Go back", "Log out").
- [app_snack_bar_widget.dart](lib/core/widgets/app_snack_bar_widget.dart): success/error/warning/info snack bars.
- [app_splash_widget.dart](lib/core/widgets/app_splash_widget.dart): startup splash (logo + loader on black).
- [auth_error_banner_widget.dart](lib/core/widgets/auth_error_banner_widget.dart): inline form error banner.
- [auth_form_layout_widget.dart](lib/core/widgets/auth_form_layout_widget.dart): shared scaffold for sign in/up screens.
- [auth_header_widget.dart](lib/core/widgets/auth_header_widget.dart): logo + title + subtitle header for auth screens.
- [auth_language_toggle_widget.dart](lib/core/widgets/auth_language_toggle_widget.dart): one-tap language switch before sign-in.
- [auth_primary_button_widget.dart](lib/core/widgets/auth_primary_button_widget.dart): full-width yellow submit button with loading state.
- [auth_text_field_widget.dart](lib/core/widgets/auth_text_field_widget.dart): labeled text field with optional password toggle.
- [bill_row_widget.dart](lib/core/widgets/bill_row_widget.dart): one bill line (label, detail, value).
- [cancel_reason_dialog_widget.dart](lib/core/widgets/cancel_reason_dialog_widget.dart): cancel-trip dialog with preset reasons (both roles).
- [complaint_dialog_widget.dart](lib/core/widgets/complaint_dialog_widget.dart): `showComplaintDialog()`, the complaint form.
- [contact_us_button_widget.dart](lib/core/widgets/contact_us_button_widget.dart): "Contact us" button for settings.
- [delete_account_button_widget.dart](lib/core/widgets/delete_account_button_widget.dart): quiet destructive "delete account" button.
- [fare_breakdown_widget.dart](lib/core/widgets/fare_breakdown_widget.dart): full bill of a finished ride.
- [fee_chip_widget.dart](lib/core/widgets/fee_chip_widget.dart): small dark pill floating on the map.
- [language_dropdown_widget.dart](lib/core/widgets/language_dropdown_widget.dart): settings language picker card.
- [live_fee_card_widget.dart](lib/core/widgets/live_fee_card_widget.dart): card for live fee timers (clock, fee, status).
- [live_trip_map_widget.dart](lib/core/widgets/live_trip_map_widget.dart): live trip map with car pin, planned route and driven path.
- [logout_footer_widget.dart](lib/core/widgets/logout_footer_widget.dart): logout button + version footer.
- [meta_item_widget.dart](lib/core/widgets/meta_item_widget.dart): icon + label fact (distance, duration).
- [network_photo_widget.dart](lib/core/widgets/network_photo_widget.dart): image from an API photo path with placeholder.
- [paginated_list_widget.dart](lib/core/widgets/paginated_list_widget.dart): generic infinite-scroll list with loading/error/empty/load-more.
- [privacy_policy_dialog_widget.dart](lib/core/widgets/privacy_policy_dialog_widget.dart): `showPrivacyPolicyDialog()`.
- [privacy_policy_markdown_widget.dart](lib/core/widgets/privacy_policy_markdown_widget.dart): themed Markdown renderer.
- [ride_pause_timer_widget.dart](lib/core/widgets/ride_pause_timer_widget.dart): live "trip paused" card.
- [ride_waiting_timer_widget.dart](lib/core/widgets/ride_waiting_timer_widget.dart): live "waiting at pickup" card.
- [role_badge_widget.dart](lib/core/widgets/role_badge_widget.dart): chosen-role pill on auth screens (tap to go back).
- [second_ticker_widget.dart](lib/core/widgets/second_ticker_widget.dart): rebuilds only its builder every second (live timers).
- [settings_row_widget.dart](lib/core/widgets/settings_row_widget.dart): tappable settings row with mirrored chevron.
- [settings_section_widget.dart](lib/core/widgets/settings_section_widget.dart): settings heading + section of rows.
- [trip_fees_overlay_widget.dart](lib/core/widgets/trip_fees_overlay_widget.dart): fees + pause timer overlay at the top of the live map.
- [vehicle_type_icon_widget.dart](lib/core/widgets/vehicle_type_icon_widget.dart): circular icon chosen by vehicle type name.

### `lib/features/`: customer side

**auth/**
- [data/swagger.json](lib/features/auth/data/swagger.json): **the full API contract** (all roles, not just auth).
- [data/datasources/auth_local_data_source.dart](lib/features/auth/data/datasources/auth_local_data_source.dart): saves/restores the customer session (`auth_session`).
- [data/datasources/auth_remote_data_source.dart](lib/features/auth/data/datasources/auth_remote_data_source.dart): customer signup/login/logout (+ FCM token fields).
- [data/models/auth_user_model.dart](lib/features/auth/data/models/auth_user_model.dart): signed-in customer + tokens.
- [data/repositories/auth_repository.dart](lib/features/auth/data/repositories/auth_repository.dart): login/signup/logout/restore, sets `ApiClient.authToken`, 401 probe.
- [presentation/cubit/auth_cubit.dart](lib/features/auth/presentation/cubit/auth_cubit.dart): role selection, sign in, sign up, logout; writes `SessionCubit`.
- [presentation/cubit/auth_state.dart](lib/features/auth/presentation/cubit/auth_state.dart): selected role + submit status + errors.
- [presentation/screens/role_selection_screen.dart](lib/features/auth/presentation/screens/role_selection_screen.dart): customer vs driver choice.
- [presentation/screens/sign_in_screen.dart](lib/features/auth/presentation/screens/sign_in_screen.dart): customer sign in.
- [presentation/screens/sign_up_screen.dart](lib/features/auth/presentation/screens/sign_up_screen.dart): customer sign up (with privacy policy checkbox).
- [presentation/widgets/auth_footer_link_widget.dart](lib/features/auth/presentation/widgets/auth_footer_link_widget.dart): "Don't have an account? Sign up" row.
- [presentation/widgets/privacy_policy_checkbox_field_widget.dart](lib/features/auth/presentation/widgets/privacy_policy_checkbox_field_widget.dart): required agree-to-policy `FormField`.
- [presentation/widgets/role_option_card_widget.dart](lib/features/auth/presentation/widgets/role_option_card_widget.dart): one selectable role card.

**home/**: create a ride request
- [data/datasources/places_remote_data_source.dart](lib/features/home/data/datasources/places_remote_data_source.dart): Photon search + reverse geocoding.
- [data/datasources/ride_request_remote_data_source.dart](lib/features/home/data/datasources/ride_request_remote_data_source.dart): `rides/locations`, `choose-vehicle`, cancel.
- [data/models/place_suggestion_model.dart](lib/features/home/data/models/place_suggestion_model.dart): one search suggestion.
- [data/models/ride_quote_model.dart](lib/features/home/data/models/ride_quote_model.dart): step-1 result (distance, ETA, vehicle quotes).
- [data/models/vehicle_type_quote_model.dart](lib/features/home/data/models/vehicle_type_quote_model.dart): one vehicle type + price.
- [data/repositories/places_repository.dart](lib/features/home/data/repositories/places_repository.dart): place search repository.
- [data/repositories/ride_request_repository.dart](lib/features/home/data/repositories/ride_request_repository.dart): order flow repository.
- [presentation/cubit/home_cubit.dart](lib/features/home/presentation/cubit/home_cubit.dart): quote → choose vehicle → cancel → reset.
- [presentation/cubit/home_state.dart](lib/features/home/presentation/cubit/home_state.dart): picked points, quote, active ride, greeting period.
- [presentation/screens/home_screen.dart](lib/features/home/presentation/screens/home_screen.dart): "create request" tab.
- [presentation/screens/location_picker_screen.dart](lib/features/home/presentation/screens/location_picker_screen.dart): full-screen map picker with search.
- [presentation/widgets/active_ride_card_widget.dart](lib/features/home/presentation/widgets/active_ride_card_widget.dart): summary of the ride just requested.
- [presentation/widgets/location_select_button_widget.dart](lib/features/home/presentation/widgets/location_select_button_widget.dart): From / To card.
- [presentation/widgets/vehicle_type_sheet_widget.dart](lib/features/home/presentation/widgets/vehicle_type_sheet_widget.dart): bottom sheet to compare and pick a vehicle type.
- [presentation/widgets/vehicle_type_tile_widget.dart](lib/features/home/presentation/widgets/vehicle_type_tile_widget.dart): one vehicle type row.

**tracking/**: live ride for the customer
- [data/datasources/customer_ride_socket_service.dart](lib/features/tracking/data/datasources/customer_ride_socket_service.dart): customer ride socket (events → streams, cancel with ack).
- [data/models/ride_driver_model.dart](lib/features/tracking/data/models/ride_driver_model.dart): assigned driver info.
- [data/models/ride_location_model.dart](lib/features/tracking/data/models/ride_location_model.dart): a GPS pin.
- [data/models/ride_vehicle_model.dart](lib/features/tracking/data/models/ride_vehicle_model.dart): assigned vehicle info.
- [data/models/tracked_ride_model.dart](lib/features/tracking/data/models/tracked_ride_model.dart): ride as pushed over the socket.
- [presentation/cubit/ride_tracking_cubit.dart](lib/features/tracking/presentation/cubit/ride_tracking_cubit.dart): consumes socket streams, planned route, cancel.
- [presentation/cubit/ride_tracking_state.dart](lib/features/tracking/presentation/cubit/ride_tracking_state.dart): connection status, ride, driver, location, exit reason.
- [presentation/screens/ride_tracking_screen.dart](lib/features/tracking/presentation/screens/ride_tracking_screen.dart): full-screen tracking; blocks back until the ride ends.
- [presentation/widgets/ride_driver_card_widget.dart](lib/features/tracking/presentation/widgets/ride_driver_card_widget.dart): driver photo, name, rating, vehicle.
- [presentation/widgets/ride_payment_due_dialog_widget.dart](lib/features/tracking/presentation/widgets/ride_payment_due_dialog_widget.dart): "pay the driver X" dialog.
- [presentation/widgets/ride_status_banner_widget.dart](lib/features/tracking/presentation/widgets/ride_status_banner_widget.dart): status line + reconnecting note.
- [presentation/widgets/ride_tracking_map_widget.dart](lib/features/tracking/presentation/widgets/ride_tracking_map_widget.dart): live map with pickup/dropoff/driver pins.
- [presentation/widgets/ride_trip_summary_widget.dart](lib/features/tracking/presentation/widgets/ride_trip_summary_widget.dart): trip summary (route, price) on the tracking screen.

**trips/**: ride history
- [data/datasources/trips_remote_data_source.dart](lib/features/trips/data/datasources/trips_remote_data_source.dart): `GET rides` (paged) and `GET rides/{id}`.
- [data/models/ride_history_model.dart](lib/features/trips/data/models/ride_history_model.dart): `RideStatus` enum (ids 1–6), stops, history row.
- [data/repositories/trips_repository.dart](lib/features/trips/data/repositories/trips_repository.dart): history repository.
- [presentation/cubit/ride_details_cubit.dart](lib/features/trips/presentation/cubit/ride_details_cubit.dart): loads one ride + simplified driven route (state in same file).
- [presentation/cubit/trips_cubit.dart](lib/features/trips/presentation/cubit/trips_cubit.dart): paginated history + status filter.
- [presentation/cubit/trips_state.dart](lib/features/trips/presentation/cubit/trips_state.dart): list, page, filter, status.
- [presentation/screens/ride_details_screen.dart](lib/features/trips/presentation/screens/ride_details_screen.dart): one ride's full details.
- [presentation/screens/trips_screen.dart](lib/features/trips/presentation/screens/trips_screen.dart): "My requests" tab.
- [presentation/widgets/ride_detail_row_widget.dart](lib/features/trips/presentation/widgets/ride_detail_row_widget.dart): label/value row.
- [presentation/widgets/ride_route_map_widget.dart](lib/features/trips/presentation/widgets/ride_route_map_widget.dart): read-only map of the driven path.
- [presentation/widgets/ride_route_widget.dart](lib/features/trips/presentation/widgets/ride_route_widget.dart): vertical pickup → stops → dropoff timeline.
- [presentation/widgets/ride_status_badge_widget.dart](lib/features/trips/presentation/widgets/ride_status_badge_widget.dart): status icon + word badge.
- [presentation/widgets/trip_card_widget.dart](lib/features/trips/presentation/widgets/trip_card_widget.dart): one history row.
- [presentation/widgets/trips_status_filter_widget.dart](lib/features/trips/presentation/widgets/trips_status_filter_widget.dart): status filter chips.

**settings/**: customer settings & profile
- [data/datasources/customer_complaints_remote_data_source.dart](lib/features/settings/data/datasources/customer_complaints_remote_data_source.dart): `POST /api/customer/complaints`.
- [data/datasources/profile_remote_data_source.dart](lib/features/settings/data/datasources/profile_remote_data_source.dart): get/update/delete customer profile.
- [data/models/customer_profile_model.dart](lib/features/settings/data/models/customer_profile_model.dart): API `Customer` schema.
- [data/models/user_profile_model.dart](lib/features/settings/data/models/user_profile_model.dart): what the profile card shows.
- [data/repositories/customer_complaints_repository.dart](lib/features/settings/data/repositories/customer_complaints_repository.dart): complaints repository.
- [data/repositories/profile_repository.dart](lib/features/settings/data/repositories/profile_repository.dart): profile repository.
- [presentation/cubit/delete_account_cubit.dart](lib/features/settings/presentation/cubit/delete_account_cubit.dart): password-confirmed delete, then signs out.
- [presentation/cubit/delete_account_state.dart](lib/features/settings/presentation/cubit/delete_account_state.dart): idle/submitting/success/failure.
- [presentation/cubit/edit_profile_cubit.dart](lib/features/settings/presentation/cubit/edit_profile_cubit.dart): load + save profile, updates the session.
- [presentation/cubit/edit_profile_state.dart](lib/features/settings/presentation/cubit/edit_profile_state.dart): loading/loaded/saving/saved/failure.
- [presentation/cubit/settings_cubit.dart](lib/features/settings/presentation/cubit/settings_cubit.dart): settings screen state from the session.
- [presentation/cubit/settings_state.dart](lib/features/settings/presentation/cubit/settings_state.dart): profile data for the card.
- [presentation/screens/edit_profile_screen.dart](lib/features/settings/presentation/screens/edit_profile_screen.dart): edit personal info.
- [presentation/screens/settings_screen.dart](lib/features/settings/presentation/screens/settings_screen.dart): customer settings tab.
- [presentation/widgets/delete_account_dialog_widget.dart](lib/features/settings/presentation/widgets/delete_account_dialog_widget.dart): delete-account form dialog.
- [presentation/widgets/edit_profile_form_widget.dart](lib/features/settings/presentation/widgets/edit_profile_form_widget.dart): edit form (owns controllers).
- [presentation/widgets/profile_card_widget.dart](lib/features/settings/presentation/widgets/profile_card_widget.dart): avatar, name, contacts, edit row.

**notifications/**: customer in-app notifications
- [data/datasources/notifications_remote_data_source.dart](lib/features/notifications/data/datasources/notifications_remote_data_source.dart): list, mark read, mark all read.
- [data/models/notification_model.dart](lib/features/notifications/data/models/notification_model.dart): `NotificationType` + one notification.
- [data/models/notifications_page_model.dart](lib/features/notifications/data/models/notifications_page_model.dart): page + pagination + unread count.
- [data/repositories/notifications_repository.dart](lib/features/notifications/data/repositories/notifications_repository.dart): repository (+ unread count).
- [presentation/cubit/notifications_cubit.dart](lib/features/notifications/presentation/cubit/notifications_cubit.dart): paginated list, read actions, syncs the badge.
- [presentation/cubit/notifications_state.dart](lib/features/notifications/presentation/cubit/notifications_state.dart): list state.
- [presentation/screens/notifications_screen.dart](lib/features/notifications/presentation/screens/notifications_screen.dart): notifications list screen.
- [presentation/widgets/notification_card_widget.dart](lib/features/notifications/presentation/widgets/notification_card_widget.dart): one notification card (read/unread).

### `lib/driver_features/`: driver side

- [driver_main_wrapper_screen.dart](lib/driver_features/driver_main_wrapper_screen.dart): driver 5-tab shell; resumes an active ride and uploads pending routes.

**driver_auth/**
- [data/datasources/driver_local_data_source.dart](lib/driver_features/driver_auth/data/datasources/driver_local_data_source.dart): saves/restores the driver session (`driver_session`).
- [data/datasources/driver_remote_data_source.dart](lib/driver_features/driver_auth/data/datasources/driver_remote_data_source.dart): driver login/logout, search radius update, startup session probe.
- [data/models/driver_status.dart](lib/driver_features/driver_auth/data/models/driver_status.dart): account status enum (`status_id`).
- [data/models/driver_user_model.dart](lib/driver_features/driver_auth/data/models/driver_user_model.dart): signed-in driver (status, wallet, rating, radius, vehicle, tokens).
- [data/models/driver_vehicle_model.dart](lib/driver_features/driver_auth/data/models/driver_vehicle_model.dart): the driver's vehicle.
- [data/repositories/driver_repository.dart](lib/driver_features/driver_auth/data/repositories/driver_repository.dart): login/logout/restore, sets the token, 401 probe.
- [presentation/cubit/driver_auth_cubit.dart](lib/driver_features/driver_auth/presentation/cubit/driver_auth_cubit.dart): sign in, restore, logout, radius update; writes `SessionCubit`.
- [presentation/cubit/driver_auth_state.dart](lib/driver_features/driver_auth/presentation/cubit/driver_auth_state.dart): driver + submit status.
- [presentation/screens/driver_sign_in_screen.dart](lib/driver_features/driver_auth/presentation/screens/driver_sign_in_screen.dart): driver sign in (no sign-up).

**driver_gps_guard/**
- [data/datasources/gps_status_service.dart](lib/driver_features/driver_gps_guard/data/datasources/gps_status_service.dart): is system GPS on + open settings.
- [presentation/cubit/gps_status_cubit.dart](lib/driver_features/driver_gps_guard/presentation/cubit/gps_status_cubit.dart): watches GPS on/off (singleton).
- [presentation/cubit/gps_status_state.dart](lib/driver_features/driver_gps_guard/presentation/cubit/gps_status_state.dart): `isEnabled` (null until known).
- [presentation/widgets/driver_gps_guard_widget.dart](lib/driver_features/driver_gps_guard/presentation/widgets/driver_gps_guard_widget.dart): wraps a driver screen, shows the dialog when GPS is off.
- [presentation/widgets/gps_required_dialog_widget.dart](lib/driver_features/driver_gps_guard/presentation/widgets/gps_required_dialog_widget.dart): non-dismissable "turn on location" dialog.

**driver_home/**
- [data/datasources/driver_socket_service.dart](lib/driver_features/driver_home/data/datasources/driver_socket_service.dart): driver socket (offers, cancellations, location emit, accept with ack).
- [data/location_ticker.dart](lib/driver_features/driver_home/data/location_ticker.dart): periodic GPS reads for the live location.
- [presentation/cubit/driver_orders_cubit.dart](lib/driver_features/driver_home/presentation/cubit/driver_orders_cubit.dart): ride offer cards + accept.
- [presentation/cubit/driver_orders_state.dart](lib/driver_features/driver_home/presentation/cubit/driver_orders_state.dart): offers + accepting id + errors.
- [presentation/cubit/driver_presence_cubit.dart](lib/driver_features/driver_home/presentation/cubit/driver_presence_cubit.dart): online/offline toggle, socket + ticker lifecycle.
- [presentation/cubit/driver_presence_state.dart](lib/driver_features/driver_home/presentation/cubit/driver_presence_state.dart): connection status.
- [presentation/screens/driver_home_screen.dart](lib/driver_features/driver_home/presentation/screens/driver_home_screen.dart): driver home tab.
- [presentation/widgets/driver_online_toggle_widget.dart](lib/driver_features/driver_home/presentation/widgets/driver_online_toggle_widget.dart): online/offline control.
- [presentation/widgets/driver_order_card_widget.dart](lib/driver_features/driver_home/presentation/widgets/driver_order_card_widget.dart): one ride offer card.
- [presentation/widgets/driver_status_card_widget.dart](lib/driver_features/driver_home/presentation/widgets/driver_status_card_widget.dart): driver identity + status + vehicle summary.

**driver_trip/**
- [data/datasources/driver_trip_location_service.dart](lib/driver_features/driver_trip/data/datasources/driver_trip_location_service.dart): GPS stream during the trip.
- [data/datasources/driver_trip_remote_data_source.dart](lib/driver_features/driver_trip/data/datasources/driver_trip_remote_data_source.dart): active ride, pickup/start/pause/resume/finish/cancel/confirm-payment, route upload.
- [data/datasources/driver_trip_route_local_data_source.dart](lib/driver_features/driver_trip/data/datasources/driver_trip_route_local_data_source.dart): keeps recorded routes until uploaded.
- [data/models/driver_active_ride_model.dart](lib/driver_features/driver_trip/data/models/driver_active_ride_model.dart): `GET rides/active` result, used to resume.
- [data/models/driver_trip_fare_model.dart](lib/driver_features/driver_trip/data/models/driver_trip_fare_model.dart): final fare from `finish`.
- [data/models/driver_trip_payment_model.dart](lib/driver_features/driver_trip/data/models/driver_trip_payment_model.dart): payment split + wallet after commission.
- [data/models/recorded_route_point_model.dart](lib/driver_features/driver_trip/data/models/recorded_route_point_model.dart): recorded GPS sample + pending upload model.
- [data/models/ride_cancellation_model.dart](lib/driver_features/driver_trip/data/models/ride_cancellation_model.dart): who cancelled + reason (socket or push).
- [data/repositories/driver_trip_repository.dart](lib/driver_features/driver_trip/data/repositories/driver_trip_repository.dart): trip actions repository.
- [data/repositories/driver_trip_route_repository.dart](lib/driver_features/driver_trip/data/repositories/driver_trip_route_repository.dart): save + upload routes, `uploadPending()`.
- [data/route_distance_calculator.dart](lib/driver_features/driver_trip/data/route_distance_calculator.dart): length of a recorded route.
- [presentation/cubit/driver_active_ride_cubit.dart](lib/driver_features/driver_trip/presentation/cubit/driver_active_ride_cubit.dart): "was I mid-ride?" check on shell open.
- [presentation/cubit/driver_active_ride_state.dart](lib/driver_features/driver_trip/presentation/cubit/driver_active_ride_state.dart): ride to resume (or none).
- [presentation/cubit/driver_trip_cubit.dart](lib/driver_features/driver_trip/presentation/cubit/driver_trip_cubit.dart): the whole active-ride state machine + route recording.
- [presentation/cubit/driver_trip_state.dart](lib/driver_features/driver_trip/presentation/cubit/driver_trip_state.dart): `DriverTripStatus` (accepted/arrived/inProgress/completed) + data.
- [presentation/screens/driver_trip_screen.dart](lib/driver_features/driver_trip/presentation/screens/driver_trip_screen.dart): active-ride screen.
- [presentation/widgets/driver_fare_dialog_widget.dart](lib/driver_features/driver_trip/presentation/widgets/driver_fare_dialog_widget.dart): what to collect + confirm payment.
- [presentation/widgets/driver_pickup_map_widget.dart](lib/driver_features/driver_trip/presentation/widgets/driver_pickup_map_widget.dart): static map centered on pickup.
- [presentation/widgets/driver_trip_actions_widget.dart](lib/driver_features/driver_trip/presentation/widgets/driver_trip_actions_widget.dart): buttons per trip phase.

**driver_route/**: private on-device route meter
- [data/datasources/route_location_service.dart](lib/driver_features/driver_route/data/datasources/route_location_service.dart): GPS feed + distance.
- [data/datasources/route_session_local_data_source.dart](lib/driver_features/driver_route/data/datasources/route_session_local_data_source.dart): stores the current route.
- [data/models/route_session_model.dart](lib/driver_features/driver_route/data/models/route_session_model.dart): `RoutePhase`, pauses, the route session.
- [data/repositories/route_session_repository.dart](lib/driver_features/driver_route/data/repositories/route_session_repository.dart): save/restore (never throws).
- [presentation/cubit/route_tracker_cubit.dart](lib/driver_features/driver_route/presentation/cubit/route_tracker_cubit.dart): arrived → start → stops → finish, all local.
- [presentation/cubit/route_tracker_state.dart](lib/driver_features/driver_route/presentation/cubit/route_tracker_state.dart): route tab state.
- [presentation/screens/driver_route_screen.dart](lib/driver_features/driver_route/presentation/screens/driver_route_screen.dart): the "Route" tab.
- [presentation/widgets/route_actions_widget.dart](lib/driver_features/driver_route/presentation/widgets/route_actions_widget.dart): buttons per step.
- [presentation/widgets/route_duration_format.dart](lib/driver_features/driver_route/presentation/widgets/route_duration_format.dart): `mm:ss` / `h:mm:ss` formatter.
- [presentation/widgets/route_live_timers_widget.dart](lib/driver_features/driver_route/presentation/widgets/route_live_timers_widget.dart): timers at the top of the route tab.
- [presentation/widgets/route_locate_button_widget.dart](lib/driver_features/driver_route/presentation/widgets/route_locate_button_widget.dart): "locate me" map button.
- [presentation/widgets/route_map_widget.dart](lib/driver_features/driver_route/presentation/widgets/route_map_widget.dart): map with driven path + pins.
- [presentation/widgets/route_summary_card_widget.dart](lib/driver_features/driver_route/presentation/widgets/route_summary_card_widget.dart): finished-route summary.
- [presentation/widgets/route_timer_card_widget.dart](lib/driver_features/driver_route/presentation/widgets/route_timer_card_widget.dart): one live stopwatch card.

**driver_wallet/**
- [data/datasources/driver_wallet_remote_data_source.dart](lib/driver_features/driver_wallet/data/datasources/driver_wallet_remote_data_source.dart): wallet history + financial report.
- [data/models/driver_financial_report_model.dart](lib/driver_features/driver_wallet/data/models/driver_financial_report_model.dart): monthly summary.
- [data/models/wallet_history_model.dart](lib/driver_features/driver_wallet/data/models/wallet_history_model.dart): one page of transactions.
- [data/models/wallet_transaction_model.dart](lib/driver_features/driver_wallet/data/models/wallet_transaction_model.dart): `WalletTransactionType` + one transaction.
- [data/repositories/driver_wallet_repository.dart](lib/driver_features/driver_wallet/data/repositories/driver_wallet_repository.dart): wallet repository.
- [presentation/cubit/driver_financial_report_cubit.dart](lib/driver_features/driver_wallet/presentation/cubit/driver_financial_report_cubit.dart): report for a year/month.
- [presentation/cubit/driver_financial_report_state.dart](lib/driver_features/driver_wallet/presentation/cubit/driver_financial_report_state.dart): report state.
- [presentation/cubit/driver_wallet_cubit.dart](lib/driver_features/driver_wallet/presentation/cubit/driver_wallet_cubit.dart): infinite-scroll transactions (optional type filter).
- [presentation/cubit/driver_wallet_state.dart](lib/driver_features/driver_wallet/presentation/cubit/driver_wallet_state.dart): accumulated list + paging.
- [presentation/screens/driver_wallet_fines_screen.dart](lib/driver_features/driver_wallet/presentation/screens/driver_wallet_fines_screen.dart): fines list (`penalty` transactions).
- [presentation/screens/driver_wallet_screen.dart](lib/driver_features/driver_wallet/presentation/screens/driver_wallet_screen.dart): wallet tab (monthly statement).
- [presentation/widgets/wallet_stat_card_widget.dart](lib/driver_features/driver_wallet/presentation/widgets/wallet_stat_card_widget.dart): one stat tile.
- [presentation/widgets/wallet_statement_summary_card_widget.dart](lib/driver_features/driver_wallet/presentation/widgets/wallet_statement_summary_card_widget.dart): balance hero card.
- [presentation/widgets/wallet_transaction_row_widget.dart](lib/driver_features/driver_wallet/presentation/widgets/wallet_transaction_row_widget.dart): one transaction row.

**driver_profile/**
- [data/datasources/driver_vehicle_remote_data_source.dart](lib/driver_features/driver_profile/data/datasources/driver_vehicle_remote_data_source.dart): `GET /api/driver/vehicle`.
- [data/repositories/driver_vehicle_repository.dart](lib/driver_features/driver_profile/data/repositories/driver_vehicle_repository.dart): vehicle repository.
- [presentation/cubit/driver_vehicle_cubit.dart](lib/driver_features/driver_profile/presentation/cubit/driver_vehicle_cubit.dart): loads the vehicle card.
- [presentation/cubit/driver_vehicle_state.dart](lib/driver_features/driver_profile/presentation/cubit/driver_vehicle_state.dart): vehicle load state.
- [presentation/screens/driver_profile_screen.dart](lib/driver_features/driver_profile/presentation/screens/driver_profile_screen.dart): read-only profile tab.
- [presentation/widgets/driver_vehicle_card_widget.dart](lib/driver_features/driver_profile/presentation/widgets/driver_vehicle_card_widget.dart): vehicle section (all states).
- [presentation/widgets/profile_figure_tile_widget.dart](lib/driver_features/driver_profile/presentation/widgets/profile_figure_tile_widget.dart): headline figure (rating, balance).
- [presentation/widgets/profile_header_widget.dart](lib/driver_features/driver_profile/presentation/widgets/profile_header_widget.dart): photo, name, status.
- [presentation/widgets/profile_info_row_widget.dart](lib/driver_features/driver_profile/presentation/widgets/profile_info_row_widget.dart): label/value row.

**driver_settings/**
- [data/datasources/driver_account_deletion_remote_data_source.dart](lib/driver_features/driver_settings/data/datasources/driver_account_deletion_remote_data_source.dart): deletion request endpoints.
- [data/datasources/driver_complaints_remote_data_source.dart](lib/driver_features/driver_settings/data/datasources/driver_complaints_remote_data_source.dart): `POST /api/driver/complaints`.
- [data/models/driver_deletion_request_model.dart](lib/driver_features/driver_settings/data/models/driver_deletion_request_model.dart): deletion request + status.
- [data/repositories/driver_account_deletion_repository.dart](lib/driver_features/driver_settings/data/repositories/driver_account_deletion_repository.dart): deletion repository.
- [data/repositories/driver_complaints_repository.dart](lib/driver_features/driver_settings/data/repositories/driver_complaints_repository.dart): complaints repository.
- [presentation/cubit/driver_account_deletion_cubit.dart](lib/driver_features/driver_settings/presentation/cubit/driver_account_deletion_cubit.dart): load / request / cancel deletion.
- [presentation/cubit/driver_account_deletion_state.dart](lib/driver_features/driver_settings/presentation/cubit/driver_account_deletion_state.dart): latest request + per-action progress.
- [presentation/cubit/driver_settings_cubit.dart](lib/driver_features/driver_settings/presentation/cubit/driver_settings_cubit.dart): search radius slider.
- [presentation/cubit/driver_settings_state.dart](lib/driver_features/driver_settings/presentation/cubit/driver_settings_state.dart): radius + save status.
- [presentation/screens/driver_settings_screen.dart](lib/driver_features/driver_settings/presentation/screens/driver_settings_screen.dart): driver settings tab.
- [presentation/widgets/driver_account_deletion_section_widget.dart](lib/driver_features/driver_settings/presentation/widgets/driver_account_deletion_section_widget.dart): delete button or request status.
- [presentation/widgets/driver_delete_account_dialog_widget.dart](lib/driver_features/driver_settings/presentation/widgets/driver_delete_account_dialog_widget.dart): deletion request form dialog.
- [presentation/widgets/driver_deletion_status_card_widget.dart](lib/driver_features/driver_settings/presentation/widgets/driver_deletion_status_card_widget.dart): request status card.
- [presentation/widgets/search_radius_slider_widget.dart](lib/driver_features/driver_settings/presentation/widgets/search_radius_slider_widget.dart): 1–10 km slider.

### Other folders

| Path | What it is |
| --- | --- |
| `assets/loader/taxi_loader_yellow.json` | Lottie loader |
| `assets/map_styles/dark_map_style.json` | Google Maps dark style |
| `assets/icons/app_logo_icons/` | Master logo (1024), Android 12 splash variant, exported icon sizes for Android/iOS/web |
| `android/`, `ios/` | Native projects (Maps key wiring, FCM config, permissions: location, foreground service, notifications) |
| `test/` | Tests (see below) |
| `.impeccable/` | Design-tool state (git-ignored) |
| `.claude/` | Claude Code worktrees/state (git-ignored, safe to delete) |

---

## 12. Tests

Run with `flutter test`. Current coverage targets the trickiest logic:

| Test | Covers |
| --- | --- |
| `test/core/app_version/app_version_cubit_test.dart` | Version gate decisions |
| `test/core/localization/locale_cubit_test.dart` | Language load/change/persist |
| `test/core/network/api_error_handler_test.dart` | Error message resolution order |
| `test/core/ride_pause_model_test.dart`, `ride_waiting_model_test.dart` | Live timer / fee snapshots |
| `test/core/widgets/vehicle_type_icon_widget_test.dart` | Vehicle icon mapping |
| `test/driver_features/driver_trip/ride_cancellation_model_test.dart` | Cancellation parsing |
| `test/driver_gps_guard/driver_gps_guard_test.dart` | GPS guard dialog behavior |
| `test/driver_route/route_tracker_cubit_test.dart` | Private route tab state machine |
| `test/driver_trip/driver_trip_resume_test.dart` | Resuming an active ride |
| `test/features/auth/privacy_policy_checkbox_field_widget_test.dart` | Required policy checkbox |
| `test/features/settings/delete_account_test.dart` | Delete account flow |
| `test/helpers/fake_language_repository.dart` | Test fake |

---

## 13. Release checklist

The app version is **set at build time**, not in `pubspec.yaml` (which stays `1.0.0+1`):

1. Decide the new version `X.Y.Z` and a build number `N` that's **higher than the last one uploaded** to the Play Console.
2. Update the footer string `AppConstants.appVersion` in [app_constants.dart](lib/core/constants/app_constants.dart) by hand. It's what Settings shows and is **not** derived from the build.
3. Make sure `android/key.properties`, the keystore, `.env` and `android/local.properties` are in place.
4. If the logo changed: `dart run flutter_launcher_icons` and `dart run flutter_native_splash:create`.
5. `flutter analyze && flutter test`
6. Build:
   ```bash
   flutter build appbundle --release --build-name=X.Y.Z --build-number=N
   # output: build/app/outputs/bundle/release/app-release.aab
   ```
7. Upload to the Play Console. Commit with the message `vX.Y.Z`.
8. **On the backend admin**, update the version-check settings (latest version, minimum version, store URL, maintenance)
   so older installs get the optional or forced update. `package_info_plus` reports the `--build-name` you used, and that's what the server compares.

iOS: `AppConstants.iosStoreUrl` is still empty (TODO), so there's no App Store listing yet.

---

## 14. Gotchas & known TODOs

- **`UNUSED_APIS.md` is out of date.** Driver `pickup`/`start`/`finish` **are** wired now (`driver_trip_remote_data_source.dart`), and customer notifications use the real API.
  Still genuinely unused: `PUT /api/customer/profile/password` (no change-password screen), `POST /api/driver/auth/signup`, `POST /api/driver/rides/{id}/accept` (accept goes through the socket), `GET /` (health).
- **`docs/socket.md`** is referenced in code comments but doesn't exist in the repo.
- **HTTP logging is always on** (`ApiClient._enableLogging = true`), including in release builds, so request/response bodies (tokens, phone numbers) go to the device log. Consider tying it to `kDebugMode`.
- **Backend URL is duplicated** in `api_client.dart` and `socket_client.dart`. Change both when the host changes.
- **`.env` is loaded but nothing reads it**, and it's bundled into the app as an asset. The real Maps key wiring is native (local.properties / Secrets.xcconfig).
- **OSRM and Photon are free public servers** with no SLA or rate guarantees. Plan self-hosting or a paid provider if traffic grows.
- **Drivers can't sign up in-app.** Accounts are created by the operator; pending, suspended and rejected accounts get 403 on login.
- **"customer", not "rider".** Old saved sessions may contain role `'rider'`; `auth_local_data_source.dart` maps it. Don't remove that mapping.
- **Background push handler runs in its own isolate.** No `sl`, no cubits; keep it self-contained.
- **Arabic digits:** never let `intl` format numbers inside l10n strings. Pass pre-formatted strings (`formatPrice`) so digits stay Latin.
- **Portrait-only**, one dark theme. Set in `main.dart` / `AppTheme`.
- **Firebase project id is `samrt-taxi`** (typo is real; don't "fix" it).
- The socket comment in `socket_client.dart` says "never a customer token", but customer tracking and account-block sockets do use the customer token. The comment is stale.

---

## 15. Recipes: common changes

**Add a new API call**
1. Find the endpoint in `swagger.json` (method, body, response). If it isn't there, ask the backend team before coding.
2. Add the path to `ApiEndpoints`.
3. Add a method to the feature's `*_remote_data_source.dart` using the injected `Dio` (from `ApiClient`).
4. Parse into a model (`fromJson`, Equatable) in `data/models/`.
5. Expose it from the repository and let `ApiException` propagate (or wrap it in the feature's `*Exception`).
6. Call it from the cubit, emitting loading → success/error states.
7. Register any new classes in `injection.dart`.
8. If the endpoint has new error literals, add them to `api_error_messages.dart` + both `.arb` files.

**Add a new screen**
1. `presentation/screens/foo_screen.dart` provides the cubit with `BlocProvider(create: (_) => sl<FooCubit>())`.
2. If other features navigate to it: add a route constant + case in `AppRouter` (and an args class if it needs data).
3. Use `BlocSelector`/`buildWhen` to avoid rebuilding the whole screen. Reuse `core/widgets`.
4. Support RTL (directional insets) and both languages.

**Add a UI string**
1. Add the key to `lib/core/l10n/app_en.arb` (with `@key` description/placeholders) **and** `app_ar.arb`.
2. Run `flutter gen-l10n` (or just build).
3. Use `context.l10n.key` in widgets, `AppStrings.current.key` elsewhere.

**Add a new driver feature**
Create `lib/driver_features/driver_<name>/{data,presentation}/...`, register it in `injection.dart` under a new section, and add a tab in `DriverMainWrapperScreen` if needed.

**Change colors or typography**
Edit the tokens in `AppColors` / `AppTheme`. Never hard-code colors in widgets. Keep [DESIGN.md](DESIGN.md) in sync.
