# Valideer `widgetType` bij dashboard widgets

Status: Voltooid

Afgewerkt na audit-opvolging: 2026-03-07

Bronbestand: `packages/pma_core/lib/models/dashboard_types.dart`, `packages/pma_core/lib/providers/dashboard/dashboard_providers.dart` en `packages/pma_core/lib/repository/models/dashboard_models.dart`

Beschrijving:
Voorkom ongeldige `widgetType` waarden bij toevoegen/wijzigen.

Wat toe te voegen:
- Validatiefunctie/enums voor ondersteunde `widgetType` waarden.
- Tests en descripers in errors/exception messages.

Audit-opvolging uitgevoerd:
- Contract expliciet gemaakt: validatiepaden gebruiken nu strict parsing (`DashboardWidgetType.fromString`) en gooien `InvalidWidgetTypeException` bij ongeldige waarden.
- Permissieve parsing is behouden voor UI-robuustheid via `DashboardWidgetType.fromStringOrDefault(...)` op callsites die user/layout-id input parseren.
- Tests gealigneerd op strict gedrag voor `validateWidgetType` en `DashboardItem.fromJson`, inclusief assertie op foutboodschap/exception type.

Prioriteit: Middel

Labels: `area:dashboard`, `bug`
