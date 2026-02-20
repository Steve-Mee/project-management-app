# Overzicht van resterende TODO's

Onderstaand een gegroepeerde lijst van alle "TODO"-aantekeningen die in de codebase voorkomen (relevante bestanden onder `lib/`). Voor elk item staat: bronbestand, korte omschrijving en wat er verwacht wordt dat toegevoegd of uitgewerkt wordt.

---

**`lib/core/providers/project_providers.dart`**
- TODO: Move to separate file when repository implementations grow
  - Verwachte actie: Verplaats `IProjectRepository` naar een aparte interface-file (bv. `lib/core/repository/i_project_repository.dart`) en update import locaties.
- TODO: Add pagination methods: getProjectsPaginated(int page, int limit)
  - Verwachte actie: Voeg paginatie-API toe aan `IProjectRepository` en implementatie in `ProjectRepository`.
- TODO: Add filtering methods: getProjectsByStatus(String status)
  - Verwachte actie: Voeg filter-functies toe aan repository en expose via providers/families.
- TODO: Add pagination for large project lists
  - Verwachte actie: Pas `projectsProvider` aan of voeg nieuw paginated provider toe.
- TODO: Add filtering/sorting parameters via family provider
  - Verwachte actie: Maak `projectsProvider` of `filteredProjectsProvider` uitbreidbaar met parameters (status, zoekquery, sortering).
- TODO: Add caching for individual projects
  - Verwachte actie: Implementeer cache voor `projectByIdProvider` of verplaats caching-logica naar repository.
- TODO: Implement efficient single project fetch if repository supports it
  - Verwachte actie: Voeg `getProjectById` efficient implementatie toe aan `IProjectRepository` en concrete repositoryen.
- TODO: Add more filter parameters as needed
  - Verwachte actie: Breid `ProjectFilter` uit (date-range, priority, owner, tags).
- TODO: Add more filter conditions as needed
  - Verwachte actie: Breid filterimplementatie in `filteredProjectsProvider` uit.
- TODO: Add more filter fields (date range, priority, etc.)
  - Verwachte actie: Zie boven.
- TODO: Remove when tests are updated to not require this
  - Verwachte actie: Herzie en vereenvoudig `ProjectsNotifier.initialize()` zodra tests aangepast zijn.
- TODO: Deprecate in favor of projectByIdProvider for better performance
  - Verwachte actie: Migreer interne callers naar `projectByIdProvider` en markeer `getProjectById` als deprecated.

---

**`lib/core/providers/auth_providers.dart`**
- TODO: Consider using an abstract interface for easy testing/swapping
  - Verwachte actie: Maak een `IAuthRepository` interface en update producers om die te gebruiken.
- TODO: Add rate limiting for login attempts
  - Verwachte actie: Implementeer hulpmiddel (memory/redis) om max login pogingen per tijdsvenster af te dwingen.
- TODO: Add biometric authentication support
  - Verwachte actie: Voeg optionele biometry provider/integratie toe (met feature flag en platform checks).
- TODO: Implement proper async checking with settings
  - Verwachte actie: Haal instellingen asynchroon op uit `settingsRepository` i.p.v. sync benadering.
- TODO: Implement rate limiting (max 5 attempts per minute)
  - Verwachte actie: Concretiseer en implementeer limiet (backoff + captcha fallback).
- TODO: Access settings repository properly
  - Verwachte actie: Gebruik `ref.read(settingsRepositoryProvider.future)` op de juiste plekken.
- TODO: Add search/filtering capabilities
  - Verwachte actie: Voeg zoek- en filteropties toe aan gebruikers/auth providers indien nodig.

---

**`lib/core/providers/dashboard_providers.dart`**
- TODO: Add validation for widgetType
  - Verwachte actie: Valideer `widgetType` bij aanmaken/opslaan van dashboard widgets.
- TODO: Add position constraints/boundaries
  - Verwachte actie: Forceer minimale/maximale posities en grenzen voor drag/resize van widgets.
- TODO: Add undo/redo functionality
  - Verwachte actie: Implementeer eenvoudige historie stack voor dashboard wijzigingen.
- TODO: Add dashboard templates
  - Verwachte actie: Voorzie preset layouts en template opslaan/laden.
- TODO: Add collaborative dashboard sharing
  - Verwachte actie: Plan API + opslag voor gedeelde dashboards en permissies.
- TODO: Add error handling/logging
  - Verwachte actie: Voeg try/catch + AppLogger.event/error melding toe bij IO/DB bewerkingen.
- TODO: Consider using an abstract interface for easy testing/swapping
  - Verwachte actie: Maak repository/interface voor dashboard data.
- TODO: Add caching for requirements
  - Verwachte actie: Cache `requirements` data met TTL of lokaal storage.
- TODO: Add offline requirements storage
  - Verwachte actie: Sla requirements lokaal op (Hive) en sync bij netwerk beschikbaarheid.
- TODO: Import projectsProvider when available
  - Verwachte actie: Koppel dashboard items aan projecten zodra `projectsProvider` stabiel is.

---

**`lib/core/providers/ai_chat_provider.dart`**
- TODO: Make rate limits configurable
  - Verwachte actie: Verplaats magic-rate-LIMIT in configuratie (env of settings repository).
- TODO: Make max requests per window configurable (currently 10 per minute)
  - Verwachte actie: Expose instelling en gebruik bij rate-limiter initialisatie.
- TODO: Add exponential backoff for rate limits
  - Verwachte actie: Voeg retry/backoff logica toe bij tijdelijke throttling.
- TODO: Add request queuing for burst handling
  - Verwachte actie: Introduceer queue en worker die requests burst-smooth verwerkt.
- TODO: Add different rate limits for different AI operations
  - Verwachte actie: Ondersteun per-endpoint of per-operatie limieten (chat, embeddings, file ops).

---

**`lib/core/services/ai_parsers.dart`**
- TODO: Implement XML parsing for future AI models
  - Verwachte actie: Voeg XML parser (package:xml) toe om AI-output of imports te parsen waar nodig.
- TODO: Implement YAML parsing for future AI models
  - Verwachte actie: Voeg YAML parser (package:yaml) toe en test conversies.

---

**`lib/core/providers/ai/ai_usage_provider.dart`**
- TODO: Implement usage history tracking
  - Verwachte actie: Bewaar tokens/requests per gebruiker/project in persistente opslag en expose history via provider.

---

**`lib/core/providers.dart`**
- TODO: Consider creating additional provider files for:
  - `task_providers.dart`, `notification_providers.dart`, `sync_providers.dart`, `analytics_providers.dart`
  - Verwachte actie: Splits grote provider barrel en implementeer ontbrekende provider bestanden waar logisch.

---

Opmerkingen en prioritering (advies):
- Hoge prioriteit: provider/repository interface-werk (project/auth/dashboard) zodat testing en swap van implementaties eenvoudig is.
- Middel: AI rate-limiting en queuing (productie-robustheid bij AI-features).
- Laag: UI-verbeteringen zoals dashboard templates, biometrics, en extra filters tenzij een feature roadmap dit versnelde.

Als je wilt, kan ik deze lijst als issue-template omzetten naar individuele GitHub issues of direct kleine PR's maken per taak (bijv. "Introduce IProjectRepository file", "Add pagination to project repository"). Geef aan hoe je de vervolgstappen wilt: (1) opsplitsen in issues, (2) meteen implementeren van enkele items, of (3) alleen bewaren als checklist.
