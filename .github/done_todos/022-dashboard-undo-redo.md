# Undo/Redo functionaliteit voor dashboard wijzigingen

Bronbestand: `lib/core/providers/dashboard_providers.dart`

Beschrijving:
Gebruikers moeten wijzigingen aan dashboards kunnen terugdraaien en opnieuw toepassen.

Wat toe te voegen:
- Eenvoudige geschiedenis stack (undo/redo) in provider of service.
- API: `undo()`, `redo()`, en `canUndo`/`canRedo`.
- UI hooks (knoppen) en tests.

Prioriteit: Laag-Middel

Labels: `area:dashboard`, `feature`
