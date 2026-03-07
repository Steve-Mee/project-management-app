# Undo/Redo functionaliteit voor dashboard wijzigingen

Status: Voltooid

Afgewerkt na audit-opvolging: 2026-03-07

Bronbestand: `packages/pma_core/lib/providers/dashboard/dashboard_providers.dart`

Beschrijving:
Gebruikers moeten wijzigingen aan dashboards kunnen terugdraaien en opnieuw toepassen.

Wat toe te voegen:
- Eenvoudige geschiedenis stack (undo/redo) in provider of service.
- API: `undo()`, `redo()`, en `canUndo`/`canRedo`.
- UI hooks (knoppen) en tests.

Audit-opvolging uitgevoerd:
- Expliciet history-suspend mechanisme toegevoegd tijdens undo/redo persist (`_runWithHistoryMutationSuspended`) zodat `saveConfig` geen undo/redo indexmutatie veroorzaakt in navigatieflows.
- `saveConfig` mutileert history-index alleen buiten gesuspendeerde history-navigatie.
- Regressietest toegevoegd die verifieert dat undo/redo-persist geen extra history-entries dupliceert.

Prioriteit: Laag-Middel

Labels: `area:dashboard`, `feature`
