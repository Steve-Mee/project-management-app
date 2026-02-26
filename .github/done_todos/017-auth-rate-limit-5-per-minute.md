# Specificeer en implementeer: max 5 login attempts per minuut

Bronbestand: `lib/core/providers/auth_providers.dart`

Beschrijving:
Concretiseer de rate limit policy voor login.

Wat toe te voegen:
- Implementatie voor 5 attempts/minute met backoff en optionele captcha.
- Tests die de limiet en unblock-logica valideren.

Prioriteit: Hoog

Labels: `security`, `area:auth`
