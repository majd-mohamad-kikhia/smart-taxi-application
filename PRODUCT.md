# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

## Users

Two first-class roles, weighted equally when their needs conflict (confirmed):

- **Riders (customers):** request a taxi, wait for a driver to accept, track the trip, pay the fare, and review past trips.
- **Drivers:** sign in, accept and run trips (pickup, waiting, pause, finish), and check their wallet: earnings, commissions, bonuses, and administrative fines.

A third role, managers/dispatchers, appears in the API (manager-initiated cancellations, admin routes). It is not part of this app's UI.

## Product Purpose

Smart Taxi (internal and package name "Mshoar") is the rider and driver app for a company-operated taxi service. It connects riders to the operator's own drivers in real time and keeps fares, waiting rules, and driver earnings explicit.

## Positioning

Company-operated fleet, not an open marketplace (confirmed). One operator manages its drivers and sets the rules: free waiting minutes, then a per-minute fee; commissions on trips; bonuses; administrative fines. A manager can intervene in or cancel trips.

## Operating Context

- Rider: requesting and waiting for a pickup, often outdoors.
- Driver: in a car, working through a trip while the phone is in use.
- Trip lifecycle (from the codebase): pending, accepted, driver arrived, in progress, completed or cancelled. Cancellation can come from the customer, the driver, or a manager.
- Realtime dispatch over sockets. Push notifications via Firebase. Google Maps for location, routes, and a live trip map. Drivers go through a GPS guard before taking trips.

## Capabilities and Constraints

- Arabic and English (gen-l10n); the app is RTL-aware. Which language is the default or primary market language is undecided.
- Fare model (from the codebase): base fare + distance fare, plus waiting fee after free time, with an estimated vs. final price and a fare breakdown.
- Not yet wired up (see UNUSED_APIS.md): rider change-password, rider notifications from the real API, driver signup, and driver arrived/start/finish API calls.
- The app currently ships one theme across all OSes. Whether it should adapt per OS is not decided; the platform is recorded as android.
- Architecture rules live in CLAUDE.md (feature-first, no cross-feature imports, Dio only, swagger-first for API work).

## Brand Commitments

- Name: Smart Taxi (the Arabic store description is "تطبيق رحلات ذكي"). The codebase name is "Mshoar".
- Existing logo and launcher icon: `assets/icons/app_logo_icons/icon-master-1024.png`. Loader animation: `assets/loader/taxi_loader_yellow.json`.

## Evidence on Hand

No testimonials, customer counts, or benchmarks exist in the repository. Do not invent any. The README is the Flutter default and carries no product information.

## Product Principles

1. Rider and driver are equal first-class users; design for each one's real situation, not a single average user.
2. Money and rules are never a surprise: fares, waiting fees, commissions, and fines are shown explicitly and explained.
3. Trip state is always legible: the user can tell at a glance where the trip stands and what happens next.
4. Every async surface has designed loading, success, and error states (also a CLAUDE.md requirement).
5. Arabic and English are both complete experiences, with correct RTL layout and no copy that only works in one language.

## Accessibility & Inclusion

No product-specific standard has been set. The app must work for Arabic (RTL) and English readers and across phone, tablet, and large-screen layouts (per CLAUDE.md).
