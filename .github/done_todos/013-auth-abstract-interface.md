# Introduceer `IAuthRepository` interface

Bronbestand: `lib/core/providers/auth_providers.dart`

Beschrijving:
Momenteel gebruiken providers concrete implementaties; een abstract repo maakt testen en swapping eenvoudiger.

Wat toe te voegen:
- Maak `lib/core/repository/i_auth_repository.dart` met benodigde methoden (login, logout, getRoleById, getUsers, inviteUser, etc.).
- Pas providers aan om `authRepositoryProvider` te leveren als `IAuthRepository`.
- Update concrete implementatie en tests.

Prioriteit: Middel

Labels: `area:auth`, `refactor`
