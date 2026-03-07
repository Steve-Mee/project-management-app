# Error Boundary and Crash Reporting (Issue #072)

This document captures the final implementation and verification steps for `#072-global-error-boundary`.

## Acceptance Checklist

- [x] Wraps the entire app (root app is wrapped with `ErrorBoundary` in `lib/main.dart`).
- [x] Catches all Flutter errors and exceptions (`ErrorBoundary` installs `FlutterError.onError`, `PlatformDispatcher.instance.onError`, and `ErrorWidget.builder`; `main()` also uses `runZonedGuarded`).
- [x] Shows a nice error screen with `Restart App` button (Material 3 fallback UI in `lib/core/widgets/error_boundary.dart`).
- [x] Logs to AppLogger + sends to Sentry (`ErrorBoundary` logs through `AppLogger` and forwards exceptions through `SentryService.captureException(...)`).
- [x] Uses Sentry for breadcrumbs (breadcrumbs are emitted from `ErrorBoundary`, `SentryService`, and forwarded automatically from `AppLogger` user action/event/debug/warning paths).
- [x] Automatic breadcrumbs for key user actions (added in project/task/AI/onboarding flows for add/update/delete-style mutations and onboarding actions).

## What Was Integrated

- Global boundary widget: `lib/core/widgets/error_boundary.dart`
- Bootstrap wiring: `lib/main.dart`
- Sentry wrapper: `lib/core/services/sentry_service.dart`
- App-level logger bridge: `packages/pma_core/lib/services/app_logger.dart`
- Feature breadcrumbs: `packages/pma_core/lib/repository/impl/hive_project_repository.dart`, `packages/pma_core/lib/providers/task/task_providers.dart`, `packages/pma_core/lib/providers/ai/ai_chat_providers.dart`, `lib/core/widgets/onboarding_wizard.dart`

## How To Test

### 1. Verify uncaught startup error capture (zone-level)

Run:

```bash
flutter run --dart-define=DEBUG_THROW_STARTUP_ERROR=true
```

Expected:

- App throws during startup.
- Error is captured by `runZonedGuarded` path in `main()`.
- Error is logged via `AppLogger` and sent to Sentry.

### 2. Verify Flutter framework error capture + ErrorBoundary UI

Run:

```bash
flutter run --dart-define=DEBUG_THROW_POSTFRAME_ERROR=true
```

Expected:

- App launches, then throws a post-frame `FlutterError`.
- `ErrorBoundary` fallback screen appears.
- `Restart App` button clears boundary state and re-renders app subtree.
- Error is logged to `AppLogger` and sent to Sentry.

### 3. Verify breadcrumb emission from user actions

Perform these actions:

- Add/update/delete a project.
- Add/update/delete a task.
- Send AI chat message and clear AI queue/history.
- Complete/skip onboarding and send onboarding invite.

Expected:

- `user.action` breadcrumbs appear in Sentry event trails.
- Event/debug/warning logs from `AppLogger` also appear as breadcrumbs.

### 4. Verify in Sentry dashboard

In Sentry, check:

- Project receives new error events from startup/post-frame tests.
- Event details include stack traces and tags/extras where set.
- Breadcrumb timeline includes `app.event`, `app.warning`, `app.debug`, and `user.action` categories.

## AppLogger Integration Notes

- `AppLogger` now forwards `event(...)` -> `app.event`, `warning(...)` -> `app.warning`, `debug(...)` -> `app.debug`, and `userAction(...)` -> `user.action`.
- `AppLogger.error(...)` also calls `Sentry.captureException(...)` in addition to local logging.
- All Sentry forwarding is best-effort and non-fatal; logging does not throw if Sentry is unavailable.

## Code Review Checklist (User Action Breadcrumbs)

Use this checklist for new feature PRs to keep `user.action` breadcrumb coverage consistent:

- For every critical user mutation (create/update/delete/send/invite/confirm), add one `AppLogger.userAction(...)` call near the success path.
- Include stable identifiers in `data` when available (`projectId`, `taskId`, `userId`, `feature`).
- Avoid duplicate breadcrumbs for the same UI action (log once at the canonical success boundary).
- Keep breadcrumb messages action-oriented and searchable (for example: `User created project`, `User completed task`).
- For failure paths, log warning/error separately and keep `userAction` focused on intentional user interactions.
