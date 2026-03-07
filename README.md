# Project Management App

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)](https://flutter.dev/) [![Riverpod](https://img.shields.io/badge/Riverpod-2.0+-blue?logo=flutter)](https://riverpod.dev/) [![Supabase](https://img.shields.io/badge/Supabase-2.0+-3ECF8E?logo=supabase)](https://supabase.com/) [![Sentry](https://img.shields.io/badge/Sentry-Enabled-red?logo=sentry)](https://sentry.io/) [![codecov](https://codecov.io/gh/Steve-Mee/project-management-app/branch/main/graph/badge.svg)](https://codecov.io/gh/Steve-Mee/project-management-app)

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT) [![GitHub Stars](https://img.shields.io/github/stars/Steve-Mee/project-management-app)](https://github.com/Steve-Mee/project-management-app/stargazers) [![GitHub Forks](https://img.shields.io/github/forks/Steve-Mee/project-management-app)](https://github.com/Steve-Mee/project-management-app/network/members) [![GitHub Issues](https://img.shields.io/github/issues/Steve-Mee/project-management-app)](https://github.com/Steve-Mee/project-management-app/issues)

## Description

Flutter-based Project Management App for tracking projects, tasks, and sub-tasks. Features AI chat integration, offline Hive storage, Supabase backend, user authentication, roles/permissions, and customizable dashboards. Supports multi-language and desktop/mobile. Built with Riverpod for state management.

## CI/CD

[![Flutter Test](https://github.com/Steve-Mee/project-management-app/actions/workflows/flutter_test.yml/badge.svg)](https://github.com/Steve-Mee/project-management-app/actions/workflows/flutter_test.yml)
[![codecov](https://codecov.io/gh/Steve-Mee/project-management-app/branch/main/graph/badge.svg)](https://codecov.io/gh/Steve-Mee/project-management-app)

- `flutter_test.yml`: Runs Flutter analyze, tests with coverage, and web build on pull requests and pushes to `main`.
- `flutter_desktop.yml`: Runs matrix desktop builds for Windows, macOS, and Linux on pull requests and pushes to `main`.
- `semantic_pr.yml`: Validates pull request titles using conventional commit semantics.
- `release.yml`: Runs semantic-release automation on pushes to `main`.

## Release Pipeline

Release pipeline documentation for issue `#075-release-pipeline-preparation` is available in [`docs/release-pipeline.md`](docs/release-pipeline.md).

Quick flow:

1. Conventional Commit merged to `main`.
2. `release.yml` runs semantic-release.
3. semantic-release updates `CHANGELOG.md`, bumps `pubspec.yaml`, and publishes GitHub Release.
4. Published release triggers `fastlane.yml` to distribute iOS TestFlight beta, Android internal track beta, and desktop artifacts.
5. Manual beta distribution is available via `Fastlane Distribution` workflow dispatch.

### Fastlane Release Automation

Issue `#075-release-pipeline-preparation` adds Fastlane lanes for iOS, Android, and desktop release builds.

- Fastlane configuration: `fastlane/Fastfile`
- Fastlane app metadata defaults: `fastlane/Appfile`
- Ruby dependencies: `Gemfile`, `fastlane/Pluginfile`

Available lanes:

- `bundle exec fastlane beta`: Runs iOS TestFlight internal upload + Android internal track upload + desktop (macOS/Windows) builds.
- `bundle exec fastlane release`: Runs iOS App Store Connect upload + Android production upload + desktop (macOS/Windows) builds.
- `bundle exec fastlane ios beta`: iOS internal beta only.
- `bundle exec fastlane android beta`: Android internal beta only.
- `bundle exec fastlane desktop_beta`: Desktop release artifacts only.

Required environment variables:

- `IOS_APP_IDENTIFIER`: iOS bundle ID (example: `com.example.projectManagementApp`).
- `APPLE_ID`: Apple developer account email.
- `APPLE_TEAM_ID`: Apple developer team ID.
- `ANDROID_PACKAGE_NAME`: Android application ID.
- `SUPPLY_JSON_KEY`: Absolute path to Google Play service account JSON key file.

## Screenshots

The repository currently contains four screenshot assets in `images/`.

### Dashboard Overview

![Dashboard Overview](images/one.jpg)

### Project Workspace

![Project Workspace](images/two.jpg)

### Planning And Tracking

![Planning And Tracking](images/three.jpg)

### Team Collaboration

![Team Collaboration](images/four.jpg)

## Gantt Chart (Modern)

The app now uses a modern `gantt_chart`-based timeline wrapper (`ModernGanttChart`) with Riverpod-driven task data.

- Material 3 styling via `Theme.of(context).colorScheme`
- Automatic dark mode support
- Touch gestures:
   - Horizontal pan/scroll on timeline
   - Drag task bars to reschedule (with callback persistence)
- Controls:
   - Zoom in/out
   - Pan left/right
   - Export menu (CSV/PDF via platform share)
- Offline-first data source through Hive-backed repositories and `tasksProvider`

Planned screenshot coverage (offline mode, deep link invites, export flows, and platform-specific views) remains on the roadmap and will be added as assets are captured.

## Architecture

The application follows a clean architecture pattern with the following layers:

```mermaid
graph TD
    A[Core] --> B[Features]
    B --> C[Providers]
    C --> D[Repositories]
    D --> E[Supabase]
    D --> F[Hive]
```

- **Core**: Fundamental utilities and shared code
- **Features**: UI and business logic modules
- **Providers**: State management with Riverpod
- **Repositories**: Data access abstraction
- **Supabase/Hive**: External data sources

## Modular Architecture

The app now uses a modular core package (`packages/pma_core`) to separate reusable core logic from app-specific feature UI.

- `pma_core` contains shared providers, services, repository logic, models, utils, and shared widgets
- Feature screens stay in the main app under `lib/features/...` and import shared code via `package:pma_core/...`
- Router-level deferred loading is enabled for feature routes to reduce initial load work

For status and acceptance checklist details, see [`docs/modularization.md`](docs/modularization.md).

## Feature Flags (Supabase)

Issue `#071-feature-flags-supabase` adds a Supabase-backed feature flag system with Hive cache fallback.

- Core service: `packages/pma_core/lib/core/services/feature_flag_service.dart`
- Main Riverpod provider: `packages/pma_core/lib/core/providers/feature_flag_provider.dart`
- Shared resolver/model: `packages/pma_core/lib/core/feature_flags/feature_flag_resolver.dart`, `packages/pma_core/lib/core/feature_flags/feature_flag.dart`
- Admin UI + route: `packages/pma_core/lib/core/widgets/feature_flags_admin.dart`, `lib/core/routes.dart` (`/admin/feature-flags`)
- Legacy compatibility shim: `packages/pma_core/lib/services/ab_testing_service.dart` (deprecated; forwards to feature flags)

Current integrated flags:

- `ai_assistant_enabled`: gates AI chat send/generate actions
- `ai_advanced_planning`: gates planning/proposals/final plan actions
- `gantt_chart_enabled`: controls Gantt screen fallback vs chart UI
- `onboarding_enabled`: controls onboarding wizard display/auto-skip

Operational behavior:

- Cache-first reads with Hive fallback (`feature_flags` box + `last_fetch`)
- Auto-refresh every 30 minutes and refresh on app resume
- Fail-open defaults in UI flows while flags are loading/unavailable
- Supabase RLS-protected writes (JWT `app_metadata.role == 'admin'`)
- Audit events recorded in `analytics_events` as `feature_flag_changed`

See [`docs/feature-flags.md`](docs/feature-flags.md) for the implementation checklist and acceptance criteria mapping.

## Analytics

Issue `#073-analytics-implementation` introduces a backend-agnostic analytics layer.

- Abstract contract: `packages/pma_core/lib/core/services/analytics_service.dart` (`AnalyticsService`)
- Default implementation: `SupabaseAnalyticsService`
- Riverpod provider: `analyticsServiceProvider` in `packages/pma_core/lib/core/providers.dart`
- Tracked issue events: `project_created`, `task_completed`, `ai_used`, `invite_sent`

Implementation details, event mapping, and schema suggestions are documented in [`docs/analytics.md`](docs/analytics.md).

## Error Handling

Issue `#072-global-error-boundary` introduces centralized crash handling and Sentry observability.

- Global boundary widget: `lib/core/widgets/error_boundary.dart`
- Bootstrap wiring: `lib/main.dart` (`runZonedGuarded` + root `ErrorBoundary`)
- Sentry wrapper service: `lib/core/services/sentry_service.dart`
- Logger bridge with breadcrumb forwarding: `packages/pma_core/lib/services/app_logger.dart`

Debug validation flags:

- `DEBUG_THROW_STARTUP_ERROR=true`: forces startup exception to validate zone/Sentry capture
- `DEBUG_THROW_POSTFRAME_ERROR=true`: throws post-frame Flutter error to validate boundary fallback UI

Implementation checklist and test steps are documented in [`docs/error-boundary.md`](docs/error-boundary.md).

## PWA Support

Issue `#074-pwa-support-web` adds explicit web PWA support assets and offline behavior.

- Manifest: `web/manifest.json`
- Service worker strategy: Flutter-generated `flutter_service_worker.js` (single-worker setup)
- Bootstrap integration: `web/index.html` -> `flutter_bootstrap.js`
- Build command: `flutter build web --release --pwa-strategy=offline-first`

For acceptance checklist, verification flow, and install steps, see [`docs/pwa-support.md`](docs/pwa-support.md).

## Documentation

| File | Description |
|------|-------------|
| [00_START_HERE.md](00_START_HERE.md) | Getting started guide for the project |
| [DASHBOARD_GUIDE.md](DASHBOARD_GUIDE.md) | Guide for using the dashboard features |
| [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) | Summary of the implementation details |
| [INTEGRATION_GUIDE.md](INTEGRATION_GUIDE.md) | Guide for integrating various components |
| [docs/gantt-chart.md](docs/gantt-chart.md) | Gantt upgrade checklist, architecture notes, and verification |
| [docs/feature-flags.md](docs/feature-flags.md) | Supabase feature flag checklist, provider/service summary, and acceptance mapping |
| [docs/analytics.md](docs/analytics.md) | Issue #073 analytics checklist, event mapping, service usage, and `analytics_events` schema suggestion |
| [docs/error-boundary.md](docs/error-boundary.md) | Global error boundary acceptance checklist, test procedure, and AppLogger/Sentry integration notes |
| [docs/pwa-support.md](docs/pwa-support.md) | Issue #074 PWA checklist, offline test steps, and Chrome install instructions |
| [docs/release-pipeline.md](docs/release-pipeline.md) | Issue #075 release checklist, semantic-release/Fastlane flow, manual beta trigger, and secrets |
| [docs/release-hardening-checklist.md](docs/release-hardening-checklist.md) | Handover checklist met Done/Pending External, secrets en go-live sign-off |
| [docs/modularization.md](docs/modularization.md) | Issue #070 modularization acceptance checklist and deferred routing summary |
| [docs/model-location-policy.md](docs/model-location-policy.md) | Canonical model ownership policy (`pma_core` as source of truth) and de-duplication plan |
| [docs/legacy-ui-kit-removal.md](docs/legacy-ui-kit-removal.md) | Issue #056 migration note and replacement checklist for removing legacy UI kit/GetX usage |
| [docs/supabase_fcm_setup.md](docs/supabase_fcm_setup.md) | Issue #058 end-to-end Supabase Edge Function to FCM setup, payload shape, and production checklist |
| [NAVIGATION_GUIDE.md](NAVIGATION_GUIDE.md) | Guide for navigating the application |
| [QUICK_REFERENCE.md](QUICK_REFERENCE.md) | Quick reference for key features |
| [TODO.md](TODO.md) | List of tasks and todos |
| [REMAINING_TODOS.md](REMAINING_TODOS.md) | Remaining tasks to be completed |
| [FINAL_STATUS.md](FINAL_STATUS.md) | Final status report |
| [FILE_INDEX.md](FILE_INDEX.md) | Index of all project files |

## Features

- 📋 **Project & Task Management**: Create, organize, and track projects with hierarchical tasks and sub-tasks
- 🤖 **AI Chat Integration**: Built-in AI assistant for project insights and task suggestions
- 💾 **Offline Storage**: Local Hive database for offline functionality and data persistence
- 🔄 **Real-time Synchronization**: Instant updates across devices with Supabase real-time
- ☁️ **Cloud Backend**: Supabase integration for collaboration and data synchronization
- 🔐 **User Authentication**: Secure login system with role-based permissions and biometric support
- 💳 **Payment Integration**: Stripe integration for premium features and subscriptions
- 📊 **Customizable Dashboards**: Personalized views and analytics for project tracking
- 📈 **Gantt Charts**: Visual project timelines and scheduling
- 📄 **Export Capabilities**: Export projects to PDF and CSV formats
- 🔗 **Deep Linking**: Share project invites via deep links
- 🌍 **Multi-language Support**: Internationalization with support for multiple languages
- 🖥️ **Cross-platform**: Runs on iOS, Android, Windows, macOS, and Linux
- ⚡ **State Management**: Riverpod for predictable and scalable app state

## Tech Stack

- **Frontend**: Flutter
- **State Management**: Riverpod
- **Local Storage**: Hive
- **Backend**: Supabase
- **Authentication**: Supabase Auth
- **AI Integration**: OpenAI API
- **Internationalization**: Flutter Intl
- **Testing**: Flutter Test, Integration Tests

<!-- Add version badges or more details -->

## Setup

### Prerequisites

- Flutter SDK (3.0+)
- Dart SDK
- Supabase account (for backend)
- OpenAI API key (for AI features)

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd my_project_management_app
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Install Fastlane dependencies:
   ```bash
   bundle install
   ```

### Configuration

4. Set up environment variables:
   - Copy `.env.example` to `.env` in the project root
   - Fill in the required values (see `.env.example` for details)
   
   **Required:**
   - `SUPABASE_URL` - Your Supabase project URL
   - `SUPABASE_ANON_KEY` - Your Supabase anonymous key
   
   **Optional:**
   - `OPENAI_API_KEY` - For AI chat features
   - `STRIPE_PUBLISHABLE_KEY` & `STRIPE_SECRET_KEY` - For payment features
   - `SENTRY_DSN` - For error reporting
   - `LOG_LEVEL` - Application logging level
   - `FIREBASE_API_KEY` - For Firebase services

5. Run the app:
   ```bash
   flutter run
   ```

### Fastlane Setup And Usage

1. Install Ruby + Bundler.
2. Run `bundle install` at repository root.
3. Export required env vars (`IOS_APP_IDENTIFIER`, `APPLE_ID`, `APPLE_TEAM_ID`, `ANDROID_PACKAGE_NAME`, `SUPPLY_JSON_KEY`).
4. Run beta pipeline: `bundle exec fastlane beta`.
5. Run production pipeline: `bundle exec fastlane release`.

### GitHub Actions Secrets (Repository Settings)

Add these in `Settings -> Secrets and variables -> Actions`.

iOS / TestFlight:

- `IOS_APP_IDENTIFIER`
- `APPLE_ID`
- `APPLE_TEAM_ID`
- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_API_ISSUER_ID`
- `APP_STORE_CONNECT_API_KEY_CONTENT`
- `IOS_P12_BASE64`
- `IOS_P12_PASSWORD`
- `IOS_MOBILEPROVISION_BASE64`
- `TESTFLIGHT_INTERNAL_GROUPS` (comma-separated group names, e.g. `QA,Product`)

Android / Google Play Internal Track:

- `ANDROID_PACKAGE_NAME`
- `SUPPLY_JSON_KEY_BASE64`
- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

Semantic Release:

- `GITHUB_TOKEN` (provided automatically by GitHub Actions)

Notes:

- iOS lanes require macOS with Xcode and valid signing configured.
- Windows/macOS desktop lanes build artifacts only; publishing is handled outside Fastlane.

### Accessibility Contrast Checks

Run the WCAG AA theme contrast tests introduced for issue `#068-accessibility-improvements`:

```bash
flutter test test/core/theme_contrast_test.dart
```

Run the same check with coverage output:

```bash
flutter test --coverage test/core/theme_contrast_test.dart
```

### Accessibility

Accessibility implementation and manual validation checklist are documented in [`docs/accessibility.md`](docs/accessibility.md).

Quick commands:

```bash
flutter run --dart-define=ENABLE_SEMANTICS_DEBUGGER=true
flutter test test/core/theme_contrast_test.dart test/features/project/project_views_accessibility_test.dart
```

<!-- Add platform-specific setup instructions -->

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Make your changes and add tests
4. Run tests: `flutter test`
5. Submit a pull request

<!-- Add code of conduct, issue templates, etc. -->

## Roadmap

- **Advanced Analytics**: Implement comprehensive reporting and analytics dashboard for project insights
- **Mobile App Stores**: Release native mobile apps on iOS App Store and Google Play Store
- **Third-party Integrations**: Add integrations with tools like Slack, Jira, and Trello
- **Enhanced AI Features**: Expand AI capabilities for project prediction and automated task suggestions

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

Built with ❤️ using Flutter

## App Size Analysis (Issue #065)

Reference report and raw output template: [`docs/app-size-analysis.md`](docs/app-size-analysis.md)

### Before/After Summary

| Metric | Before | After | Delta | Delta % |
|------|------:|------:|------:|------:|
| APK (armeabi-v7a, MB) | `TBD` | `TBD` | `TBD` | `TBD` |
| APK (arm64-v8a, MB) | `TBD` | `TBD` | `TBD` | `TBD` |
| APK (x86_64, MB) | `TBD` | `TBD` | `TBD` | `TBD` |
| Dart code total | `TBD` | `TBD` | `TBD` | `TBD` |
| Assets total | `TBD` | `TBD` | `TBD` | `TBD` |
| Fonts total | `TBD` | `TBD` | `TBD` | `TBD` |

### Optimizations Performed

- Removed unused icon package: `cupertino_icons` (no `CupertinoIcons` usage).
- Kept Material icons only via `uses-material-design: true` (`Icons.*` is actively used).
- Removed unused dependency: `riverpod` (kept `flutter_riverpod`).
- Removed unused dependency: `dart_openai`.
- Removed unused dependency: `langchain`.
- Removed unused dependency: `langchain_openai`.
- Removed unused dependency: `flutter_ai_agent_tool`.
- Removed unused dependency: `flutter_local_notifications`.
- Removed unused dependency: `timezone`.
- Removed unused dependency: `legacy_gantt_chart` (legacy package no longer used in runtime code).
- Kept only referenced asset configuration in `pubspec.yaml`: `.env`.
- No custom font declarations were present, so no custom font bundles are included.

### Final APK Size Per ABI

| ABI | APK File | Final Size (Bytes) | Final Size (MB) |
|------|------|------:|------:|
| armeabi-v7a | `app-armeabi-v7a-release.apk` | `TBD` | `TBD` |
| arm64-v8a | `app-arm64-v8a-release.apk` | `TBD` | `TBD` |
| x86_64 | `app-x86_64-release.apk` | `TBD` | `TBD` |

### Re-run Analysis

```bash
flutter build apk --analyze-size --split-per-abi
```
