# Legacy UI Kit Removal

Issue: `#056-remove-legacy-ui-kit`

This project no longer depends on the legacy UI kit stack (`get`, `GetX`, `GetMaterialApp`).
The app runs on pure Flutter Material + Riverpod + custom widgets.

## Scope Completed

- Removed `get: ^4.x` from root dependencies (`pubspec.yaml`).
- Removed active imports/usages of `package:get/get.dart`.
- Confirmed `main.dart` bootstraps with `MaterialApp.router`.
- Consolidated theme usage in `lib/core/theme.dart` with Material 3 configuration.

## Replacement Checklist

- App shell and routing:
  - `GetMaterialApp` -> `MaterialApp` / `MaterialApp.router`
- State management:
  - `GetX` controllers/state -> Riverpod providers/notifiers
- Navigation:
  - GetX route helpers -> Navigator/Router API used by app routes
- UI components:
  - legacy UI kit components -> Material widgets and project-specific widgets

## Regression Guard (Quick Checks)

- `flutter analyze` reports no `get` or `GetX` integration errors.
- Global text search confirms no active `package:get/get.dart` usage in app code.
- Dashboard and project feature screens run on Material/Riverpod imports only.

## Notes

- Existing documentation/tasks that refer to "legacy UI package" and "GetWidget" map to this same migration objective.
- Keep future UI migrations aligned with Material 3 tokens in `lib/core/theme.dart`.
