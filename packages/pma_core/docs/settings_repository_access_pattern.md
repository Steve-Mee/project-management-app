# Settings Repository Access Pattern

Source file: `packages/pma_core/lib/providers/auth/auth_providers.dart`

Recommended pattern for async settings access:

```dart
final settings = await ref.read(settingsRepositoryProvider.future);
await settings.setAutoLoginEnabled(true);
```

When to use `read(...future)`:
- Inside imperative async methods (for example notifier actions like `login`, `setEnabled`, `setHelpLevel`).
- When you need a one-time resolved repository instance and do not want reactive re-evaluation.

When to use `watch(...future)`:
- In reactive provider `build()` methods where rebuild behavior is intentionally tied to dependency changes.
- Avoid this in imperative action methods to prevent unnecessary re-evaluation complexity.

Guardrails:
- Do not use sync fallback constructors (for example `HiveSettingsRepository.new`) for unresolved async settings state.
- In auth flows, prefer explicit `await ref.read(settingsRepositoryProvider.future)` and handle errors at callsite.
