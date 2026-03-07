# Accessibility Guide (Issue #068)

This document captures the accessibility acceptance checklist, manual test flows, and command snippets used for verification in this project.

## Acceptance Checklist

- [x] Missing semantic labels on buttons, icons, lists
  - Added reusable helpers in `lib/core/utils/accessibility_helper.dart`.
  - Applied semantics to project list/card/dialog, onboarding, offline indicator, AI chat, list/kanban/table views.
- [x] Low contrast in dark mode
  - Updated theme palette and component states in `lib/core/theme.dart`.
  - Added contrast guard tests in `test/core/theme_contrast_test.dart`.
- [x] Screen reader readiness (TalkBack / VoiceOver)
  - Added semantics labels/hints/values and list wrappers (`wrapSemanticList`) in key screens.
  - Added project-view accessibility widget tests in `test/features/project/project_views_accessibility_test.dart`.

## Flutter Accessibility Inspector Workflow

Use this during development for quick semantic validation:

1. Run app with semantics debugger enabled:

```bash
flutter run --dart-define=ENABLE_SEMANTICS_DEBUGGER=true
```

2. In VS Code/DevTools, inspect semantic boundaries and labels while navigating:
- Project list and cards
- Onboarding controls and forms
- Offline indicator status bar and sheet
- AI chat input and send controls
- Kanban/list/table views

3. Confirm every actionable control has a meaningful announcement:
- `label`: what control/content is
- `hint`: what action it performs (where needed)
- `value`: progress/count/state information

## TalkBack (Android) Test Commands

Use an emulator or connected Android device.

Check connected devices:

```bash
adb devices
```

Enable TalkBack service (device/emulator dependent package name):

```bash
adb shell settings put secure enabled_accessibility_services com.google.android.marvin.talkback/com.google.android.marvin.talkback.TalkBackService
adb shell settings put secure accessibility_enabled 1
```

Disable after test:

```bash
adb shell settings put secure accessibility_enabled 0
```

Manual validation pass:
- Swipe navigation reads labels in logical order
- Buttons/icons announce intent
- List/table/kanban sections announce context and item counts
- Progress indicators announce percentage values

## VoiceOver (iOS) Test Commands

There is no stable, universal non-interactive CLI toggle for VoiceOver in all simulator/device setups.
Use commands below to prepare simulator, then enable VoiceOver from Settings.

Boot simulator and open Settings:

```bash
open -a Simulator
xcrun simctl boot "iPhone 15"
xcrun simctl launch booted com.apple.Preferences
```

Then in iOS Settings:
- Accessibility -> VoiceOver -> On

Manual validation pass:
- Rotor and swipe navigation move through controls in expected order
- Semantic labels/hints are clear and non-duplicative
- Editable fields are announced as text fields with purpose

## Web Accessibility Notes

For Flutter web builds:

```bash
flutter run -d chrome
```

Recommended checks:
- Keyboard-only navigation (`Tab`, `Shift+Tab`, `Enter`, `Space`, arrow keys)
- Browser accessibility tree (Chrome DevTools -> Elements -> Accessibility)
- Lighthouse Accessibility audit
- Optional automated checks with axe DevTools extension

Verify:
- Focus indicators are visible
- Interactive elements are reachable and announced
- No critical color-contrast regressions in dark mode

## Test Commands

Theme contrast regression tests:

```bash
flutter test test/core/theme_contrast_test.dart
```

Project view semantics tests:

```bash
flutter test test/features/project/project_views_accessibility_test.dart
```

Run both with coverage:

```bash
flutter test --coverage test/core/theme_contrast_test.dart test/features/project/project_views_accessibility_test.dart
```

## Accessibility Audit Matrix

This matrix makes manual and automated accessibility verification traceable per primary user flow.

| Area | Key Screens / Widgets | Automated Evidence | Manual Evidence (TalkBack/VoiceOver/Web) | Last Updated |
| --- | --- | --- | --- | --- |
| Onboarding flow | Welcome, onboarding actions, form controls | Covered by semantics helper usage and onboarding semantics integration | Checklist documented in this guide and validated during issue #068 completion pass | 2026-03-07 |
| Project views | Project list, cards, list/kanban/table switches | `test/features/project/project_views_accessibility_test.dart` | Checklist documented in this guide and validated during issue #068 completion pass | 2026-03-07 |
| Offline/sync UX | App bar offline indicator, sync sheet controls | Widget-level interaction/semantics coverage in offline indicator tests | Checklist documented in this guide and validated during issue #068 completion pass | 2026-03-07 |
| Theme contrast | Dark theme color contrast pairs | `test/core/theme_contrast_test.dart` | Visual confirmation workflow documented (Inspector + screen reader pass) | 2026-03-07 |
| AI chat controls | Input field, send action, state messaging | Semantics wrappers integrated in AI chat UI path | Checklist documented in this guide and validated during issue #068 completion pass | 2026-03-07 |

### Release Verification Note

Before a production release, rerun the manual checklist sections in this file for at least one Android TalkBack target, one iOS VoiceOver target, and web keyboard-only navigation, then refresh the matrix date.

## Reference

- Flutter accessibility guide: https://docs.flutter.dev/ui/accessibility-and-internationalization/accessibility
