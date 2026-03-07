# Project Filter Scopes

Date: 2026-03-07
Scope: TODO 005 follow-up

## Canonical Types

- Provider-level filter: `ProjectFilter` in `providers/project/project_providers.dart`
- Repository-level filter: `ProjectFilter` in `models/project_filter.dart`

## Mapping Rule

Provider code must convert via `ProjectFilter.toRepositoryFilter()` before calling repository filtering APIs.

## Repository-Supported Fields

- `status`
- `searchQuery`
- `priority`
- `startDate`
- `endDate`
- `tags`

## Provider-Only Fields

These stay in provider scope and are not forwarded directly to repository filters:

- `ownerId`
- `requiredTags`
- `sortBy` / `sortAscending`
- `viewName` / `viewMode` / dashboard-related metadata
- `dueDateStart` / `dueDateEnd` (unless repository contract is extended)

## Why

This bridge keeps UI flexibility while preventing drift and ambiguity between two filter shapes introduced during modularization.
