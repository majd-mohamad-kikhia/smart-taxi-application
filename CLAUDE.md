# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

**مشوار (Mshoar)** — a Flutter ride-hailing app UI (package name `mshoar`). This is currently a
UI/UX prototype: every cubit ships only mock/simulated data (see "Mock data, no backend" below).
There is no `data`/`domain` split with real repositories or API clients yet — `data/models` in
each feature holds plain model classes constructed with hardcoded values.

The app is Arabic-first: locale is pinned to `ar_SA`, and the entire UI is forced to RTL via a
top-level `Directionality` wrapper in `main.dart`. English strings should not be introduced into
UI-facing text without being asked.

## Commands

Standard Flutter CLI, run from the repo root:

- `flutter pub get` — install dependencies after touching `pubspec.yaml`.
- `flutter analyze` — static analysis (uses `analysis_options.yaml`, based on `flutter_lints`).
- `flutter test` — run all tests in `test/`.
- `flutter test test/widget_test.dart` — run a single test file.
- `flutter run` — run on a connected device/emulator/browser.
- `flutter build <platform>` — e.g. `flutter build apk`, `flutter build ios`, `flutter build web`.

There is currently only one test file (`test/widget_test.dart`, a basic smoke test).

## Architecture

Feature-first structure under `lib/features/<feature>/`, each split into:

- `data/models/` — plain, mostly `Equatable`-free model classes (immutable, `const` constructors).
- `presentation/cubit/` — one `Cubit<State>` + one `State` (extends `Equatable`, with an `initial()`
  factory and a `copyWith`) per feature.
- `presentation/screens/` — the feature's screen widget(s).
- `presentation/widgets/` — screen-specific widgets, not shared elsewhere.

Features: `booking`, `favorites`, `home`, `settings`, `tracking`, `trips`.

Shared/global code lives under `lib/core/`:

- `core/injection/injection.dart` — single `setupInjection()` using `get_it`. Every cubit is
  registered with `registerFactory` (new instance per resolution, not a singleton). Called once in
  `main()` before `runApp`.
- `core/routing/app_router.dart` — a single `AppRouter` class with route-name constants and a
  `switch`-based `onGenerateRoute`. All navigation goes through named routes
  (`Navigator.of(context).pushNamed(AppRouter.x)`), not direct widget pushes. Unknown routes fall
  back to `HomeScreen`.
- `core/theme/` — `AppColors` and `AppTheme` (Material theme, uses `google_fonts`).
- `core/widgets/` — cross-feature shared widgets, e.g. `AppNavHelper` (shared bottom-nav tap
  routing logic used by multiple tab screens) and `AppAnimatedDialog`.
- `core/constants/app_constants.dart` — single `AppConstants` class holding spacing/radius/duration
  scales and map defaults (default OSM tile URL, default lat/lng/zoom for Riyadh). UI code should
  reference these constants rather than hardcoding new magic numbers.

### Cubit wiring pattern

Screens obtain their cubit from the service locator and immediately call `initialize()`:

```dart
create: (_) => sl<FeatureCubit>()..initialize(),
```

`initialize()` re-emits (or builds) the mock initial state — it does not currently fetch anything
real. When adding a new feature, follow this same `sl<Cubit>()..initialize()` + `BlocProvider`
wiring, register the cubit as a factory in `injection.dart`, and add its route to `AppRouter`.

### Mock data, no backend

Cubits simulate async work with `Future.delayed` (e.g. `BookingCubit.confirmBooking`) and otherwise
mutate in-memory state via `copyWith`. Model instances with realistic Arabic sample data are
constructed directly inside state factories (e.g. `HomeState.initial()`). There are no HTTP
clients, no persistence, and several cubit methods are explicit `// TODO` stubs for
not-yet-implemented navigation/flows (see `HomeCubit.requestRideToDestination`,
`repeatLastTrip`, `applyPromoCode`). Don't assume a service/repository layer exists — check the
relevant cubit before wiring new behavior through one.

### Map integration

Map screens use `flutter_map` + `latlong2` (OpenStreetMap tiles), not Google Maps. Tile URL and
default camera position come from `AppConstants` (`osmTileUrl`, `defaultMapLat/Lng/Zoom`).

## Platform targets

Standard Flutter multi-platform scaffold exists for `android`, `ios`, `linux`, `macos`, `web`, and
`windows`, but active development is centered on `lib/`. The `build/` directory is generated output
and should not be edited or treated as source.
