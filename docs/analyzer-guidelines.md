# Analyzer Guidelines

This project uses `analysis_options.yaml` with `flutter_lints` plus stricter rules for const usage.

## Baseline Commands

Use these commands for local quality checks:

```bash
flutter analyze
flutter test
```

## Important Note About Info Diagnostics

Do not rely on `flutter analyze --no-fatal-infos` in backlog notes.

- `flutter analyze` already treats info-level diagnostics as non-fatal unless fatal flags are explicitly enabled.
- Keep CI and local checks aligned with plain `flutter analyze` unless there is a deliberate policy change.

## Current Rule Highlights

From `analysis_options.yaml`:

- `prefer_const_constructors: true`
- `prefer_const_declarations: true`
- `avoid_print: false`
- `use_key_in_widget_constructors: false`

These settings are intentional for this repository and should be revisited only with team agreement.
