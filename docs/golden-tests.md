# Golden Tests

Issue: `#060-golden-tests-ui`

This project uses Flutter golden tests to detect visual regressions in critical
UI components.

## Covered Components

- Dashboard card (`test/golden/dashboard_card_test.dart`)
- AI chat bubble (`test/golden/ai_chat_bubble_test.dart`)
- Gantt chart (`test/golden/gantt_chart_test.dart`)
- Task list item context (`test/golden/task_list_item_test.dart`)
- Theme switcher (`test/golden/theme_switcher_test.dart`)

## Run Golden Tests Locally

Run all tests tagged as golden:

```bash
flutter test --tags=golden
```

Run a single golden test file:

```bash
flutter test test/golden/dashboard_card_test.dart
```

## Update Goldens

When a visual change is intentional, regenerate golden images:

```bash
UPDATE_GOLDENS=1 flutter test --tags=golden
```

On PowerShell:

```powershell
$env:UPDATE_GOLDENS='1'; flutter test --tags=golden; Remove-Item Env:UPDATE_GOLDENS
```

## Review Checklist

- Confirm the visual change is intentional.
- Inspect updated files under `test/goldens/`.
- Re-run golden tests without `UPDATE_GOLDENS` to verify green baseline.
- Include a short note in PR description explaining why baseline changed.
