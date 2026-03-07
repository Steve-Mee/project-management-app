# Introduceer `IAuthRepository` interface

Status: Voltooid

Afgewerkt na audit-opvolging: 2026-03-07

Bronbestand: `packages/pma_core/lib/repository/i_auth_repository.dart`

Beschrijving:
Momenteel gebruiken providers concrete implementaties; een abstract repo maakt testen en swapping eenvoudiger.

Wat toe te voegen:
- Maak `lib/core/repository/i_auth_repository.dart` met benodigde methoden (login, logout, getRoleById, getUsers, inviteUser, etc.).
- Pas providers aan om `authRepositoryProvider` te leveren als `IAuthRepository`.
- Update concrete implementatie en tests.

Audit-opvolging uitgevoerd:
- Interface opgesplitst in gerichte sub-contracten zonder breaking wijziging:
	- `IAuthSessionRepository`
	- `IAuthDirectoryRepository`
	- `IAuthRateLimitRepository`
	- `IAuthRepository` blijft aggregate contract voor backward compatibility.
- Ambigue "future methods" commentblok verwijderd uit de interface.
- Implementatie-agnostische contracttests toegevoegd voor kritieke auth-flow invarianten (login/logout/current-user/session-state stream).

Prioriteit: Middel

Labels: `area:auth`, `refactor`
