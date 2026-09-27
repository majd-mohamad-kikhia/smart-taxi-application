# Flutter Project Rules

## 1. Project Structure

The project follows a feature-first architecture with two main root folders:


lib/
├── core/
└── features/


---

## 2. Core Layer (core/)

The core folder contains global, reusable, and application-wide logic.

### It includes:

- Networking configuration (Dio setup, interceptors)
- Routing configuration
- App constants
- Core services
- Shared helper functions
- Reusable global widgets
- App themes and colors
- Bundles and utilities
- Shared models (only if truly global)

### Rules:

- core must not depend on any feature.
- Only global logic belongs in core.
- If something is used by multiple features, move it to core.

---

## 3. Features Layer (features/)

Each feature must be isolated and modular.

### Structure:

features/
└── feature_name/
├── data/
│ ├── datasources/
│ └── models/
└── presentation/
├── bloc/
├── screens/
└── widgets/


### Rules:

- Features must not depend directly on other features.
- Shared logic must be moved to core.
- Each feature must be independent and self-contained.
- No cross-feature imports.

---

## 4. Naming Conventions

- File names: snake_case
- Class names: PascalCase
- Screens must end with Screen
- Widgets must end with Widget
- Bloc files must end with Bloc
- Cubit files must end with Cubit
- State files must end with State

---

## 5. Architecture Rules

- Do not place business logic inside UI widgets.
- UI layer handles rendering and user interaction only.
- Data layer must not contain UI-related code.
- No direct API calls inside UI or Bloc/Cubit.
- All network calls must go through the data layer.
- Avoid circular imports.

---

## 6. Responsiveness Rules

- UI must support:
  - Mobile
  - Tablet
  - Large screens (Web/Desktop)
- Avoid hardcoded widths and heights.
- Use LayoutBuilder, MediaQuery, or responsive helpers.
- Extract reusable responsive widgets when needed.

---

## 7. State Management Rules

- Avoid unnecessary state emissions.
- Minimize widget rebuilds.
- Use BlocBuilder selectively.
- Prefer BlocSelector when possible.
- States must be immutable.
- Avoid emitting identical states.
- Separate UI state from server state.

---

## 8. Performance Rules

- Use const constructors whenever possible.
- Dispose controllers properly.
- Avoid heavy logic inside build().
- Avoid deep widget nesting.
- Extract reusable components.
- Use pagination for large lists.
- Do not rebuild entire screens unnecessarily.

---

## 9. Dependency Injection

- No manual instantiation inside UI.
- All dependencies must be injected.
- Injection setup must be inside core/injection/.
- Do not create repositories or services directly in widgets.

---

## 10. Error Handling

- Never swallow exceptions.
- All failures must return structured error models.
- Network errors must be handled centrally.
- UI must properly represent:
  - Loading state
  - Success state
  - Error state

---

## 11. Networking Standards

- Use Dio only.
- Define all endpoints in a centralized location.
- Interceptors must handle:
  - Logging
  - Token injection
  - Error parsing
- Do not duplicate API logic.
- Before implementing any feature that talks to the API, check `lib/features/auth/data/swagger.json` for the exact endpoint, method, request body, and response schema — never guess field names or shapes. If the endpoint isn't in swagger.json yet, ask before implementing against assumptions.

---

## 12. Safety Rules (AI Protection)

- Never modify more than one feature without confirmation.
- Never refactor global structure without explicit instruction.
- Do not rename folders or architecture layers unless instructed.
- Do not introduce new dependencies without confirmation.

---

## 13. Code Quality Standards

- Follow SOLID principles.
- Keep files focused and small.
- Avoid files exceeding reasonable size limits.
- Extract reusable logic into dedicated classes.
- Write clean and readable code over clever code.
- Before building any new UI piece, check `core/widgets/` and the current feature's `presentation/widgets/` for an existing widget that already does it, and reuse it instead of rebuilding it.
- While building UI, if any part of it (a card, row, badge, button, list, dialog, etc.) is generic enough to be reused elsewhere in the app, extract it into its own `*_widget.dart` file immediately — in `core/widgets/` if it's usable by more than one feature, or the feature's own `presentation/widgets/` if it's feature-specific.

---

This document defines the development standards and architectural rules for the Flutter project.
All generated or modified code must strictly follow these rules.