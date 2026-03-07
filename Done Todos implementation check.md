# Done Todos: implementation check

## Globaal overzicht

- Totaal done todo's: 75
- Geanalyseerd in deze batch: 001-005
- Resterend: 006-075
- Batchgrootte: 5 per iteratie

### Overkoepelende observaties (tot nu)

- TODO 001 is functioneel uitgevoerd, maar de oorspronkelijke padverwijzingen in de todo zelf zijn door TODO 070 (modularisatie naar `packages/pma_core`) deels verouderd. Dit is geen functionele regressie, wel documentatie-drift.
- TODO 002-005 zijn grotendeels aanwezig, maar er is nog inconsistentie tussen model-niveau filtertype en provider-niveau uitgebreid filtertype, plus een kleine naam-afwijking (`projectsPaginatedProvider` i.p.v. `paginatedProjectsProvider`).

---

## 001 - IProjectRepository interface extracted

### Opvolging status

- DONE (afgewerkt op 2026-03-07): voorgestelde opschoning, documentatie-update en contracttests uitgevoerd.

### Wat is correct geimplementeerd

- Interface staat in apart bestand: `packages/pma_core/lib/repository/i_project_repository.dart`.
- Interface bevat uitgebreide set methoden inclusief repository lifecycle en sharing helpers.
- Providers gebruiken interface-injectie via `projectRepositoryProvider` in `packages/pma_core/lib/providers/project/project_providers.dart`.
- Test-fakes implementeren de interface, wat swapbaarheid bevestigt (`test/projects_provider_test.dart`, `test/sync_providers_test.dart`).

### Wat ik nog zou wijzigen

- Dubbele comments opruimen in interfacebestand (meerdere regels zijn letterlijk gedupliceerd), voor onderhoudbaarheid.
- Inline "future methods to consider" comments verwijderen of omzetten naar formele docs, omdat de methods inmiddels effectief bestaan.

### Wat ik nog zou toevoegen

- Contracttests op interface-niveau voor cruciale invarianten (bijv. paginatie en filterconsistentie over implementaties).
- Kort ADR-achtig document dat vastlegt waarom `IProjectRepository` in `pma_core` zit (zodat padverwijzingen in done_todos minder snel verouderen).

### Wat ik nog zou verwijderen

- Verouderde referenties in TODO 001 naar `lib/core/...` padstructuur (overschreven door TODO 070).

### Impact van jongere TODO op oudere TODO

- TODO 070 heeft TODO 001 niet teniet gedaan, maar wel de oorspronkelijke bestandslocatie verplaatst. De implementatie blijft geldig; de documentatie in TODO 001 is deels achterhaald.

---

## 002 - Voeg paginatie API toe voor projecten

### Opvolging status

- DONE (afgewerkt op 2026-03-07): input-validatie, deterministische sortering en uitgebreide paginatie-edge-case tests toegevoegd.

### Wat is correct geimplementeerd

- Interface bevat paginatie API: `getProjectsPaginated({int page = 1, int limit = 20, ProjectFilter? filter})` in `packages/pma_core/lib/repository/i_project_repository.dart`.
- Hive-implementatie aanwezig met page/limit en optionele filtertoepassing: `packages/pma_core/lib/repository/impl/hive_project_repository.dart`.
- Repository test de slicelogica over meerdere pagina's: `test/project_repository_test.dart`.

### Wat ik nog zou wijzigen

- Input-validatie voor `page` en `limit` ontbreekt of is implicit. Voeg harde guards toe (`page >= 1`, `limit > 0`) en eenduidige foutboodschap.
- Sorteervolgorde is niet expliciet gestandaardiseerd voor paginatie. Voeg deterministische sortering toe (bijv. `createdAt desc` of `name asc`) voor stabiele paginaresultaten.

### Wat ik nog zou toevoegen

- Tests voor randgevallen:
  - `page=0`, `limit=0`, negatieve waarden
  - filter + paginatie gecombineerd
  - lege dataset
- Metadata/total count variant (bijv. `PaginatedResult<T>`) als UI totale pagina's nodig heeft.

### Wat ik nog zou verwijderen

- Geen directe verwijdering nodig; wel eventuele impliciete aannames over insertion-order expliciteren.

---

## 003 - Voeg filtering-methoden toe aan project repository

### Opvolging status

- DONE (afgewerkt op 2026-03-07): gedeelde repository-filter-engine toegevoegd en semantiek geharmoniseerd tussen paginatie en filtering.

### Wat is correct geimplementeerd

- Interface bevat `getProjectsByStatus` en `getFilteredProjects(...)`.
- Hive-implementatie heeft beide methoden.
- Testdekking aanwezig voor statusfilter, zoekquery en extra conditions in `test/project_repository_test.dart`.

### Wat ik nog zou wijzigen

- Er is functionele mismatch tussen comment en gedrag in repository:
  - comment zegt dat bepaalde filters client-side gebeuren,
  - maar `getProjectsPaginated` past wél meerdere filters toe (status/search/priority/tags/start/end).
  Dit moet geharmoniseerd worden om surprises te voorkomen.
- `getFilteredProjects` filtert momenteel niet op alle velden die in uitgebreid provider-filter bestaan (owner/tags/sort-dimensies blijven deels provider-side). Maak expliciet schema: welke laag is source-of-truth voor welk filtertype.

### Wat ik nog zou toevoegen

- Uniforme filter-engine (shared helper) voor zowel `getProjectsPaginated` als `getFilteredProjects`, om drift en dubbele logica te vermijden.
- Snapshottests voor samengestelde filters (status + query + tags + date-range).

### Wat ik nog zou verwijderen

- Overlappende filterlogica op meerdere plekken zonder gedeelde implementatie (technische schuld, verhoogt regressierisico).

---

## 004 - Paginated provider voor projecten

### Opvolging status

- DONE (afgewerkt op 2026-03-07): provider-validatie toegevoegd, deprecated alias voorzien en dedicated provider-tests toegevoegd.

### Wat is correct geimplementeerd

- Er is een paginated family provider: `projectsPaginatedProvider` in `packages/pma_core/lib/providers/project/project_providers.dart`.
- Provider accepteert samengestelde parameters via `ProjectPaginationParams(page, limit, filter)`.
- Gebruik in voorbeelden/UI aanwezig (`lib/core/repository/usage_examples.dart`).

### Wat ik nog zou wijzigen

- Naamafwijking t.o.v. TODO-tekst: TODO vroeg `paginatedProjectsProvider`, code gebruikt `projectsPaginatedProvider`.
  Advies: alias of deprecatie-export toevoegen om verwarring in docs/tests te voorkomen.
- Parameter-validatie op provider-niveau toevoegen (zelfde guards als repository) zodat fouten vroeger zichtbaar zijn.

### Wat ik nog zou toevoegen

- Dedicated provider-tests die aantonen dat provider effectief met page/limit/filter naar repository delegeert.
- README/architectuur-documentatie met 1 canonieke naam voor paginatieprovider.

### Wat ik nog zou verwijderen

- Eventuele oude verwijzingen naar niet-bestaande providernaam (`paginatedProjectsProvider`) in documentatie of comments.

---

## 005 - Voeg filter-/sort-parameters toe aan providers (family)

### Opvolging status

- DONE (afgewerkt op 2026-03-07): expliciet type-bridge patroon toegevoegd tussen provider- en repositoryfilter, met consistente toepassing en testdekking.

### Wat is correct geimplementeerd

- Providerlaag bevat uitgebreid filtertype met extra velden (o.a. owner/tags/sort/view): `ProjectFilter` in `packages/pma_core/lib/providers/project/project_providers.dart`.
- Family provider voor filtering bestaat (`filteredProjectsProvider`) en extra gecombineerde providers bestaan (`filteredProjectsPaginatedProvider`, `projectsCombinedProvider`).
- `ProjectFilterParams` (freezed) is aanwezig als uitbreidbare parametrisatievorm.

### Wat ik nog zou wijzigen

- Er zijn twee verschillende `ProjectFilter`-types in pma_core:
  - modeltype: `packages/pma_core/lib/models/project_filter.dart`
  - uitgebreid providertype: `packages/pma_core/lib/providers/project/project_providers.dart`
  Dit vergroot kans op typeverwarring en partiele filtertoepassing.
  Advies: consolideren naar één canoniek filtermodel of helder type-bridge patroon.
- Sortering is niet overal in pipeline uniform doorgevoerd (deels provider-side, deels niet in repository).

### Wat ik nog zou toevoegen

- End-to-end tests op filter + sort + paginatie samen, inclusief owner/tags/date combinaties.
- Duidelijke architectuurregel in docs:
  - welke filters repository-side lopen,
  - welke bewust provider-side lopen,
  - en waarom.

### Wat ik nog zou verwijderen

- Dubbele of semantisch overlappende filterdefinities zonder expliciete mappinglaag.

### Impact van jongere TODO op oudere TODO

- TODO 054 (modelmigraties) en TODO 070 (modularisatie) hebben de implementatie-architectuur uitgebreid; hierdoor is TODO 005 inhoudelijk gerealiseerd, maar met extra complexiteit (dubbele filtertypes) die nu opgeschoond moet worden.

---

## Samenvatting batch 001-005

- Volledig correct en stabiel: TODO 001, TODO 002 (basis), TODO 003 (basis), TODO 004 (functioneel)
- Correct maar met duidelijke verbeterpunten: TODO 005
- Belangrijkste restwerk:
  - filter-engine harmoniseren,
  - dubbele `ProjectFilter`-definities reduceren,
  - paginatiecontract (validatie + sortering) formaliseren,
  - documentatie synchroniseren met post-070 paden.

---

## Update globaal overzicht na batch 006-010

- Geanalyseerd tot nu: 001-010
- Resterend: 011-075

## 006 - Voeg caching toe voor individuele projecten

### Opvolging status

- DONE (afgewerkt op 2026-03-07): projectById TTL read-through/write-through cache gekoppeld, cache-statusprovider toegevoegd en mutatie-invalidatie op project-id niveau afgedwongen.

### Wat is correct geimplementeerd

- `projectByIdProvider` bestaat en haalt direct een enkel project op via repository (`packages/pma_core/lib/providers/project/project_providers.dart`).
- `ProjectDetailScreen` gebruikt `projectByIdProvider(projectId)` i.p.v. alle projecten op te halen.

### Wat ik nog zou wijzigen

- `projectCacheProvider` is momenteel functioneel niet gekoppeld aan `projectByIdProvider`:
  - er is enkel een read in UI (`lib/features/project/project_detail_screen.dart`),
  - er is geen write-pad dat cached data erin plaatst.
  Gevolg: `isFromCache` blijft in praktijk altijd `false`.
- Comment "5-minute TTL cache" in `project_detail_screen.dart` is misleidend zolang die cacheflow niet effectief gebruikt wordt.

### Wat ik nog zou toevoegen

- Echte TTL-caching voor `projectByIdProvider`:
  - ofwel via `ref.keepAlive()` + timer,
  - ofwel via een dedicated cache-notifier met read-through/write-through.
- Invalidering op mutaties (`updateProject`, `deleteProject`, `updateTasks`, `updateProgress`) specifiek voor het betrokken project-id.

### Wat ik nog zou verwijderen

- De huidige `projectCacheProvider` scaffold verwijderen als je niet voor provider-level cache kiest, of anders volledig afmaken en documenteren.

### Impact van jongere TODO op oudere TODO

- TODO 007 (efficiente `getProjectById`) maakt TODO 006 deels minder kritisch qua performance, maar niet qua UX-state (`Loaded from cache` indicatie is nu niet betrouwbaar).

---

## 007 - Efficient getProjectById implementatie

### Opvolging status

- DONE (afgewerkt op 2026-03-07): `getProjectById` contract expliciet gemaakt als throwing (niet-null return), documentatie geharmoniseerd en provider/UI not-found foutpad afgedekt met widget test.

### Wat is correct geimplementeerd

- Interface bevat `Future<ProjectModel> getProjectById(String id)` (`packages/pma_core/lib/repository/i_project_repository.dart`).
- Hive-implementatie gebruikt directe box key lookup (`_projectsBox.get(id)`) i.p.v. scan (`packages/pma_core/lib/repository/impl/hive_project_repository.dart`).
- Providers gebruiken repository-call rechtstreeks via `projectByIdProvider`.
- Testdekking aanwezig voor success + not found (`test/project_repository_test.dart`).

### Wat ik nog zou wijzigen

- TODO-tekst sprak over nullable return (`Future<ProjectModel?>`), maar implementatie gooit exception bij niet gevonden project.
  Kies 1 contract expliciet en documenteer het overal:
  - of nullable teruggeven,
  - of exception als canonical behavior.

### Wat ik nog zou toevoegen

- Test op provider-niveau voor error-mapping van not-found (UI pad), zodat foutafhandeling consistent is.

### Wat ik nog zou verwijderen

- Ambigue documentatie die nullable en throwing contract door elkaar gebruikt.

---

## 008 - Breid filter-parameters voor projecten uit

### Wat is correct geimplementeerd

- Uitgebreide provider-filter bevat extra velden: `ownerId`, `dueDateStart`, `dueDateEnd`, `requiredTags`, `sortBy`, `sortAscending`, enz. (`packages/pma_core/lib/providers/project/project_providers.dart`).
- UI filterdialog ondersteunt meerdere extra velden (priority, tags, required tags, date fields) (`lib/features/project/widgets/project_filter_dialog.dart`).

### Wat ik nog zou wijzigen

- Niet alle extra velden worden effectief toegepast in de primaire filterpipeline:
  - `_filterProjects` gebruikt alleen status/search/priority/tags/start/end.
  - velden zoals `dueDateStart`, `dueDateEnd`, `requiredTags` en deels `ownerId` zijn slechts in bepaalde paden of helemaal niet actief.
- Dit creëert een mismatch tussen wat UI laat instellen en wat query-logica werkelijk uitvoert.

### Wat ik nog zou toevoegen

- Eenduidige mappinglaag: elk filterveld krijgt expliciet gedrag met testcases per veld.
- Matrix-test die verifieert dat elk veld effect heeft op resultaatset.

### Wat ik nog zou verwijderen

- Filtervelden die nog geen semantiek hebben verwijderen uit publieke API, of markeren als experimenteel totdat ze effectief ondersteund zijn.

---

## 009 - Breid filter-conditions in filteredProjectsProvider uit

### Wat is correct geimplementeerd

- `ProjectFilterConditions` bestaat en repository ondersteunt `extraConditions` in `getFilteredProjects(...)`.
- Basale gecombineerde filtering (status + query + priority + tags + date) is aanwezig via provider/repository combinaties.
- Tests bestaan voor `extraConditions` op repository-niveau (`test/project_repository_test.dart`).

### Wat ik nog zou wijzigen

- `filteredProjectsProvider` zelf accepteert `models.ProjectFilter` (simpel model), niet de uitgebreide provider `ProjectFilter` met AND/OR-concepten zoals `requiredTags`.
- Daardoor is de geavanceerde AND/OR-belofte uit UI/documentatie niet volledig afgedekt door deze provider.

### Wat ik nog zou toevoegen

- Dedicated tests op provider-niveau voor gecombineerde logica:
  - OR via `tags`,
  - AND via `requiredTags`,
  - combinatie met zoekquery en datums,
  - null/empty regressietests.
- Een centrale evaluatiefunctie voor filterconditions (zodat repository en provider dezelfde semantiek delen).

### Wat ik nog zou verwijderen

- Verspreide en deels dubbele filterlogica over meerdere providers/repository-methoden zonder gedeelde source-of-truth.

### Impact van jongere TODO op oudere TODO

- TODO 010 en latere uitbreidingen van filter-UI hebben meer filtermogelijkheden toegevoegd dan TODO 009 in kernprovider-logica werkelijk afdwingt.

---

## 010 - Voeg extra filter-velden (date range, priority) toe

### Wat is correct geimplementeerd

- Date range + priority velden zijn aanwezig in filtermodellen en filterdialog.
- Filtering op `priority`, `startDate`, `endDate` gebeurt effectief in provider/repository paden.
- UI presenteert en exporteert deze filterinfo (o.a. in `project_filter_dialog.dart` en `pdf_export.dart`).

### Wat ik nog zou wijzigen

- Consistentie op due-date gerelateerde velden verbeteren:
  - `dueDateStart`/`dueDateEnd` bestaan, maar worden niet uniform toegepast zoals `startDate`/`endDate`.
- Zorg dat dezelfde date-range semantiek overal geldt (in-memory filtering, repository filtering, export previews).

### Wat ik nog zou toevoegen

- Gerichte tests voor date-range boundaries (inclusief grensdagen) en timezone-randgevallen.
- E2E test van filterdialog -> provider -> zichtbare lijst om te bewijzen dat geselecteerde velden echt effect hebben.

### Wat ik nog zou verwijderen

- Verouderde comments/statuslabels die "completed" suggereren voor velden die nog niet in alle querypaden actief zijn.

---

## Samenvatting batch 006-010

- Volledig functioneel: TODO 007 (kern), TODO 010 (basis)
- Deels functioneel met belangrijke afwerking nodig: TODO 006, TODO 008, TODO 009
- Belangrijkste restwerk:
  - echte individuele project-cache implementeren of verwijderen,
  - filterveld-semantiek uniform maken over provider/repository/UI,
  - contracten en documentatie aligneren (nullable vs exception, "completed" claims).

---

## Update globaal overzicht na batch 011-015

- Geanalyseerd tot nu: 001-015
- Resterend: 016-075

## 011 - Verwijderen/aanpassen van ProjectsNotifier.initialize() test-compatibiliteit

### Wat is correct geimplementeerd

- In de huidige code bestaat `ProjectsNotifier.initialize()` niet meer; de notifier gebruikt `build()` + provider-overrides als teststrategie (`packages/pma_core/lib/providers/project/project_providers.dart`).
- Tests mocken/overriden `projectRepositoryProvider` direct (`test/projects_provider_test.dart`).

### Wat ik nog zou wijzigen

- De done todo-tekst is verouderd: ze verwijst naar een methode die inmiddels verwijderd is.
- Vervang die TODO-inhoud door een expliciete migratienota: "initialize verwijderd, gebruik provider overrides + notifier build lifecycle".

### Wat ik nog zou toevoegen

- Korte test-guideline in docs voor projectproviders (hoe fake repo injecteren, hoe async state afwachten).

### Wat ik nog zou verwijderen

- Verouderde verwijzingen naar `initialize()` in documentatie/backlog, omdat dit verkeerde maintenance-signalen geeft.

### Impact van jongere TODO op oudere TODO

- TODO 070 (modularisatie) en latere provider-refactors hebben TODO 011 functioneel ingehaald: het probleem bestaat niet meer in de huidige architectuur.

---

## 012 - Deprecate ProjectsNotifier.getProjectById in favor of projectByIdProvider

### Wat is correct geimplementeerd

- `ProjectsNotifier.getProjectById` is gemarkeerd met `@Deprecated` en bevat duidelijke migratie-instructie naar `projectByIdProvider` (`packages/pma_core/lib/providers/project/project_providers.dart`).
- Runtimegebruik in app loopt via `projectByIdProvider` (o.a. `lib/features/project/project_detail_screen.dart`).

### Wat ik nog zou wijzigen

- Deprecatiepad is goed, maar nog zonder harde verwijderdatum/versioning. Voeg een target release toe voor effectieve removal.

### Wat ik nog zou toevoegen

- Kleine lintregel of CI-check die nieuw gebruik van deprecated methode blokkeert.
- Test die expliciet verifieert dat belangrijkste schermen de family provider gebruiken.

### Wat ik nog zou verwijderen

- Na afgesproken migratie-window: de deprecated methode volledig verwijderen om dubbel gedrag te vermijden.

---

## 013 - Introduceer IAuthRepository interface

### Wat is correct geimplementeerd

- Interface bestaat: `packages/pma_core/lib/repository/i_auth_repository.dart`.
- `authRepositoryProvider` levert interface-typed repository (`packages/pma_core/lib/providers/auth/auth_providers.dart`).
- `HiveAuthRepository` implementeert de interface en wordt breed gebruikt in providers/tests.
- Testfakes implementeren `IAuthRepository` in meerdere tests (o.a. `test/auth_providers_test.dart`, `test/user_filter_providers_test.dart`).

### Wat ik nog zou wijzigen

- Interface is vrij breed en bevat zowel domeinbeheer (roles/groups/users) als sessie/rate-limit operaties.
  Advies: splitsen in sub-interfaces (bijv. `IAuthSessionRepository`, `IUserAdminRepository`) voor scherpere testbaarheid.

### Wat ik nog zou toevoegen

- Contracttests voor kritieke auth flows (login/logout/current-user/session-state) die implementatie-agnostisch draaien.

### Wat ik nog zou verwijderen

- Ambigue "future methods" comments in interface die niet meer aansluiten op reele roadmap of al via andere services opgelost zijn.

### Impact van jongere TODO op oudere TODO

- TODO 050 (auth backend integratie) bouwt direct voort op TODO 013 en maakt de interfacekeuze waardevol; geen tenietdoening, wel verbreding van verantwoordelijkheden.

---

## 014 - Rate limiting voor login-pogingen

### Wat is correct geimplementeerd

- Dedicated service aanwezig: `LoginRateLimiter` met sliding window + progressive backoff en persistent Hive-opslag (`packages/pma_core/lib/services/login_rate_limiter.dart`).
- Auth flow gebruikt limiter in `AuthNotifier.login` via `loginRateLimiterProvider` (`packages/pma_core/lib/providers/auth/auth_providers.dart`).
- Initialisatie gebeurt bij app start (`lib/main.dart` bevat `await LoginRateLimiter.instance.initialize()`).
- Tests aanwezig voor limiter en auth-rate-limit gedrag (`test/login_rate_limiter_test.dart`, `test/auth_providers_test.dart`).

### Wat ik nog zou wijzigen

- Er is potentiele dubbele rate-limitlogica:
  - persistente limiter service,
  - plus extra in-memory attempt tracking in `HiveAuthRepository` (`_failedAttempts`, `canAttemptLogin`, `recordFailedLoginAttempt`).
  Dit kan divergent gedrag geven.
  Advies: 1 canonieke limiter houden en de andere route verwijderen of strikt mappen.

### Wat ik nog zou toevoegen

- Integratietest op volledig loginpad met echte `AuthNotifier` + limiter (niet alleen testnotifier-variant).
- Security-notes/documentatie over reset-policy en privacy van identifier hashing.

### Wat ik nog zou verwijderen

- Ongebruikte/overlappende rate-limit API in repository als deze niet in productieflow wordt aangesproken.

---

## 015 - Biometrische authenticatie ondersteunen

### Wat is correct geimplementeerd

- `local_auth` integratie aanwezig in auth provider (`packages/pma_core/lib/providers/auth/auth_providers.dart`).
- Methoden aanwezig: `isBiometricAvailable`, `authenticateWithBiometrics`, `enrollBiometrics`.
- Platform checks aanwezig (web/desktop uitgesloten).
- UI-flow is verbonden (login/settings gebruiken biometric toggles en acties):
  - `lib/features/auth/login_screen.dart`
  - `lib/features/settings/settings_screen.dart`

### Wat ik nog zou wijzigen

- Credentials worden voor biometrische login direct opgeslagen in secure storage (`biometric_username`, `biometric_password`).
  Dit werkt functioneel, maar is security-gevoelig.
  Advies: token-based aanpak of refresh-token binding i.p.v. plaintext wachtwoordsecret in opslag.
- TODO-tekst vroeg feature-flag; implementatie gebruikt vooral settings toggles, niet duidelijk via centraal feature-flag systeem.

### Wat ik nog zou toevoegen

- Uitgebreide tests voor biometrische runtimepaden (momenteel grotendeels als "not fully tested" gemarkeerd in `test/auth_providers_test.dart`).
- Fallback UX-tests (biometrie faalt -> password flow zonder lockout regressie).

### Wat ik nog zou verwijderen

- Legacy of dubbele biometrie-instellingen als `biometricLoginProvider` en `useBiometricsProvider` functioneel overlappen zonder helder onderscheid.

### Impact van jongere TODO op oudere TODO

- TODO 071 (feature flags via Supabase) suggereert een centraler togglesysteem; TODO 015 gebruikt vooral settings-level toggles. Dat is niet fout, maar governance is nu verspreid.

---

## Samenvatting batch 011-015

- Volledig functioneel: TODO 012, TODO 013, TODO 014 (kern), TODO 015 (kern)
- Inhoudelijk achterhaald/ingehaald: TODO 011
- Belangrijkste restwerk:
  - auth/repository concerns verder scheiden,
  - rate-limit dubbeling reduceren,
  - biometrische opslagstrategie verharden,
  - verouderde backlogtekst updaten waar implementatie intussen verder evolueerde.

---

## Update globaal overzicht na batch 016-020

- Geanalyseerd tot nu: 001-020
- Resterend: 021-075

## 016 - Async ophalen van instellingen in auth providers

### Wat is correct geimplementeerd

- Groot deel van auth/settings-reads gebruikt nu het async patroon met `await ref.read(settingsRepositoryProvider.future)` in notifiers en auth flow (`packages/pma_core/lib/providers/auth/auth_providers.dart`).
- In-code guideline comment aanwezig die dit patroon expliciet benoemt.

### Wat ik nog zou wijzigen

- `recaptchaServiceProvider` gebruikt nog een sync-achtige fallback via:
  - `ref.watch(settingsRepositoryProvider).maybeWhen(...)`
  - `orElse: HiveSettingsRepository.new`
  Dit kan een niet-geinitialiseerde repository opleveren en kan settingsgedrag maskeren bij loading/error.

### Wat ik nog zou toevoegen

- Consistente helper/factory voor settings access zodat alle callsites dezelfde init/error-strategie volgen.
- Test die expliciet loading/error-state op `settingsRepositoryProvider` in auth-paden verifieert.

### Wat ik nog zou verwijderen

- Fallback-constructies die sync toegang simuleren op async settings, tenzij die fallback functioneel echt gewenst is en volledig geïnitialiseerd wordt.

---

## 017 - Specificeer en implementeer: max 5 login attempts per minuut

### Wat is correct geimplementeerd

- Concrete policy staat in `LoginRateLimiter`:
  - `maxAttempts = 5`
  - `windowSeconds = 60`
  - progressive backoff + persistent Hive state (`packages/pma_core/lib/services/login_rate_limiter.dart`).
- Auth login gebruikt limiter (`getAttemptCount`, `getBackoffDuration`, `recordAttempt`, `resetOnSuccess`) in `AuthNotifier.login`.
- Captcha pad aanwezig vanaf 3 failed attempts in auth login flow.
- Testdekking aanwezig in `test/login_rate_limiter_test.dart` en `test/auth_providers_test.dart`.

### Wat ik nog zou wijzigen

- Begrip "per minuut" en backoff-schaal zijn technisch correct, maar policy staat verspreid over service + providercomments; maak 1 security policybron in docs.
- Captcha logica zit in auth provider, niet in limiter; dat is ok, maar contract tussen beide lagen kan explicieter (bijv. threshold constants centraal).

### Wat ik nog zou toevoegen

- Integratietest met echte `AuthNotifier` en niet enkel testsubclass om regressies in provider wiring te vangen.
- Metrics/asserties op unblock gedrag na backoff-expiry in runtimeflow.

### Wat ik nog zou verwijderen

- Eventuele dubbele of niet-gebruikte login attempt-routes buiten de centrale limiterflow.

### Impact van jongere TODO op oudere TODO

- TODO 017 concretiseert TODO 014 (zelfde securitydomein) en maakt de policy explicieter; geen tenietdoening, wel aanscherping.

---

## 018 - Gebruik settingsRepositoryProvider.future waar nodig

### Wat is correct geimplementeerd

- Veel codepaden in auth providers volgen het afgesproken patroon met `settingsRepositoryProvider.future` en inline verwijzing naar TODO 018.
- Notifiers voor AI consent, biometric toggles, help level en use biometrics gebruiken consistent async settings access.

### Wat ik nog zou wijzigen

- `ref.watch(settingsRepositoryProvider.future)` wordt op sommige plekken gebruikt waar `ref.read(...)` semantisch stabieler kan zijn binnen imperative methods.
  Standaardiseren op 1 keuze per context voorkomt onnodige her-evaluatiecomplexiteit.

### Wat ik nog zou toevoegen

- Korte engineering note: wanneer `read` vs `watch` gebruiken met `.future` in notifiers.
- Extra tests die gedrag valideren wanneer settings provider faalt of vertraagd is.

### Wat ik nog zou verwijderen

- Restanten van gemengde sync/async settings-accesspatronen in auth provider (met name fallbackconstructies).

### Impact van jongere TODO op oudere TODO

- TODO 018 bouwt direct voort op TODO 016 en werkt die systematischer uit; TODO 016 is daardoor deels geabsorbeerd in bredere conventie.

---

## 019 - Voeg zoek- en filtermogelijkheden toe aan auth/user providers

### Wat is correct geimplementeerd

- `UsersFilter` model bestaat met `searchQuery`, `role`, `status`.
- `searchUsersProvider` en `filteredUsersProvider` family providers bestaan in auth providers.
- Relevante tests aanwezig in `test/user_filter_providers_test.dart` en aanvullend in `test/auth_providers_test.dart`.
- UI voorbeeldcode is aanwezig in auth provider bestand (documentatieblok met component usage).

### Wat ik nog zou wijzigen

- `status` filtering is nog niet echt geïmplementeerd (wordt gelogd als niet ondersteund), terwijl veld publiek beschikbaar is.
  Dit is functioneel mismatch tussen API-oppervlak en gedrag.

### Wat ik nog zou toevoegen

- Ofwel status echt toevoegen aan `AppUser` model + filtering activeren,
- Of status tijdelijk verwijderen uit filtermodel tot semantiek effectief ondersteund is.

### Wat ik nog zou verwijderen

- "Niet geïmplementeerd" branches in core filterlogica zodra de definitieve statusrichting gekozen is.

---

## 020 - Valideer widgetType bij dashboard widgets

### Wat is correct geimplementeerd

- `validateWidgetType(...)` helper bestaat en `DashboardWidgetType` enum centraliseert toegelaten types.
- `DashboardItem.fromJson` normaliseert widgetType via enum parsing.
- Tests rond widgetType parsing en dashboard add/update flows bestaan in `test/dashboard_providers_test.dart`.

### Wat ik nog zou wijzigen

- Er is een inconsistentie tussen intentie en runtimegedrag:
  - `validateWidgetType` suggereert dat invalid input exception triggert,
  - maar `DashboardWidgetType.fromString` valt terug op `metricCard` in plaats van throw.
  Gevolg: invalid values worden stil gemapt i.p.v. hard geweigerd.
- `addItem` valideert `item.widgetType.name`; omdat dit al enum-typed is, is die check praktisch altijd triviaal waar.

### Wat ik nog zou toevoegen

- Keuze expliciet maken:
  - strict mode: throw `InvalidWidgetTypeException`, of
  - permissive mode: fallback + warning.
  En tests/documentatie daarop afstemmen.
- Error messaging harmoniseren zodat de behavior in tests overeenkomt met function contract.

### Wat ik nog zou verwijderen

- Dode/tegenstrijdige exceptionpaden of comments die strikt valideren beloven terwijl fallback-gedrag actief is.

### Impact van jongere TODO op oudere TODO

- TODO 021 (position constraints) en latere dashboard-hardening hebben aandacht verlegd naar layoutveiligheid; daardoor is widgetType-validatie functioneel aanwezig maar minder strikt dan oorspronkelijk bedoeld.

---

## Samenvatting batch 016-020

- Volledig functioneel: TODO 017 (kern), TODO 018 (grotendeels), TODO 019 (basis), TODO 020 (basis)
- Correct maar met duidelijke afronding nodig: TODO 016
- Belangrijkste restwerk:
  - recaptcha/settings fallback pad opschonen,
  - statusfilter in user filtering afmaken of terugschalen,
  - widgetType-validatiecontract (strict vs fallback) expliciet vastzetten en aligneren met tests.

---

## Update globaal overzicht na batch 021-025

- Geanalyseerd tot nu: 001-025
- Resterend: 026-075

## 021 - Position constraints en boundaries voor dashboard widgets

### Wat is correct geimplementeerd

- Dashboard position constraints zijn aanwezig via constants (`kDashboardMinX`, `kDashboardMinY`, `kDashboardMinWidth`, `kDashboardMinHeight`, container bounds).
- `_clampPosition`, `_isValidPosition` en `enforcePositionConstraints(...)` zijn geïmplementeerd in `DashboardConfigNotifier`.
- `addItem` en `updateItemPosition` passen clamping toe vóór opslag.
- Testdekking is goed voor grensgevallen in `test/dashboard_providers_test.dart`.

### Wat ik nog zou wijzigen

- In `_clampPosition` kan bij extreme invoer theoretisch een negatief `x`/`y` ontstaan na `containerWidth - width` als `width` groter is dan container; nu wordt dat niet apart hersteld.
  Voeg een extra final clamp (`max(0, ...)`) na overflow-correctie toe.

### Wat ik nog zou toevoegen

- Testcase voor `width > containerWidth` en `height > containerHeight` om bovenstaande randvoorwaarde af te dekken.

### Wat ik nog zou verwijderen

- Geen directe verwijdering nodig.

---

## 022 - Undo/Redo functionaliteit voor dashboard wijzigingen

### Wat is correct geimplementeerd

- History stack, `undo()`, `redo()`, `canUndo`, `canRedo`, max-history trimming zijn aanwezig in `DashboardConfigNotifier`.
- Undo/redo-testen staan in `test/dashboard_providers_test.dart` inclusief edge cases.

### Wat ik nog zou wijzigen

- `undo/redo` roepen `saveConfig` aan, en `saveConfig` manipuleert ook history-index; daarna wordt `_currentIndex` opnieuw overschreven.
  Dit werkt nu in tests, maar is fragiel en kan regressies geven bij toekomstige save-flow wijzigingen.
  Advies: expliciet history-suspend mechanisme tijdens undo/redo persist.

### Wat ik nog zou toevoegen

- Test die controleert dat undo/redo geen extra history-entry dupliceert bij persist/callback side-effects.

### Wat ik nog zou verwijderen

- Impliciete index-resetlogica in meerdere plekken; centraliseer indexbeheer.

---

## 023 - Dashboard templates en preset layouts

### Wat is correct geimplementeerd

- Data model en preset templates bestaan.
- CRUD-achtige paden bestaan: `saveAsTemplate`, `loadTemplate`, `deleteTemplate`, `getAllTemplates`.
- Opslag in repository + settings is aanwezig.
- Testen voor presets, save/load/delete en invalid template id zijn aanwezig in `test/dashboard_providers_test.dart`.

### Wat ik nog zou wijzigen

- `saveAsTemplate` accepteert lege naam en duplicaten (expliciet getest).
  Dit is functioneel permissief, maar UX kan rommelig worden.
  Advies: valideer minimale naamlengte en/of deduplicatiebeleid.

### Wat ik nog zou toevoegen

- Metadata op templates (bijv. laatste gebruik, eigenaar, beschrijving) voor betere beheerervaring.

### Wat ik nog zou verwijderen

- Eventueel permissieve edge-cases (lege naam) als productrichting stricter templatebeheer wil.

---

## 024 - Collaborative dashboard sharing

### Wat is correct geimplementeerd

- Core sharing flows bestaan in provider:
  - `generateShareLink`
  - `hasPermission`
  - `inviteUser`
  - `loadSharedDashboard` met last-write-wins conflictkeuze
  - realtime subscription (`_subscribeToSharedChanges`)
- Repository heeft Supabase + local shared dashboard paden.

### Wat ik nog zou wijzigen

- `hasPermission` vergelijkt nu exact op gelijkheid (`userPerm == required.name`), zonder hiërarchie.
  Daardoor impliceert `edit` niet automatisch `view`.
  Advies: permissiehiërarchie modelleren (`edit` omvat `view`).

### Wat ik nog zou toevoegen

- Echte integratietests met gemockte Supabase responses/channels; huidige tests in `test/dashboard_providers_test.dart` zijn grotendeels logica-simulaties, geen end-to-end provider/repo verificatie.
- Invite-flow auditing (wie heeft wanneer permissie aangepast) als governanceverbetering.

### Wat ik nog zou verwijderen

- Testcases die alleen pseudo-logic valideren zonder provider-callpad kunnen deels vervangen worden door sterkere integratietests.

### Impact van jongere TODO op oudere TODO

- TODO 028 (offline requirements/sync) en latere sync-hardening versterken collaboration, maar vergroten ook conflictcomplexiteit; TODO 024 basis is aanwezig maar nog licht qua testdiepte.

---

## 025 - Error handling en logging toevoegen voor dashboard providers

### Wat is correct geimplementeerd

- Dashboard provider gebruikt uitgebreid `try/catch`, `_logError`, `_logEvent`, en `dashboardErrorProvider` statuscodes op meerdere IO-acties.
- Tests aanwezig voor failure-paden (`loadConfig`, `saveConfig`, `addItem`, `removeItem`, `updateItemPosition`, `createCustomWidget`) in `test/dashboard_providers_test.dart`.

### Wat ik nog zou wijzigen

- Repositorylaag slikt op meerdere plekken exceptions zonder log of propagate (bijv. verschillende `catch (e) { return []; }` of no-op catches in `HiveDashboardRepository`).
  Dat ondergraaft observability vanuit providerlaag.
  Advies: minimaal `AppLogger.warning/error` toevoegen in repository catches.

### Wat ik nog zou toevoegen

- Uniform error taxonomy (codes + context metadata) zodat dashboardErrorProvider en logs één gedeeld woordenboek hebben.

### Wat ik nog zou verwijderen

- Stille catches zonder logging in repository helperklassen.

### Impact van jongere TODO op oudere TODO

- TODO 025 legt een basis voor latere reliability-hardening (o.a. offline/sync), maar stille repository catches beperken nu nog de effectieve diagnosekwaliteit.

---

## Samenvatting batch 021-025

- Volledig functioneel: TODO 021 (kern), TODO 022 (kern), TODO 023 (kern), TODO 025 (providerlaag)
- Functioneel maar met duidelijke diepgangstekorten: TODO 024
- Belangrijkste restwerk:
  - permissiehiërarchie in sharing aanscherpen,
  - integratietests voor collaboration verdiepen,
  - stille repository-catches vervangen door gestructureerde logging,
  - undo/redo indexbeheer robuuster maken tegen toekomstige save-flow veranderingen.

---

## Update globaal overzicht na batch 026-030

- Geanalyseerd tot nu: 001-030
- Resterend: 031-075

## 026 - Maak abstract interface voor dashboard data (testbaarheid)

### Wat is correct geimplementeerd

- Interface bestaat als apart contract: `packages/pma_core/lib/repository/i_dashboard_repository.dart`.
- Concrete implementatie gebruikt dat contract: `packages/pma_core/lib/repository/impl/hive_dashboard_repository.dart`.
- Providers injecteren repository via interface-typed provider: `dashboardRepositoryProvider` in `packages/pma_core/lib/providers/dashboard/dashboard_providers.dart`.
- Testbaarheid is effectief verbeterd: dashboard tests gebruiken fake repositories (o.a. `test/dashboard_providers_test.dart`).

### Wat ik nog zou wijzigen

- Interface is inhoudelijk breed en combineert config, templates, sharing en requirements-sync in 1 contract.
  Advies: opsplitsen in sub-contracten (`IDashboardConfigRepository`, `IDashboardSharingRepository`, `IRequirementsRepository`) om mock-opzet eenvoudiger te maken.

### Wat ik nog zou toevoegen

- Kleine contracttests die voor elke implementatie dezelfde minimale gedragsverwachtingen valideren (save/load, template roundtrip, share-link lifecycle).

### Wat ik nog zou verwijderen

- Geen directe verwijdering nodig.

---

## 027 - Cache `requirements` data met TTL

### Wat is correct geimplementeerd

- Er is caching met TTL aanwezig, maar voor dashboard-configuratie (`_DashboardCacheManager`, standaard 5 minuten) in `packages/pma_core/lib/repository/impl/hive_dashboard_repository.dart`.
- Requirements hebben een lokale read-path (`getCachedRequirements`) en update-pad (`saveRequirement`) die snelle lokale opslag gebruikt.
- Provider invalideert requirements-gerelateerde state bij updates (`requirementsProvider`, `projectRequirementsProvider`) in `packages/pma_core/lib/providers/dashboard/dashboard_providers.dart`.

### Wat ik nog zou wijzigen

- De TODO vraagt expliciet TTL-cache op requirements; die TTL ontbreekt nu op requirements zelf.
  Er is wel lokale cache-opslag, maar geen `_CacheEntry<T>`-achtig patroon met expiry op requirementniveau.
- Invalidering gebeurt nu vooral via provider invalidation, niet via cache-expiry + update-invalidering als gecombineerd contract.

### Wat ik nog zou toevoegen

- Dedicated requirements TTL-cache (bijv. `Map<String, CacheEntry<ProjectRequirements>>`) met:
  - timestamp/expiry,
  - invalidate op `saveRequirement`,
  - fallback naar repository fetch bij verlopen entry.
- Tests voor TTL-verloop en update-invalidering op requirementspad.

### Wat ik nog zou verwijderen

- Claims in comments/docs die impliceren dat requirements TTL-cache al volledig af is, zolang enkel config-TTL bestaat.

### Impact van jongere TODO op oudere TODO

- TODO 028 (offline requirements) voegt lokale opslag toe, maar vervangt TTL-caching niet. Daardoor is TODO 027 slechts gedeeltelijk ingevuld in de huidige vorm.

---

## 028 - Offline opslag voor requirements (Hive)

### Wat is correct geimplementeerd

- Requirements-opslag in Hive is aanwezig (`requirements_box`) in `packages/pma_core/lib/repository/impl/hive_dashboard_repository.dart`.
- Er is een pending changes queue (`pending_requirements_changes`) met methoden `queuePendingChange` en `processPendingSync`.
- Provider respecteert offline mode en queued wijzigingen via `saveRequirement` wanneer `_isOffline == true` (`packages/pma_core/lib/providers/dashboard/dashboard_providers.dart`).

### Wat ik nog zou wijzigen

- Sync-logica is momenteel simplistisch: `processPendingSync` leegt vooral de queue zonder echte remote replay/mergeflow.
- Connectiviteitsgedreven sync-triggering ontbreekt als robuust mechanisme; flow hangt af van provider-level toggles.
- Geen zichtbaar migratiepad voor requirements schema-evoluties in Hive (versioning/migratie-afhandeling).

### Wat ik nog zou toevoegen

- Echte replay-sync naar remote backend met idempotente operatie-IDs en foutafhandeling per queued item.
- Connectiviteitslistener die `processPendingSync` triggert bij online herstel.
- Tests voor offline->online replay, conflicten en queue-herstel na app-restart.
- Expliciet migratieplan voor requirements data model (Hive adapter/version bump pad).

### Wat ik nog zou verwijderen

- "Assume sync successful"-achtige aannames in sync manager zodra echte replaylogica actief is.

### Impact van jongere TODO op oudere TODO

- TODO 025 (error handling/logging) en TODO 024 (sharing/sync context) verhogen de noodzaak van observeerbare sync; stille/no-op syncpaden uit TODO 028 beperken nu die betrouwbaarheid.

---

## 029 - Koppel dashboard items aan `projectsProvider`

### Wat is correct geimplementeerd

- Integratie bestaat via `projectRequirementsProvider` dat `projectsProvider.future` leest en projectcontext resolveert (`packages/pma_core/lib/providers/dashboard/dashboard_providers.dart`).
- Project-id naar projectnaam-resolutie en fallback naar lege requirements zijn aanwezig.
- Loading/error-situaties zijn afgevangen met timeout/fallback en catch-pad dat veilige defaults retourneert.

### Wat ik nog zou wijzigen

- Koppeling is momenteel vooral op requirements-niveau en minder direct op dashboard item rendering zelf.
  Als TODO ook item-level naamweergave bedoelde, is dat maar deels afgedekt.
- Timeout naar lege lijst na 1 seconde is pragmatisch, maar kan bij tragere devices tot te agressieve fallback leiden.

### Wat ik nog zou toevoegen

- Expliciete item-level resolverprovider (projectId -> display label/status) voor consistente weergave in widgets.
- Tests voor loading/error/timeouts die valideren dat UI-consumptie semantisch klopt (niet alleen geen crash).

### Wat ik nog zou verwijderen

- Hardcoded fallbacktekst zoals `'Unknown Project'` centraliseren in l10n/consts om drift te voorkomen.

---

## 030 - Maak AI rate limits configureerbaar

### Wat is correct geimplementeerd

- Magic numbers zijn verplaatst naar configureerbaar model `AiRateLimitsConfig` met defaults, JSON-serialisatie en validatie (`packages/pma_core/lib/models/ai_rate_limits_config.dart`).
- Settings repository ondersteunt load/save met validatie en fallback (`getAiRateLimitsConfig`, `setAiRateLimitsConfig`) in `packages/pma_core/lib/repository/impl/hive_settings_repository.dart`.
- AI chat laadt config runtime via settings provider en gebruikt fallback bij fouten (`packages/pma_core/lib/providers/ai/ai_chat_providers.dart`).
- Validatie/clamping is aanwezig voor ongeldige inputwaarden; per-operation limits zijn mee ondersteund.
- Testen voor config persist/loads en per-operation limieten zijn aanwezig (`test/ai_chat_provider_test.dart`).

### Wat ik nog zou wijzigen

- Er bestaan twee AI chat provider varianten (`ai/ai_chat_providers.dart` en `ai_legacy/ai_chat_providers.dart`), beide met rate-limit gedrag.
  Dit verhoogt risico op drift in policy-implementatie.
- `build()` gebruikt `ref.watch(settingsRepositoryProvider.future)` in imperatieve initialisatie; `ref.read(...)` is hier vaak stabieler en voorspelbaarder.

### Wat ik nog zou toevoegen

- Eenduidige policybron voor rate-limitsemantiek (window/tokens/retries/per-operation) zodat legacy en huidige provider niet uiteenlopen.
- Integratietest op hoofdpad (`lib`-gebruik via barrel exports) om te garanderen dat actieve app-provider de configureerbare limieten effectief respecteert.

### Wat ik nog zou verwijderen

- Overlappende legacy rate-limit paden zodra migratie naar de actieve provider volledig is afgerond.

### Impact van jongere TODO op oudere TODO

- TODO 034 (per-operation limits) bouwt op TODO 030 en verdiept die; TODO 030 blijft geldig maar is nu onderdeel van een bredere ratelimit-architectuur.

---

## Samenvatting batch 026-030

- Volledig functioneel: TODO 026, TODO 029, TODO 030
- Gedeeltelijk functioneel met afwerking nodig: TODO 027, TODO 028
- Belangrijkste restwerk:
  - echte TTL-cache voor requirements toevoegen,
  - offline requirements sync van queue-leegmaak naar echte replay/merge brengen,
  - dashboard-project koppeling verder doortrekken naar item-level weergave,
  - AI legacy/current provider drift reduceren rond rate-limit policy.

---

## Update globaal overzicht na batch 031-035

- Geanalyseerd tot nu: 001-035
- Resterend: 036-075

## 031 - Maak max requests per window configureerbaar

### Wat is correct geimplementeerd

- Configmodel bevat `maxRequestsPerWindow` met defaults + validatie (`packages/pma_core/lib/models/ai_rate_limits_config.dart`).
- Settingslaag ondersteunt lezen/schrijven van deze configuratie (`packages/pma_core/lib/repository/impl/hive_settings_repository.dart`).
- Er is een settings-notifier/provider voor rate-limit configuratie (`aiRateLimitsConfigProvider` in `packages/pma_core/lib/providers/settings/settings_providers.dart`).
- UI exposeert rate-limit instellingen in settings (incl. per-operation/global velden) in `lib/features/settings/settings_screen.dart`.

### Wat ik nog zou wijzigen

- In de actieve AI-chat provider (`packages/pma_core/lib/providers/ai/ai_chat_providers.dart`) wordt `maxRequestsPerWindow` niet expliciet toegepast in de runtime throttling; de flow gebruikt vooral minute/hour/day counters.
- De oudere provider (`packages/pma_core/lib/providers/ai_legacy/ai_chat_providers.dart`) gebruikt `maxRequestsPerWindow` wel actief, wat policy-drift veroorzaakt.

### Wat ik nog zou toevoegen

- Test die expliciet bewijst dat wijziging van `maxRequestsPerWindow` effectief gedrag verandert in de actieve provider.
- Eenduidige window-throttle implementatie in de actieve provider (of expliciete deprecatie van window-veld als het bewust vervangen is).

### Wat ik nog zou verwijderen

- Dubbele policy-interpretaties tussen legacy en actieve provider.

---

## 032 - Voeg exponential backoff toe bij rate-limits

### Wat is correct geimplementeerd

- Exponential backoff met jitter bestaat in actieve provider via `_calculateBackoffDelay` + retry in queue-worker (`packages/pma_core/lib/providers/ai/ai_chat_providers.dart`).
- Legacy provider bevat throttling-specifieke retry met backoff en retry logging (`_callAiWithRetry`, `ai_retry_attempt`) in `packages/pma_core/lib/providers/ai_legacy/ai_chat_providers.dart`.

### Wat ik nog zou wijzigen

- In de actieve provider is retry/backoff niet throttling-specifiek, maar generiek op queue failures; dat wijkt af van de TODO-intentie (rate-limit gedreven backoff).
- Actieve provider gebruikt vaste retrygrens (`retryCount < 3`) i.p.v. config-gedreven `maxRetryAttempts` op runtime.

### Wat ik nog zou toevoegen

- Throttling-detectie in actieve provider (rate-limit/429) met specifiek retrypad.
- Gerichte tests voor retrygedrag en observability-events in de actieve provider (nu vooral beperkte/indirecte dekking).

### Wat ik nog zou verwijderen

- Hardcoded retry-limiet in queue-worker zodra config-gedreven aanpak is doorgetrokken.

### Impact van jongere TODO op oudere TODO

- TODO 033 (queue-worker) heeft 032 deels geabsorbeerd: backoff zit nu in queueverwerking, maar throttling-semantiek is daardoor diffuser geworden.

---

## 033 - Request queuing voor AI burst handling

### Wat is correct geimplementeerd

- Request-queue model staat in `packages/pma_core/lib/models/ai_request_queue.dart` met priority/FIFO gedrag, metrics en serialization.
- Actieve provider heeft background worker (`_startWorker`, `_processQueue`) en queue-metrics (`queueLength`, `processedToday`, `droppedCount`).
- Queue persistence hooks bestaan (`persistQueue`, `restoreQueue`) in `packages/pma_core/lib/providers/ai/ai_chat_providers.dart`.
- Settings UI toont queue status en biedt queue clear actie (`lib/features/settings/settings_screen.dart`).

### Wat ik nog zou wijzigen

- `queueEnabled` configuratie bestaat, maar wordt in de actieve provider niet afgedwongen (requests worden altijd gequeued).
- Observability en testdekking voor queuepad zijn relatief dun t.o.v. de complexiteit (nauwelijks dedicated queue tests in `test/`).

### Wat ik nog zou toevoegen

- Integratietests voor queue overflow, retry, persistence restore, en metrics updates.
- Expliciete branch voor `queueEnabled == false` in actieve provider met voorspelbare error/UX.

### Wat ik nog zou verwijderen

- Dode configuratiepaden (zoals `queueEnabled`) als ze niet runtime-effectief gemaakt worden.

---

## 034 - Per-operation rate limits voor AI

### Wat is correct geimplementeerd

- `AiRateLimitsConfig` ondersteunt `perOperationLimits` inclusief validatie en JSON mapping (`packages/pma_core/lib/models/ai_rate_limits_config.dart`).
- Settings kan per-operation limieten opslaan/lezen en UI bewerken (`lib/features/settings/settings_screen.dart`, `packages/pma_core/lib/providers/settings/settings_providers.dart`).
- Legacy provider implementeert operation-based checks (`isOperationRateLimited`, operation counters) in `packages/pma_core/lib/providers/ai_legacy/ai_chat_providers.dart`.

### Wat ik nog zou wijzigen

- Actieve provider schaalt `perOperationLimits` wel bij subscription, maar gebruikt ze niet in daadwerkelijke operation-based throttling bij queue processing.
- TODO vroeg ook queue-aanpassing op operation-basis; dat gedrag zit nu vooral in legacy, niet in de actieve runtimeflow.

### Wat ik nog zou toevoegen

- Operation-aware limiter in actieve provider (bijv. aparte counters per `request.action`).
- Tests per actie (`chat`, `generate_questions`, `generate_proposals`, `generate_final_plan`) die limieten en fallback naar global limit valideren.

### Wat ik nog zou verwijderen

- Schijnconfiguratie waarbij UI wel per-operation limieten toont maar runtime deze beperkt gebruikt.

### Impact van jongere TODO op oudere TODO

- TODO 038 (split provider files) en migratie naar nieuwe AI provider hebben delen van 034 technisch verplaatst, maar ook regressierisico gecreeerd doordat enforcement niet overal is meegenomen.

---

## 035 - Implementeer XML-parsing voor AI-parsers

### Wat is correct geimplementeerd

- XML dependency is toegevoegd (`xml` in zowel root `pubspec.yaml` als `packages/pma_core/pubspec.yaml`).
- Parserondersteuning staat in `packages/pma_core/lib/services/ai_parsers.dart` met:
  - `XmlAiParser`,
  - `safeParseXml(...)`,
  - fallback XML-extractie uit mixed text,
  - integratie via `ParserRegistry`/`parseAIResponse`.
- Testdekking is sterk en concreet (`test/ai_parsers_test.dart`) voor geldige XML, attributes/nesting, mixed text fallback, malformed input en lege input.

### Wat ik nog zou wijzigen

- TODO noemde oorspronkelijke padlocatie; implementatie zit nu in `packages/pma_core/...` (inhoudelijk correct, pad in todo verouderd).

### Wat ik nog zou toevoegen

- Extra test voor grote/namespaced XML payloads als compatibiliteit met externe integraties belangrijk wordt.

### Wat ik nog zou verwijderen

- Geen directe verwijdering nodig.

### Impact van jongere TODO op oudere TODO

- TODO 047 (parsing extensions) heeft 035 niet tenietgedaan maar juist opgewaardeerd: XML parsing is nu onderdeel van een generiek extensiesysteem.

---

## Samenvatting batch 031-035

- Volledig functioneel: TODO 035
- Functioneel maar met belangrijke runtime-gaten in actieve provider: TODO 031, TODO 032, TODO 033, TODO 034
- Belangrijkste restwerk:
  - runtime enforcement van `maxRequestsPerWindow` en `perOperationLimits` in de actieve AI-provider,
  - throttling-specifieke backoff en config-gedreven retrylimieten harmoniseren,
  - `queueEnabled` daadwerkelijk laten doorwerken in runtimegedrag,
  - gerichte queue/backoff/per-operation integratietests toevoegen.

---

## Update globaal overzicht na batch 036-040

- Geanalyseerd tot nu: 001-040
- Resterend: 041-075

## 036 - Implementeer YAML-parsing voor AI-parsers

### Wat is correct geimplementeerd

- YAML dependency staat in `pubspec` (root en `pma_core`) en parsercode gebruikt `package:yaml`.
- YAML parsing is aanwezig via `YamlAiParser` en `safeParseYaml(...)` in `packages/pma_core/lib/services/ai_parsers.dart`.
- Parser extensiesysteem (`ParserRegistry` + `parseAIResponse`) ondersteunt YAML als first-class format.
- Testdekking is goed: `test/ai_parsers_test.dart` dekt geldige YAML, nested/list, fallback, malformed input en lege input.

### Wat ik nog zou wijzigen

- TODO sprak over oorspronkelijke padlocatie; implementatie zit inmiddels in `packages/pma_core/...` (inhoudelijk correct, todo-pad verouderd).

### Wat ik nog zou toevoegen

- Extra tests voor complexere YAML edge cases (anchors/aliases, expliciete nulls) als die output vanuit AI realistisch is.

### Wat ik nog zou verwijderen

- Geen directe verwijdering nodig.

---

## 037 - Implement usage history tracking voor AI (tokens/requests)

### Wat is correct geimplementeerd

- Persistent usage-model is aanwezig (`AiUsageRecord`) en repositorycontract bestaat (`IAiUsageRepository`).
- Concrete lokale repository bestaat met Hive persistence + filtering/totals (`packages/pma_core/lib/repository/impl/hive_ai_usage_repository.dart`).
- Providers bieden usage updates, history-notifier en aggregaties (per user/per project/totals) in `packages/pma_core/lib/providers/ai/ai_usage_providers.dart`.
- Supabase pad is aanwezig voor aggregate usage (`aiUsageProvider`, `aiUsageUpdateProvider`) en realtime insert subscription in notifier.
- Testdekking bestaat met fake repo en analytics/helpers in `test/ai_usage_provider_test.dart`.

### Wat ik nog zou wijzigen

- Er zit hybride opslagarchitectuur (Supabase aggregate + lokale Hive history) die niet volledig als 1 consistente source-of-truth is afgedwongen.
- Realtime subscription verwerkt inserts, maar robuustere sync/rehydration scenario's (bij reconnect) zijn beperkt uitgewerkt.

### Wat ik nog zou toevoegen

- Integratietests voor end-to-end flow: AI call -> usage record logging -> history provider -> totals met user/project filters.
- Duidelijke datacontract-notitie: welke metrics authoritative uit Supabase komen en welke uit lokale history.

### Wat ik nog zou verwijderen

- Eventuele overlappende of impliciete padclaims in comments zodra de hybride strategie expliciet is gedocumenteerd.

---

## 038 - Splits `providers.dart` en maak extra provider-bestanden

### Wat is correct geimplementeerd

- Core barrel is opgesplitst en verwijst naar een gecentraliseerde index (`packages/pma_core/lib/providers.dart` exporteert `providers/index.dart`).
- Gevraagde providerbestanden bestaan als modules en compat-barrels, waaronder:
  - `packages/pma_core/lib/providers/task/task_providers.dart`
  - `packages/pma_core/lib/providers/notification/notification_providers.dart`
  - `packages/pma_core/lib/providers/sync/sync_providers.dart`
  - `packages/pma_core/lib/providers/analytics/analytics_providers.dart`
  plus compat exports op topniveau (`task_providers.dart`, `notification_providers.dart`, `sync_providers.dart`, `analytics_providers.dart`).

### Wat ik nog zou wijzigen

- Dubbele aanwezigheid (module + compat barrel) is nuttig voor migratie, maar verhoogt exportcomplexiteit zolang cleanup niet afgerond is.

### Wat ik nog zou toevoegen

- Kort migratie-overzicht in docs met canonieke importpaden zodat nieuwe code direct de modulepaden gebruikt.

### Wat ik nog zou verwijderen

- Legacy compat-barrels gefaseerd verwijderen zodra alle interne imports op canonieke paden zitten.

### Impact van jongere TODO op oudere TODO

- TODO 055 (barrel files) heeft TODO 038 verder gestandaardiseerd; 038 is dus niet teniet gedaan, maar in bredere providers-architectuur opgenomen.

---

## 039 - Supabase sync implementation

### Wat is correct geimplementeerd

- Sync providers bestaan (`packages/pma_core/lib/providers/sync/sync_providers.dart`) met statusmodel, sync acties en connectivity-listener.
- `IProjectRepository` bevat sync-methoden (`syncProject`, `syncAllProjects`, `bidirectionalSyncProject`, `watchProjectChanges`, `resolveConflict`).
- `HiveProjectRepository` implementeert bidirectionele sync, conflict-resolutie (last-write-wins) en bulk sync (`packages/pma_core/lib/repository/impl/hive_project_repository.dart`).
- `CloudSyncService` bevat concrete Supabase calls voor create/update/delete/get stream (`packages/pma_core/lib/services/cloud_sync_service.dart`).
- Offline queue handling is deels gekoppeld via dashboard pending sync processing in sync provider.
- Basale tests bestaan in `test/sync_providers_test.dart`.

### Wat ik nog zou wijzigen

- Deel van de sync-tests is vooral interface/callability-georienteerd en valideert beperkte echte Supabase-integratiepaden.
- `CloudSyncService` bevat nog placeholder-achtige paden/comments (`authSignInPlaceholder`, `authSignOutPlaceholder`, bulk delete no-op stijl), wat wijst op onvolledige hardening.
- In `getProjectsStream()` helper in `HiveProjectRepository` staat een triviale filter (`change['id'] == change['id']`) in onderste sync-manager helper; dit is functioneel verdacht en onderhoudstechnisch ruis.

### Wat ik nog zou toevoegen

- Integratietests met gemockte Supabase responses/channels voor conflict-resolutie, realtime updates en foutpaden.
- Duidelijke retry/error policy voor sync failures met metrics.

### Wat ik nog zou verwijderen

- Placeholder auth sync-methoden zodra echte auth-sync flows volledig live zijn.

---

## 040 - Authentication security enhancements

### Wat is correct geimplementeerd

- Captcha na failed attempts is aanwezig in auth flow (eerder geverifieerd rond TODO 014/017 en zichtbaar in auth providers/login UI).
- Sliding window rate limiting (5 pogingen/min) is aanwezig via `LoginRateLimiter` + auth integratie.
- Biometrische authenticatie is aanwezig met platform checks en settings-integratie in auth providers.
- Async settings repository toegang is grotendeels doorgevoerd in auth providers.
- Placeholder auth is vervangen door bredere backend/Supabase-integratie in auth repository/providers (geen pure mock-only flow meer).

### Wat ik nog zou wijzigen

- Security-hardening blijft nodig op opslagstrategie voor biometrische credentials (nu nog gevoelig designpad).
- Dubbele/overlappende limiter logica tussen service en repository blijft risico op inconsistent gedrag.

### Wat ik nog zou toevoegen

- Integratietests op volledig securitypad: failed attempts -> captcha -> lockout/backoff -> recovery.
- Duidelijke security policy doc voor credential handling + biometric fallback.

### Wat ik nog zou verwijderen

- Eventuele resterende placeholder-achtige auth helpermethoden in sync/service lagen die niet voor productie bedoeld zijn.

### Impact van jongere TODO op oudere TODO

- TODO 040 concretiseert en bundelt eerdere auth-verbeteringen (TODO 014/015/016/017/018) en valideert dat die samen een security baseline vormen; het vervangt die niet maar hangt ervan af.

---

## Samenvatting batch 036-040

- Volledig functioneel: TODO 036, TODO 038
- Sterk maar architectonisch nog te harmoniseren: TODO 037
- Functioneel met duidelijke hardening/testdiepte nodig: TODO 039, TODO 040
- Belangrijkste restwerk:
  - AI usage source-of-truth (Supabase vs lokale history) expliciet maken,
  - Supabase sync placeholders en verdachte helperlogica verder opschonen,
  - security flow integratietests verdiepen (captcha/lockout/biometric end-to-end),
  - compat provider-barrels gefaseerd afbouwen na volledige migratie.

---

## Update globaal overzicht na batch 041-045

- Geanalyseerd tot nu: 001-045
- Resterend: 046-075

## 041 - AI usage analytics improvement

### Wat is correct geimplementeerd

- Usage history tracking is aanwezig via `AiUsageRecord`, `AiUsageNotifier`, repository en history provider (`packages/pma_core/lib/providers/ai/ai_usage_providers.dart`, `packages/pma_core/lib/repository/impl/hive_ai_usage_repository.dart`).
- Filtering op history (from/to/userId/projectId) is aanwezig in notifier/repository.
- CSV/JSON export is aanwezig via `exportUsageHistory(...)` in `ai_usage_providers.dart`.
- Project- en user-aggregaties zijn beschikbaar via `aiUsagePerProjectProvider` en `aiUsagePerUserProvider`.
- `promptOverride` en `projectId` worden doorgegeven in AI chat request payload en service calls (`packages/pma_core/lib/providers/ai/ai_chat_providers.dart`).

### Wat ik nog zou wijzigen

- TODO vroeg filtering in `analytics_providers.dart`, maar dat bestand is nu enkel compat-export; de echte logica zit in `ai_usage_providers.dart` (functioneel ok, documentatie/pad verouderd).
- `AIUsageScreen` (`lib/features/ai_usage/ai_usage_screen.dart`) toont nog vooral overzicht + "future features" i.p.v. volledige metrics expansion UI.
- "Use actual pricing from AI provider" is slechts deels ingevuld; kostenberekening blijft grotendeels op record/heuristiek, niet aantoonbaar live provider-pricing gekoppeld in actieve chat flow.

### Wat ik nog zou toevoegen

- End-to-end test: AI request -> usage record met projectId -> history filter -> CSV export.
- Expliciete pricing source-of-truth (model/config/service) zodat `estimatedCost` uniform en herleidbaar is.

### Wat ik nog zou verwijderen

- Verouderde verwijzingen naar oude provider-bestandsnamen in todo/docs.

### Impact van jongere TODO op oudere TODO

- TODO 037 legde de basis; TODO 041 bouwt daarop verder. Zonder extra harmonisatie blijft er wel overlap tussen aggregate usage (Supabase) en lokale history (Hive).

---

## 042 - Project management features expansion

### Wat is correct geimplementeerd

- Paginatie (`getProjectsPaginated`) en efficient single fetch (`getProjectById`) zijn aanwezig in repository + providers.
- Geavanceerde filtering (status, date range, priority, tags) is aanwezig in provider/repository paden.
- Zoek/filter capabilities zijn aanwezig in project providers en UI flow.
- Fuzzy search helper bestaat in `packages/pma_core/lib/providers/project/project_providers.dart`.

### Wat ik nog zou wijzigen

- De "fuzzy" implementatie is in praktijk een contains/word-match benadering; geen echte distance-based fuzzy matching.
- Niet alle uitgebreide filtervelden zijn overal uniform afgedwongen (eerder vastgesteld in batch 008-010).

### Wat ik nog zou toevoegen

- Relevantie-ranking of Levenshtein/trigram variant als echte fuzzy search gewenst is.
- E2E tests voor zoek + filter + paginatie gecombineerd.

### Wat ik nog zou verwijderen

- Overclaiming in comments/docs als "fuzzy" bedoeld wordt als geavanceerde similarity search.

---

## 043 - Dashboard customization features

### Wat is correct geimplementeerd

- Undo/redo, templates, constraints, widget validation en error handling bestaan in dashboard provider/repository lagen (eerder geverifieerd in batch 020-025).
- `customize_dashboard_screen.dart` ondersteunt templates, custom widgets, position updates en save flow.

### Wat ik nog zou wijzigen

- In de UI ontbreken expliciete undo/redo acties, terwijl notifier-capabilities bestaan.
- Widget type validatie blijft permissief fallback-gedrag gebruiken (`fromString` fallback), dus strict-validatieclaim is beperkt.

### Wat ik nog zou toevoegen

- Undo/redo knoppen in `lib/features/dashboard/customize_dashboard_screen.dart` met state-indicatie (`canUndo/canRedo`).
- UI tests die template toepassen + widget verplaatsing + foutstatus (`dashboardErrorProvider`) valideren.

### Wat ik nog zou verwijderen

- UI/completion claims die suggereren dat alle providerfeatures al zichtbaar beschikbaar zijn in het scherm.

### Impact van jongere TODO op oudere TODO

- TODO 043 bundelt meerdere eerdere dashboard-hardenings (020-025), maar UI-exposure loopt nog achter op provider-capabilities.

---

## 044 - Payment integration Stripe

### Wat is correct geimplementeerd

- Payment providers bestaan met checkout-session flow, webhook event handling en retry (`packages/pma_core/lib/providers/payment/payment_providers.dart`).
- Supabase Edge Function voor Stripe webhook bestaat (`supabase/functions/stripe_webhook/index.ts`) met event handling voor `checkout.session.completed` en payment intent events.
- Basis payment UI-integratie bestaat in settings (`lib/features/settings/settings_screen.dart`) met upgrade/retry statusweergave.
- `project_plan_display.dart` leest subscription data inclusief `stripe_customer_id`.
- Testen bestaan voor payment notifier/webhook handling (`test/payment_providers_test.dart`).

### Wat ik nog zou wijzigen

- Dit is nog grotendeels demo/simulatie:
  - checkout session is `demo_session_*`,
  - polling simuleert success,
  - `PaymentService` draait expliciet in "manual mode".
- Stripe signature verificatie in edge function is placeholder (`verifyStripeSignature` retourneert altijd `true`).
- "Stripe SDK integration" in Flutter code is niet werkelijk actief (init in `PaymentService` staat uitgecommentarieerd).

### Wat ik nog zou toevoegen

- Echte backend checkout-session create endpoint en Stripe SDK-init path.
- Robuuste signature verificatie in webhook function.
- End-to-end testflow met echte webhook payload validatie en subscription state transitions.

### Wat ik nog zou verwijderen

- Demo/session placeholder paden zodra productie-Stripe flow live staat.

### Impact van jongere TODO op oudere TODO

- TODO 044 is functioneel gestart maar niet production-complete; latere hardening TODOs moeten dit expliciet als "in progress" behandelen i.p.v. volledig afgerond.

---

## 045 - UI enhancements mention autocomplete

### Wat is correct geimplementeerd

- `CommentSection` bevat @mention autocomplete met `RawAutocomplete`, user suggestion filtering en relevance-sortering (`lib/features/project/widgets/comment_section.dart`).
- Mention parsing/opslag gebeurt bij submit via `CommentModel.parseMentions(...)` en `mentionedUsers` mapping.
- Mentions worden visueel gemarkeerd en klikbaar weergegeven in comment text rendering.
- Integratie met user data is aanwezig via auth/user providers.
- Widget tests bestaan voor autocomplete en mention rendering (`test/comment_section_test.dart`).

### Wat ik nog zou wijzigen

- Mention tap actie is nog placeholder dialog (geen echte profielnavigatie).
- Mapping `username -> userId` en omgekeerd verdient centralisatie om inconsistentie te vermijden.

### Wat ik nog zou toevoegen

- Integratietest die volledige submitflow valideert: tekst met mentions -> opgeslagen `mentionedUsers` -> correcte display na reload.

### Wat ik nog zou verwijderen

- Placeholder mention-tap dialog zodra echte profielroute beschikbaar is.

---

## Samenvatting batch 041-045

- Volledig functioneel: TODO 045
- Functioneel met inhoudelijke afwerking nodig: TODO 041, TODO 042, TODO 043
- Deels/vooral demo-georienteerd en nog niet production-grade: TODO 044
- Belangrijkste restwerk:
  - AI usage pricing + history architectuur expliciet finaliseren,
  - "fuzzy" search claim aligneren met echte searchstrategie,
  - dashboard undo/redo ook in customize UI ontsluiten,
  - Stripe flow van demo naar echte checkout/signature-verified webhook brengen.

---

## Update globaal overzicht na batch 046-050

- Geanalyseerd tot nu: 001-050
- Resterend: 051-075

## 046 - Rate limits UI per operation

### Wat is correct geimplementeerd

- Settings UI voor per-operation limieten is aanwezig in `lib/features/settings/settings_screen.dart` (operation rows, save, queue/backoff controls).
- Configmodel ondersteunt de gevraagde velden (`maxRequestsPerWindow`, `perOperationLimits`, `backoffBaseDelay`, `backoffMaxDelay`, `maxRetryAttempts`, `queueEnabled`) in `packages/pma_core/lib/models/ai_rate_limits_config.dart`.
- Config persist/load loopt via settings providers/repository (`aiRateLimitsConfigProvider`, `HiveSettingsRepository`).
- Testen voor settings-config updates bestaan (`test/settings_screen_test.dart`).

### Wat ik nog zou wijzigen

- Runtime enforcement in de actieve AI-provider blijft onvolledig:
  - per-operation limits worden niet consequent toegepast,
  - `queueEnabled` heeft beperkt effectief runtimegedrag.
- Hierdoor is de UI/config-laag verder dan de daadwerkelijke limiter-semantiek.

### Wat ik nog zou toevoegen

- Integratietests die bewijzen dat aangepaste UI-limieten het gedrag van `aiChatProvider` echt wijzigen per operation.

### Wat ik nog zou verwijderen

- Geen directe verwijdering nodig; wel misleidende "volledig af" claims zonder runtime-e2e bewijs.

### Impact van jongere TODO op oudere TODO

- TODO 046 formaliseert de UI rond TODO 031-034, maar bevestigt ook de bestaande kloof tussen configuratie en actieve enforcement.

---

## 047 - AI parsing extensions

### Wat is correct geimplementeerd

- XML en YAML parsing zijn aanwezig in `packages/pma_core/lib/services/ai_parsers.dart`.
- `parseAIResponse(...)` ondersteunt meerdere formaten en auto-detectie.
- Er is een expliciet extension point via `AiParser` + `ParserRegistry` met runtime registratie van parsers.
- Testdekking in `test/ai_parsers_test.dart` valideert XML, YAML en extensiesysteem.

### Wat ik nog zou wijzigen

- Geen groot functioneel issue; implementatie dekt de acceptance criteria goed.

### Wat ik nog zou toevoegen

- Eventueel tests voor custom parser-failure isolation (één extensie faalt, andere blijven werken).

### Wat ik nog zou verwijderen

- Geen directe verwijdering nodig.

---

## 048 - Application configuration expansions

### Wat is correct geimplementeerd

- Configuratie is uitgebreid en gecentraliseerd in `lib/core/config/app_config.dart` met extra env vars (o.a. `OPENAI_API_KEY`, `STRIPE_*`, `OPENAI_BASE_URL`, `SENTRY_DSN`, `LOG_LEVEL`, `FIREBASE_API_KEY`).
- `main.dart` gebruikt `AppConfig.initialize()` vroeg in startup en leest config via typed getters.
- Validatie en duidelijke waarschuwingen/fouten voor ontbrekende required keys zijn aanwezig.
- Tests voor config-initialisatie en uitbreidbaarheid bestaan in `test/core/config/app_config_test.dart`.

### Wat ik nog zou wijzigen

- Legacy `initEnv()` in `main.dart` is grotendeels redundante/deprecated flow (met gecommentarieerde OPENAI-key handling) nu `AppConfig` de canonieke bron is.

### Wat ik nog zou toevoegen

- Kleine cleanup/migratienota zodat alle configuratie expliciet via `AppConfig` loopt en legacy helpers verwijderd kunnen worden.

### Wat ik nog zou verwijderen

- Verouderde `initEnv()` codepad zodra bevestigd is dat geen callsite het nog nodig heeft.

---

## 049 - Repository refactoring

### Wat is correct geimplementeerd

- Repositories zijn opgesplitst in interfaces + implementaties (`i_*_repository.dart` + `impl/*`) met aparte modelmodules (`repository/models/*`).
- Brede adoptie van abstrahering voor testbaarheid is aanwezig (`IProjectRepository`, `IAuthRepository`, `IDashboardRepository`, `IAiUsageRepository`).
- Testcode gebruikt fake/mock repositories op interface-niveau in meerdere suites.
- Meerdere implementaties bevatten expliciete refactor-notes naar issue 049.

### Wat ik nog zou wijzigen

- Sommige implementatiebestanden blijven zeer groot (met helperklassen en meerdere verantwoordelijkheden), dus "split when they grow" is slechts deels voltooid.

### Wat ik nog zou toevoegen

- Verdere opsplitsing op domeinverantwoordelijkheid (bijv. sync managers, data mappers, auth ops in aparte bestanden met small interfaces).

### Wat ik nog zou verwijderen

- Restant-compat exports/paden die niet meer nodig zijn na volledige migratie.

---

## 050 - Auth backend integration

### Wat is correct geimplementeerd

- Auth flow gebruikt echte Supabase backend calls voor sign-in/sign-up/sign-out in auth repository/provider lagen.
- `IAuthRepository` interface en `HiveAuthRepository` implementatie zijn aanwezig en breed geïnjecteerd in providers/tests.
- User management methoden (users/roles/groups CRUD) bestaan in repository interface/implementatie.

### Wat ik nog zou wijzigen

- Acceptance item "invite user en reset password methoden" is niet volledig afgedekt in auth repository-interface:
  - geen expliciete `inviteUser(...)`/`resetPassword(...)` methoden in `IAuthRepository`,
  - in providerlaag ontbreken dedicated reset/invite auth-methoden.
- "Sync capabilities voor auth data" loopt nog via placeholder cloud sync calls (`authSignInPlaceholder`, `authSignOutPlaceholder`) i.p.v. echte auth-sync contracten.
- Testen voor backend integratie zijn deels documentair/oppervlakkig (`test/auth_providers_test.dart` noemt expliciet beperkte mockbaarheid).

### Wat ik nog zou toevoegen

- Expliciete interface-methoden voor invite/reset met concrete Supabase-implementaties.
- Echte auth sync-methoden (geen placeholders) of verwijdering van sync-claims als dat buiten scope valt.
- Integratietests voor kritieke backend-auth scenario's (signup/login/logout/reset).

### Wat ik nog zou verwijderen

- Placeholder auth-sync calls zodra productie-equivalent beschikbaar is.

### Impact van jongere TODO op oudere TODO

- TODO 050 versterkt TODO 013/040 richting backend-first auth, maar laat nog openstaande gaten rond invite/reset en auth-sync hardening.

---

## Samenvatting batch 046-050

- Volledig functioneel: TODO 047, TODO 048
- Sterk maar nog niet volledig afgerond: TODO 049
- Deels functioneel met belangrijke runtime/contract gaten: TODO 046, TODO 050
- Belangrijkste restwerk:
  - rate-limit instellingen end-to-end afdwingen in actieve AI-runtime,
  - repository-splitsing verder doorzetten op grote implementatiebestanden,
  - auth invite/reset expliciet in repository + providercontract opnemen,
  - auth sync placeholders vervangen door echte backend flows.

---

## Update globaal overzicht na batch 051-055

- Geanalyseerd tot nu: 001-055
- Resterend: 056-075

## 051 - Pubspec metadata dependencies

### Wat is correct geimplementeerd

- Appnaam is aangepast naar `project_management_app` in `pubspec.yaml`.
- Beschrijving is geüpdatet naar een inhoudelijke projectbeschrijving.
- Er is metadata aanwezig voor `homepage`, `repository` en `issue_tracker`.
- Er zijn comments aanwezig over dependency cleanup en meerdere oude afhankelijkheden zijn verwijderd.

### Wat ik nog zou wijzigen

- Acceptance vroeg `intl: ^0.19.0`; in zowel root als `packages/pma_core/pubspec.yaml` staat nog `intl: any`.
- Acceptance vroeg GitHub homepage/repository met `project-management-app` (streepjes), terwijl huidige waarden `myprojectmanagementapp.com` en `project_management_app` (underscore) gebruiken.

### Wat ik nog zou toevoegen

- Eenduidige metadata-alignment met de afgesproken GitHub URL-conventie (hyphenated repo pad).
- Vastgepinde `intl` versie volgens l10n-vereiste.

### Wat ik nog zou verwijderen

- Losse/ambigue `intl: any` om dependency drift te beperken.

---

## 052 - README upgrade

### Wat is correct geimplementeerd

- README bevat badges, uitgebreide secties, architectuurdiagram (Mermaid), documentatietabel, featurelijst, en secties voor Contributing/Roadmap.
- CI/CD, release, accessibility, feature flags en analytics documentatieblokken zijn uitgebreid toegevoegd.

### Wat ik nog zou wijzigen

- Screenshotsectie claimt 8 specifieke imagebestanden met `.png`, maar de map `images/` bevat momenteel slechts 4 `.jpg` bestanden (`one.jpg`, `two.jpg`, `three.jpg`, `four.jpg`).
- Daardoor lijken meerdere screenshotverwijzingen in README feitelijk stuk/verouderd.

### Wat ik nog zou toevoegen

- Werkende screenshot-assets met consistente bestandsnamen/extensies die overeenkomen met README-referenties.

### Wat ik nog zou verwijderen

- Niet-bestaande screenshotlinks in README totdat de assets bestaan.

---

## 053 - Analysis options stricter

### Wat is correct geimplementeerd

- `analysis_options.yaml` include is ingesteld op `package:flutter_lints/flutter.yaml`.
- Gevraagde rules staan aan/ingesteld:
  - `prefer_const_constructors: true`
  - `prefer_const_declarations: true`
  - `avoid_print: false`
  - `use_key_in_widget_constructors: false`

### Wat ik nog zou wijzigen

- Acceptance verwees naar `flutter analyze --no-fatal-infos`; dat commando-argument bestaat niet in moderne Flutter/Dart tooling. Dit punt is inhoudelijk achterhaald.

### Wat ik nog zou toevoegen

- Korte analyzegids in docs met huidige correcte analyzer-instellingen/verwachtingen (zodat backlogtekst niet misleidt).

### Wat ik nog zou verwijderen

- Verouderde verwijzingen naar niet-ondersteunde analyzer-flags in todo-documentatie.

---

## 054 - Models freezed migration

### Wat is correct geimplementeerd

- Freezed/json_serializable usage is breed aanwezig in modelbestanden (`@freezed`, `*.freezed.dart`, `*.g.dart`) in zowel `lib/models` als `packages/pma_core/lib/models`.
- Build tooling/dependencies voor codegen staan in pubspecs (root + core package).
- Hive adapter migratiepad is aanwezig via `migrated_model_adapters.dart` en veilige adapterregistratie.
- Repositories/providers/tests zijn grotendeels aangepast op de gegenereerde modellen.

### Wat ik nog zou wijzigen

- De codebase bevat nog dubbele modelsets (root + `pma_core`) wat onderhoudslast en drift-risico verhoogt.
- Versions wijken af van de oorspronkelijke todo-tekst (nieuwere versies), wat functioneel ok is maar documentatie mismatch geeft.

### Wat ik nog zou toevoegen

- Expliciete canonical model-locatie-afspraak (welke set leidend is) om dubbele modeldefinities verder te reduceren.

### Wat ik nog zou verwijderen

- Overblijvende duplicaten zodra de migratie volledig op 1 modelset is geconsolideerd.

### Impact van jongere TODO op oudere TODO

- TODO 070 (modularisatie) heeft TODO 054 uitgebreid: migratie is geslaagd, maar leverde ook tijdelijke modelduplicatie op tussen applaag en core package.

---

## 055 - Barrel files providers

### Wat is correct geimplementeerd

- Centrale provider barrels bestaan:
  - `packages/pma_core/lib/providers.dart`
  - `packages/pma_core/lib/providers/index.dart`
- Repository barrels bestaan (`repository/repository.dart`, `repository/repository_interfaces.dart`, `repository/repository_impl.dart`).
- Hoofdbarrel `packages/pma_core/lib/pma_core.dart` exporteert models/providers/repository/services/utils/widgets.

### Wat ik nog zou wijzigen

- Acceptance vroeg per-feature `lib/features/xxx/providers/index.dart`; zulke feature-indexbestanden bestaan niet.
- Acceptance vroeg brede importvervanging naar barrel-imports, maar er zijn nog veel directe imports (`package:pma_core/providers/...`, `package:pma_core/models/...`, `package:pma_core/repository/...`) in de appcode.

### Wat ik nog zou toevoegen

- Gefaseerde importmigratie met lint/check die nieuwe directe diepe imports blokkeert waar een barrel beschikbaar is.

### Wat ik nog zou verwijderen

- Legacy/compat providerpaden zodra barrel-adoptie echt voltooid is.

### Impact van jongere TODO op oudere TODO

- TODO 055 bouwt voort op TODO 038, maar is nog niet volledig af qua adoptie en feature-level indexstructuur.

---

## Samenvatting batch 051-055

- Volledig functioneel: TODO 053 (inhoudelijk), TODO 054 (grootste deel)
- Functioneel met duidelijke correcties nodig: TODO 051, TODO 052, TODO 055
- Belangrijkste restwerk:
  - pubspec metadata/versioning aligneren met afgesproken repo- en `intl`-vereisten,
  - README screenshotreferenties laten overeenkomen met echte assets,
  - barrel-adoptie werkelijk doorvoeren (feature indexes + import cleanup),
  - modelduplicatie tussen app en core package verder reduceren.

---

## Update globaal overzicht na batch 056-060

- Geanalyseerd tot nu: 001-060
- Resterend: 061-075

## 056 - Remove legacy UI kit

### Wat is correct geimplementeerd

- `get: ^4.x` staat niet meer in `pubspec.yaml`.
- Er zijn geen actieve `GetX`/`GetMaterialApp`/`package:get/get.dart` imports of usages gevonden in de Dart-code.
- `main.dart` draait op `MaterialApp`/`MaterialApp.router` en gebruikt Riverpod + eigen thema (`AppTheme.lightTheme`/`AppTheme.darkTheme`).
- Thema-inrichting zit centraal in `lib/core/theme.dart` met Material 3-configuratie.

### Wat ik nog zou wijzigen

- Acceptance noemt expliciet "alle screens"; dat is in code wel consistent met huidige Material/Riverpod stack, maar niet als expliciete migratielijst gedocumenteerd.

### Wat ik nog zou toevoegen

- Korte migratienota in docs met "legacy UI kit verwijderd" + checklist van vervangen componentgroepen, zodat regressies later makkelijker te detecteren zijn.

### Wat ik nog zou verwijderen

- Geen directe verwijdering nodig; implementatie oogt opgeschoond.

---

## 057 - AiService abstraction

### Wat is correct geimplementeerd

- `AiService` abstractie bestaat met `Future<String> generate(...)` plus aanvullende contractmethoden in `packages/pma_core/lib/services/ai/ai_service.dart`.
- `OpenAiLangchainService` implementeert `AiService` in `packages/pma_core/lib/services/ai/openai_langchain_service.dart`.
- `aiServiceProvider` levert interface-typed service (`Provider<AiService>`) in `packages/pma_core/lib/providers/ai/ai_providers.dart`.
- Callsites in AI-chat/planning-schermen gebruiken de provider (`ref.read(aiServiceProvider)...`) in plaats van directe concrete service-coupling.
- Tests voor abstractie/override/switching bestaan in `test/ai_service_abstraction_test.dart`.

### Wat ik nog zou wijzigen

- Acceptance vroeg pad `lib/core/services/ai/ai_service.dart`; door modularisatie zit dit nu in `packages/pma_core/...` (functioneel ok, maar todo-pad verouderd).
- "Feature flag" switching is slechts gedeeltelijk ingevuld:
  - provider schakelt op `AiSettings.enableOpenAILangchain` (settings-toggle),
  - `OpenAiLangchainService.fromFeatureFlag(...)` bestaat, maar wordt niet in de actieve providerselectie gebruikt.

### Wat ik nog zou toevoegen

- Eenduidige backend-resolutie via feature-flag service (bijv. `ai_backend = grok/gemini/claude/openai_langchain`) i.p.v. enkel boolean settings-toggle.

### Wat ik nog zou verwijderen

- Dubbelzinnigheid in naming: "OpenAiLangchainService" met default `backend: grok` kan verwarrend zijn voor onderhoud.

### Impact van jongere TODO op oudere TODO

- TODO 070 (modularisatie) heeft de bestandslocatie verschoven maar TODO 057 functioneel niet teniet gedaan.

---

## 058 - Firebase FCM only

### Wat is correct geimplementeerd

- Firebase usage in appstartup is beperkt tot `firebase_core` + `firebase_messaging` (`lib/main.dart`).
- `NotificationService` in core beschrijft expliciet FCM-only gedrag (`packages/pma_core/lib/services/notification_service.dart`).
- Root dependencies bevatten alleen `firebase_core` en `firebase_messaging` aan Firebase-kant.
- Er is een gerichte testsuite `test/firebase_fcm_only_test.dart` die de FCM-only baseline valideert.

### Wat ik nog zou wijzigen

- Acceptance vroeg expliciet `supabase_fcm_setup.md`; dit bestand is niet aanwezig.
- Bestaande `docs/supabase-setup.md` bevat Edge Functions, maar geen uitgewerkte Supabase -> FCM flowdocumentatie als apart setupdocument.

### Wat ik nog zou toevoegen

- `docs/supabase_fcm_setup.md` met:
  - tokenregistratie-flow,
  - Edge Function triggerpad,
  - payloadvoorbeeld,
  - foutafhandeling/retry,
  - productie-secrets/checklist.

### Wat ik nog zou verwijderen

- Geen directe codeverwijdering nodig zolang push-notificaties via huidige FCM-stack werken.

---

## 059 - Test coverage badge

### Wat is correct geimplementeerd

- CI bevat `flutter test --coverage` in workflows (`.github/workflows/flutter_test.yml`, `.github/workflows/ci.yml`).
- Coverage upload naar Codecov is aanwezig via `codecov/codecov-action@v4`.
- README bevat codecov badge met link naar repository coverage.
- `codecov.yml` zet projecttarget op `85%`.

### Wat ik nog zou wijzigen

- Geen kritieke functionele afwijking gevonden voor deze acceptance.

### Wat ik nog zou toevoegen

- Optioneel: aparte branch/status gate voor `packages/pma_core` subset-coverage als "core + repositories" expliciet bewaakt moet blijven.

### Wat ik nog zou verwijderen

- Geen directe verwijdering nodig.

### Impact van jongere TODO op oudere TODO

- TODO 075 (release pipeline) bouwt hierop voort; coverage-signalen zijn nu bruikbaar als quality gate in releaseflow.

---

## 060 - Golden tests UI

### Wat is correct geimplementeerd

- Golden tests bestaan voor de gevraagde UI-categorieen:
  - dashboard card (`test/golden/dashboard_card_test.dart`),
  - AI chat bubble/scherm (`test/golden/ai_chat_bubble_test.dart`),
  - gantt chart (`test/golden/gantt_chart_test.dart`),
  - task list item-context (`test/golden/task_list_item_test.dart`),
  - theme switcher (`test/golden/theme_switcher_test.dart`).
- Golden baseline afbeeldingen zijn aanwezig in `test/goldens/*.png`.
- Globale golden testconfig is aanwezig via `test/flutter_test_config.dart` + `test/helpers/golden_test_setup.dart` (tolerance/update config).
- Spot-check uitgevoerd: `test/golden/dashboard_card_test.dart` passeert.

### Wat ik nog zou wijzigen

- Naming in acceptance en implementatie wijkt licht af (bijv. `DashboardCard` vs `ProjectCardWidget`, task-item test via `TaskChartWidget` context). Functioneel waarschijnlijk afgedekt, maar semantisch minder scherp.

### Wat ik nog zou toevoegen

- Korte README/doc sectie voor het draaien van golden tests lokaal (`flutter test --tags=golden`, update-flow met `UPDATE_GOLDENS=1`).

### Wat ik nog zou verwijderen

- Geen directe verwijdering nodig.

---

## Samenvatting batch 056-060

- Volledig functioneel: TODO 056, TODO 059, TODO 060
- Functioneel met gerichte afwerking nodig: TODO 057
- Deels functioneel met duidelijke documentatiegap: TODO 058
- Belangrijkste restwerk:
  - AI backend-selectie echt feature-flagged en eenduidig maken,
  - expliciete `supabase_fcm_setup.md` toevoegen met end-to-end FCM-flow,
  - kleine naming/docs-alignments voor golden/component-benamingen.

---

## Update globaal overzicht na batch 061-065

- Geanalyseerd tot nu: 001-065
- Resterend: 066-075

## 061 - GitHub Actions CI/CD

### Wat is correct geimplementeerd

- Workflowbestanden aanwezig volgens acceptance:
  - `.github/workflows/flutter_test.yml` (analyze, tests, coverage, web build),
  - `.github/workflows/flutter_desktop.yml` (Windows/macOS/Linux build),
  - `.github/workflows/semantic_pr.yml`,
  - `.github/workflows/release.yml`.
- Triggers op `pull_request` en `push` naar `main` zijn aanwezig op test- en desktop-workflows.
- `semantic_pr.yml` valideert conventional PR titles via `amannn/action-semantic-pull-request@v5`.
- `release.yml` draait semantic-release op `push` naar `main`.

### Wat ik nog zou wijzigen

- Acceptance "trigger on pull_request and push main" is functioneel afgedekt voor build/test. Voor release/semantics is trigger bewust opgesplitst (PR title check vs main release), wat logisch is maar niet expliciet beschreven in todo.

### Wat ik nog zou toevoegen

- Korte workflowmatrix in docs die per workflow de trigger en het doel toont, zodat "wat draait wanneer" expliciet is.

### Wat ik nog zou verwijderen

- Geen directe verwijdering nodig.

---

## 062 - Hive encryption

### Wat is correct geimplementeerd

- `EncryptedHiveBox` wrapper bestaat in `packages/pma_core/lib/repository/encrypted_hive_box.dart`.
- Implementatie gebruikt `encrypt` + `FlutterSecureStorage` voor key generatie/opslag, en `HiveAesCipher` voor box-encryptie.
- Gevraagde gevoelige boxes staan als encrypted geconfigureerd in `HiveInitializer`:
  - `auth`, `settings`, `ai_usage`, `local_tokens`.
- `HiveInitializer` routeert gevoelige boxen via `EncryptedHiveBox(...).open()`.
- Testdekking aanwezig in `test/encrypted_hive_box_test.dart` (geen plaintext op disk, sleutelbeheer, read/write).

### Wat ik nog zou wijzigen

- Er is dubbele initialisatielogica in startup (`main.dart` opent enkele encrypted boxes al expliciet, daarna nog `HiveInitializer.initialize()`), wat risico op drift geeft.

### Wat ik nog zou toevoegen

- Een enkele canonical startup-flow voor box-openen (bij voorkeur uitsluitend via `HiveInitializer`) + regressietest op startup-initvolgorde.

### Wat ik nog zou verwijderen

- Redundante handmatige box-open calls in `main.dart` zodra centralisatie in `HiveInitializer` volledig bevestigd is.

---

## 063 - Supabase setup documentation

### Wat is correct geimplementeerd

- Er is een uitgebreide setupdoc: `docs/supabase-setup.md`.
- Document bevat de gevraagde onderdelen:
  - SQL schema,
  - RLS policies,
  - storage buckets policies,
  - edge functions,
  - setup/deploy instructies.
- Sectie "How to add a new policy" is aanwezig in dezelfde doc.

### Wat ik nog zou wijzigen

- Todo vraagt "create new MD file"; functioneel gehaald, maar bestandsnaam wijkt af van mogelijk verwachte naming-conventie in backlogtekst.

### Wat ik nog zou toevoegen

- Link vanuit hoofd-README dicht bij backend setup-sectie voor snellere discoverability.

### Wat ik nog zou verwijderen

- Geen directe verwijdering nodig.

---

## 064 - Infinite scroll lists

### Wat is correct geimplementeerd

- Providerlaag gebruikt `AsyncNotifier`-patroon met paginatiestaat voor projecten en taken:
  - `ProjectsNotifier` met `currentPage`, `hasMore`, `isLoadingMore`, `loadMoreProjects()`.
  - `TaskNotifier` met analoge velden en `loadMoreTasks()`.
- Scrollcontroller-gedreven loading is aanwezig in UI:
  - `ProjectScreen` met `_scrollController` + `_onScroll()`,
  - `ProjectDetailScreen` met taak-kolom controllers en load-more trigger.
- Loading indicator en "End reached" footer zijn aantoonbaar aanwezig voor tasks in `project_detail_screen.dart`.

### Wat ik nog zou wijzigen

- Voor ProjectsList is de implementatie niet volledig aligned met acceptance:
  - `ProjectScreen` gebruikt eigen lokale paginatiestaat (`_page`, `_hasMore`, `_isLoading`) i.p.v. direct `ProjectsNotifier.loadMoreProjects()`.
  - expliciete "end reached" boodschap voor projecten ontbreekt; vooral loading-state is zichtbaar.
- TODO spreekt over ProjectsList + TasksList; huidige "end reached"-UX is duidelijker aanwezig bij tasks dan bij projects.

### Wat ik nog zou toevoegen

- Eenduidige projectlist-footer met `end reached`-melding + retry bij loadMore fout, analoog aan tasks.
- Widget/integratietests voor project infinite-scroll gedrag (append, hasMore=false, fout+retry).

### Wat ik nog zou verwijderen

- Dubbele paginatielogica (UI-lokaal vs notifier) zodra gekozen is voor 1 source-of-truth.

### Impact van jongere TODO op oudere TODO

- TODO 064 bouwt op eerdere paginatie-werk uit TODO 002/004, maar voegt nu een tweede paginatiepad toe in UI, wat onderhoudsrisico introduceert.

---

## 065 - App size analysis

### Wat is correct geimplementeerd

- Analyse-doc bestaat: `docs/app-size-analysis.md` met command en evaluatiekader.
- README bevat sectie "App Size Analysis (Issue #065)".
- Er zijn concrete cleanup-notes voor ongebruikte dependencies/assets/icons in README en `pubspec.yaml` comments.

### Wat ik nog zou wijzigen

- Acceptance vroeg feitelijke run van `flutter build apk --analyze-size --split-per-abi`; hiervoor is geen hard bewijs in repo-output opgenomen.
- In zowel README als `docs/app-size-analysis.md` staan veel velden nog op `TBD`/template-status, inclusief final APK sizes.

### Wat ik nog zou toevoegen

- Werkelijke meetresultaten (ABI grootte, before/after delta, analyze-size snippets) invullen i.p.v. placeholders.
- CI artifactstap voor size reports/APKs indien dit structureel bewaakt moet worden.

### Wat ik nog zou verwijderen

- Placeholdertabellen (`TBD`) zodra echte metingen zijn toegevoegd.

---

## Samenvatting batch 061-065

- Volledig functioneel: TODO 061, TODO 062, TODO 063
- Grotendeels functioneel met belangrijke UX/architectuurafwerking: TODO 064
- Deels functioneel/documentair, maar bewijs van uitvoering ontbreekt: TODO 065
- Belangrijkste restwerk:
  - project infinite-scroll pad harmoniseren met notifier en een expliciete end-state tonen,
  - app-size analyse concretiseren met echte build-uitvoer en ingevulde metrics,
  - startup-encryptieflow centraliseren om dubbele box-openpaden te vermijden.

---

## Update globaal overzicht na batch 066-070

- Geanalyseerd tot nu: 001-070
- Resterend: 071-075

## 066 - Offline indicator sync status

### Wat is correct geimplementeerd

- Globale indicator boven appbar is aanwezig via `OfflineIndicatorAppBar` in `packages/pma_core/lib/widgets/offline_indicator.dart` en wordt gebruikt in routing/main flows.
- Statuskleuren matchen acceptance:
  - groen voor `synced`,
  - oranje voor `syncing`,
  - rood voor `offline` (`OfflineStatusState.statusColor` in `packages/pma_core/lib/providers/offline_status_providers.dart`).
- Tap opent status-sheet met `last sync` en handmatige syncknop (`manualSync`).

### Wat ik nog zou wijzigen

- Er lijken meerdere sync-status paden/providers naast elkaar te bestaan (`offline_status_providers.dart` en legacy/andere sync providers), wat op termijn inconsistent gedrag kan geven.

### Wat ik nog zou toevoegen

- Gerichte widgettest voor indicator-kleur/status-sheet flow (offline -> syncing -> synced + manual sync knop).

### Wat ik nog zou verwijderen

- Eventuele legacy sync-status providerpaden zodra 1 canonical provider gekozen is.

---

## 067 - Onboarding flow

### Wat is correct geimplementeerd

- First-launch wizardflow is aanwezig in `lib/core/widgets/onboarding_wizard.dart` met stappen:
  - welcome,
  - create first project,
  - AI intro,
  - invite team.
- Startup-gating staat in `lib/main.dart` (`_AppBootstrapGate`) en toont onboarding alleen op first launch.
- Persistente flag via `shared_preferences` + Riverpod provider is aanwezig in `packages/pma_core/lib/providers/onboarding_providers.dart`.

### Wat ik nog zou wijzigen

- Er is geen duidelijke dedicated testfile die first-launch persistencepad (`isFirstLaunch`/`markOnboardingCompleted`) integraal valideert.

### Wat ik nog zou toevoegen

- Unit/integratietests voor onboarding persistence en bootstrap-gate gedrag:
  - eerste run toont wizard,
  - na completion/skip niet opnieuw tonen.

### Wat ik nog zou verwijderen

- Geen directe verwijdering nodig.

---

## 068 - Accessibility improvements

### Wat is correct geimplementeerd

- Toegankelijkheidsdocumentatie is uitgebreid aanwezig in `docs/accessibility.md` met checklist, TalkBack/VoiceOver/web flows.
- Semantics-helpers en brede Semantics-toepassing zijn zichtbaar in code (`packages/pma_core/lib/utils/accessibility_helper.dart`, onboarding/offline/project views).
- Donker-modus contrastaanpak is verwerkt in `lib/core/theme.dart` en er wordt verwezen naar contrast-tests (`test/core/theme_contrast_test.dart`).
- Accessibility widgettests aanwezig voor project views (`test/features/project/project_views_accessibility_test.dart`).

### Wat ik nog zou wijzigen

- Acceptance eist "all buttons, icons, lists"; de codebase heeft veel Semantics, maar dit blijft in praktijk lastig volledig bewezen zonder systematische coverage-rapportage per scherm.
- TalkBack/VoiceOver/web validatie is vooral documentair beschreven; er is geen machine-verifieerbaar bewijs in repo van uitgevoerde device-runs.

### Wat ik nog zou toevoegen

- Een lightweight accessibility audit-matrix per hoofdscherm (met datum/resultaat) om handmatige testclaims traceerbaar te maken.

### Wat ik nog zou verwijderen

- Geen directe verwijdering nodig.

---

## 069 - Gantt chart upgrade

### Wat is correct geimplementeerd

- Migratie van legacy naar moderne gantt-implementatie is doorgevoerd:
  - dependency `gantt_chart` actief,
  - `legacy_gantt_chart` verwijderd,
  - `ModernGanttChart` wrapper in `packages/pma_core/lib/widgets/modern_gantt_chart.dart`.
- Donker-modus en Material 3 theming zijn geïntegreerd via `Theme.of(context).colorScheme`.
- Touch/drag gestures zijn aanwezig (horizontal drag update/end) met commit callbacks.
- Tests bestaan voor drag commit en exportflow (`test/core/widgets/modern_gantt_chart_test.dart`), plus goldens voor gantt (licht/donker).

### Wat ik nog zou wijzigen

- In doc staat nog een verouderde verwijzing naar `lib/core/widgets/modern_gantt_chart.dart`, terwijl canonical implementatie in `packages/pma_core/...` staat.

### Wat ik nog zou toevoegen

- E2E project-view test die task-reschedule via gantt drag end-to-end naar provider persistence volgt.

### Wat ik nog zou verwijderen

- Verouderde padreferenties in gantt-documentatie.

### Impact van jongere TODO op oudere TODO

- TODO 069 versterkt TODO 065 (size cleanup) door legacy dependency-vermindering en hangt samen met TODO 060 (golden tests) voor visuele regressiebewaking.

---

## 070 - Modularization core package

### Wat is correct geimplementeerd

- `packages/pma_core` bestaat en exporteert kernlagen (`models`, `providers`, `repository`, `services`, `utils`, `widgets`) via `packages/pma_core/lib/pma_core.dart`.
- App-features blijven in hoofdapp en importeren `pma_core` breed in featurecode.
- `go_router` deferred loading is daadwerkelijk aanwezig in `lib/core/routes.dart` met deferred imports en `_DeferredFeatureScreen(loadLibrary: ...)`.
- Modularisatie-statusdocument is aanwezig in `docs/modularization.md` met acceptance mapping.

### Wat ik nog zou wijzigen

- Er zijn nog restanten/duplicatie op appniveau buiten `pma_core` (bijv. sommige modellen/legacy compat-paden), dus modularisatie is functioneel geslaagd maar niet volledig opgeschoond.

### Wat ik nog zou toevoegen

- Consolidatieplan voor resterende duplicaten/compat exports met duidelijke removal milestones.

### Wat ik nog zou verwijderen

- Legacy compat-shims en dubbele modelpaden zodra migratie volledig stabiel is.

### Impact van jongere TODO op oudere TODO

- TODO 070 heeft eerdere todo-documentatie (001/013/057 etc.) op bestandslocaties deels verouderd gemaakt zonder die implementaties functioneel te breken.

---

## Samenvatting batch 066-070

- Volledig functioneel: TODO 066, TODO 067, TODO 069, TODO 070
- Functioneel maar deels documentair bewezen en nog auditdiepte nodig: TODO 068
- Belangrijkste restwerk:
  - sync-status providerlandschap consolideren rond 1 canonical pad,
  - onboarding first-launch persistence expliciet unit/integratietesten,
  - accessibility handmatige verificaties traceerbaar vastleggen,
  - modularisatie-restduplicaten en verouderde padverwijzingen gefaseerd opschonen.

---

## Update globaal overzicht na batch 071-075

- Geanalyseerd tot nu: 001-075
- Resterend: 000

## 071 - Feature flags via Supabase

### Wat is correct geimplementeerd

- `FeatureFlagNotifier` + `featureFlagProvider` bestaan en laden flags via Supabase met cache-first gedrag (`packages/pma_core/lib/core/providers/feature_flag_provider.dart`).
- Service leest/schrijft `feature_flags` via Supabase (`select` + `upsert`) en cachet in Hive (`packages/pma_core/lib/core/services/feature_flag_service.dart`).
- Stale-cache handling, background refresh, lifecycle refresh (op resume) en fail-open/fallbacks zijn aanwezig.
- Feature flags worden effectief gebruikt in gevraagde paden:
  - onboarding gating (`onboarding_enabled`) in `lib/core/widgets/onboarding_wizard.dart`.
  - gantt gating (`gantt_chart_enabled`) in `lib/features/projects/views/project_gantt_view.dart`.
  - AI gating (`ai_assistant_enabled`, `ai_advanced_planning`) in `packages/pma_core/lib/providers/ai/ai_chat_providers.dart`.
- Testdekking is aanwezig voor service/provider/resolver en UI-gating (`test/core/feature_flag_service_test.dart`, `test/core/feature_flag_provider_test.dart`, `test/features/feature_flags/feature_flag_gating_test.dart`).

### Wat ik nog zou wijzigen

- Geen kritieke afwijking t.o.v. acceptance criteria; de kern van TODO 071 is functioneel gerealiseerd.

### Wat ik nog zou toevoegen

- Optioneel: extra integratietest met echte Supabase testschema om write-failures door RLS-policy expliciet te valideren.

### Wat ik nog zou verwijderen

- Geen directe verwijdering nodig.

---

## 072 - Global ErrorBoundary + breadcrumbs

### Wat is correct geimplementeerd

- Een globale `ErrorBoundary` widget bestaat en wordt rond de volledige appboom geplaatst (`lib/main.dart`, `lib/core/widgets/error_boundary.dart`).
- Startup is beschermd met `runZonedGuarded` en ongevangen errors worden naar Sentry gestuurd.
- ErrorBoundary installeert Flutter/Platform error hooks, rapporteert uitzonderingen, en toont een restartbare fallback UI.
- Breadcrumb logging voor user actions is aanwezig via `AppLogger.userAction(...)` en Sentry breadcrumb calls (`packages/pma_core/lib/services/app_logger.dart`, `lib/core/services/sentry_service.dart`).

### Wat ik nog zou wijzigen

- Acceptance zegt "log all user actions"; in praktijk is dit afhankelijk van consistente callsite-adoptie van `AppLogger.userAction(...)`. Technisch is de infrastructuur aanwezig, maar volledige dekking blijft een disciplinevraag.

### Wat ik nog zou toevoegen

- Eventueel een kleine lint- of code review checklistregel voor nieuwe feature-acties: "voeg userAction breadcrumb toe voor kritieke interacties".

### Wat ik nog zou verwijderen

- Geen directe verwijdering nodig.

---

## 073 - Analytics implementatie

### Wat is correct geimplementeerd

- `AnalyticsService` is abstract gemaakt met concrete `SupabaseAnalyticsService` implementatie (`packages/pma_core/lib/core/services/analytics_service.dart`).
- Canonieke eventnamen bestaan en bevatten de gevraagde events (`project_created`, `task_completed`, `ai_used`, `invite_sent`) in `packages/pma_core/lib/core/services/analytics_events.dart`.
- Event-tracking callsites zijn aanwezig in functionele flows:
  - `ai_used` in AI chat provider,
  - `task_completed` in task provider,
  - `invite_sent` in invitation/member services.
- Offline queue/retry voor analytics events is aanwezig in de Supabase analytics service.
- Tests bestaan voor analytics gedrag en duplicate-protectie rond project-create sync flow (`test/core/analytics_service_test.dart`, `test/core/analytics_no_duplicate_project_created_test.dart`).

### Wat ik nog zou wijzigen

- `project_created` wordt in project provider nu gelogd via `AppLogger.event(...)` i.p.v. expliciete `AnalyticsService.logEvent(...)` callsite. Dit werkt voor observability, maar maakt analytics-backend wisselbaarheid minder strikt dan bij de andere drie kern-events.

### Wat ik nog zou toevoegen

- Expliciete `AnalyticsService.logEvent(AnalyticsEventName.projectCreated, ...)` in project-create pad voor volledige uniformiteit met de abstractielaag.

### Wat ik nog zou verwijderen

- Geen directe verwijdering nodig.

---

## 074 - PWA support web

### Wat is correct geimplementeerd

- `web/manifest.json` is aanwezig met naam/short_name/description/thema/iconen.
- `web/index.html` bevat manifest-link en relevante PWA meta-tags.
- Service worker strategie loopt via Flutter web bootstrap (single strategy), en CI valideert service worker registratie + cache + offline reload (`.github/workflows/flutter_test.yml`).
- Uitgebreide verificatiedoc is aanwezig met handmatige Chrome-offline stappen (`docs/pwa-support.md`).

### Wat ik nog zou wijzigen

- Acceptance noemt "add ... service worker"; in huidige Flutter-architectuur is de service worker build-generated (`flutter_service_worker.js`) i.p.v. handmatig sourcebestand in `web/`. Dat is functioneel correct, maar verdient expliciete noot in de todo-context om verwarring te voorkomen.

### Wat ik nog zou toevoegen

- Eventueel een korte verwijzing in README dat PWA offline support CI-gevalideerd is via Playwright-check.

### Wat ik nog zou verwijderen

- Geen directe verwijdering nodig.

---

## 075 - Release pipeline preparation

### Wat is correct geimplementeerd

- GitHub Releases + changelog via semantic-release zijn geconfigureerd (`.github/workflows/release.yml`, `.releaserc.json`).
- Fastlane lanes voor iOS/Android/desktop builds zijn aanwezig (`fastlane/Fastfile`).
- Distributieworkflow voor TestFlight internal + Play internal + desktop artifacts is aanwezig met preflight checks (`.github/workflows/fastlane.yml`).
- Uitgebreide release documentatie en hardening-checklist zijn aanwezig (`docs/release-pipeline.md`, `docs/release-hardening-checklist.md`).

### Wat ik nog zou wijzigen

- Een deel van acceptance is "setup" op platformniveau (TestFlight/Play internal), en dat blijft terecht als extern/manual stap gemarkeerd in docs; repo-only kan dit niet volledig bewijzen zonder live credentials/runs.

### Wat ik nog zou toevoegen

- Na eerste live run: evidence links (run IDs, release tag, store screenshots) toevoegen in docs voor audittrail.

### Wat ik nog zou verwijderen

- Geen directe verwijdering nodig.

---

## Samenvatting batch 071-075

- Volledig functioneel: TODO 071, TODO 072, TODO 074
- Functioneel met kleine uniformiteitsverbetering wenselijk: TODO 073
- Configuratief volledig in repo, operationeel deels afhankelijk van externe platform-setup: TODO 075
- Belangrijkste restwerk:
  - `project_created` analytics-callsite expliciet via `AnalyticsService` aligneren,
  - PWA service-worker generatie-context kort documenteren in todo/README,
  - release pipeline na eerste live distributierun voorzien van verifieerbare evidence links.

---

## Eindsamenvatting audit 001-075

- Geanalyseerd: 001-075
- Open op done_todo-auditniveau: geen resterende niet-geanalyseerde items.
- Globale conclusie: de meerderheid van done_todos is functioneel geimplementeerd; terugkerende verbeterpunten zitten vooral in:
  - documentatie-alignment na modularisatie,
  - uniformiteit in event/analytics en provider source-of-truth,
  - bewijsvoering voor operationele/externe setup-stappen (store distribution, handmatige validaties).
