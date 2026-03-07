# Async ophalen van instellingen in auth providers

Status: Voltooid

Afgewerkt na audit-opvolging: 2026-03-07

Bronbestand: `packages/pma_core/lib/providers/auth/auth_providers.dart`

Beschrijving:
Sommige plekken doen sync checks op settings; gebruik de async settings repository waar nodig.

Wat toe te voegen:
- Vervang sync checks met `await ref.read(settingsRepositoryProvider.future)` of geschikte pattern.
- Zorg voor juiste loading/error states in providers.

Audit-opvolging uitgevoerd:
- `recaptchaServiceProvider` omgezet naar `FutureProvider<RecaptchaService>` met expliciete async settings-initialisatie via `await ref.read(settingsRepositoryProvider.future)`.
- Sync fallback (`maybeWhen(..., orElse: HiveSettingsRepository.new)`) verwijderd om impliciete niet-geinitialiseerde settings te voorkomen.
- Login-flow wacht nu expliciet op `recaptchaServiceProvider.future` voordat captcha-token wordt opgevraagd.
- Guard-test toegevoegd om regressie naar sync fallbackconstructie te voorkomen.

Prioriteit: Middel

Labels: `area:auth`, `bug`
