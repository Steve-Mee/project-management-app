# Voeg zoek- en filtermogelijkheden toe aan auth/user providers

Status: Voltooid

Afgewerkt na audit-opvolging: 2026-03-07

Bronbestand: `packages/pma_core/lib/providers/auth/auth_providers.dart`

Beschrijving:
Gebruikersbeheer heeft baat bij zoeken en filters (role, status).

Wat toe te voegen:
- Provider/families voor `searchUsers(query)` en `getUsers({role, status})`.
- UI-component voorbeelden en tests.

Audit-opvolging uitgevoerd:
- `UsersFilter` API en runtimegedrag gealigneerd: niet-geimplementeerde `status` filter verwijderd uit model en filterlogica.
- Placeholder branch voor status-filtering verwijderd om mismatch tussen API-oppervlak en effectieve filtering te vermijden.
- User filtering tests bijgewerkt naar de ondersteunde criteria (`searchQuery`, `role`).

Prioriteit: Laag-Middel

Labels: `area:auth`, `feature`
