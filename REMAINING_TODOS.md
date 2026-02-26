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
- TODO: Add filtering/sorting parameters via family provider
  - Verwachte actie: Maak `projectsProvider` of `filteredProjectsProvider` uitbreidbaar met parameters (status, zoekquery, sortering).
- TODO: Implement efficient single project fetch if repository supports it
  - Verwachte actie: Voeg `getProjectById` efficient implementatie toe aan `IProjectRepository` en concrete repositoryen.
- TODO: Add more filter parameters as needed
  - Verwachte actie: Breid `ProjectFilter` uit (date-range, priority, owner, tags).
- TODO: Add more filter conditions as needed
  - Verwachte actie: Breid filterimplementatie in `filteredProjectsProvider` uit.
- TODO: Add more filter fields (date range, priority, etc.)
  - Verwachte actie: Zie boven.
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
- TODO: Implement rate limiting (max 5 attempts per minute)
  - Verwachte actie: Concretiseer en implementeer limiet (backoff + captcha fallback).
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
- TODO: Add error handling/logging
  - Verwachte actie: Voeg try/catch + AppLogger.event/error melding toe bij IO/DB bewerkingen.
- TODO: Consider using an abstract interface for easy testing/swapping
  - Verwachte actie: Maak repository/interface voor dashboard data.

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

---

**Nieuwe TODO's (051-075)**

- **051. pubspec.yaml metadata & dependencies updaten (30 min)**  
  Verander name: my_project_management_app → project_management_app  
  Vervang de placeholder description: "A new Flutter project." door de volledige beschrijving uit README.md  
  Verander intl: any → intl: ^0.19.0 (of exacte versie uit l10n.yaml)  
  Voeg toe:YAMLhomepage: https://github.com/Steve-Mee/project-management-app  
  repository: "https://github.com/Steve-Mee/project-management-app"  
  Verwijder ongebruikte deps indien aanwezig (controleer met flutter pub deps --style=compact)  
  Run flutter pub get + commit

- **052. README.md volledig upgraden (1-1.5 uur)**  
  Voeg badges toe bovenaan: Flutter, Riverpod 2, Supabase, Sentry, MIT License, CI status (later)  
  Maak nieuwe sectie Screenshots met 8 afbeeldingen (dashboard light/dark, AI chat, Gantt, offline mode, mobile + desktop, deep link invite, export PDF/CSV)  
  Voeg sectie Architecture toe met Mermaid-diagram (core → features → providers → repositories → Supabase/Hive)  
  Maak table met alle documentatie-bestanden (00_START_HERE.md, DASHBOARD_GUIDE.md, IMPLEMENTATION_SUMMARY.md, etc.)  
  Update Features-lijst met alle huidige enterprise features  
  Voeg "Contributing" en "Roadmap" sectie toe

- **053. analysis_options.yaml strenger maken (20 min)**  
  Voeg include: package:flutter_lints/flutter.yaml of package:very_good_analysis toe  
  Activeer regels: prefer_const_constructors, prefer_const_declarations, avoid_print: false, use_key_in_widget_constructors: false  
  Run flutter analyze --no-fatal-infos en fix alle nieuwe warnings

- **054. Alle models migreren naar freezed + json_serializable (2-3 dagen)**  
  Voeg deps toe: freezed: ^2.5.0, freezed_annotation: ^2.4.0, json_annotation: ^4.9.0, build_runner: ^2.4.0  
  Vervang alle handmatige fromJson/toJson + Equatable door @freezed classes  
  Update Hive adapters (of migreer naar freezed + Hive generator)  
  Update alle repositories, providers en tests  
  Verwijder oude model-bestanden na validatie

- **055. Barrel files aanmaken voor providers (1 uur)**  
  Maak lib/core/providers/index.dart met alle exports  
  Maak per feature lib/features/xxx/providers/index.dart  
  Vervang alle lange imports door import 'package:.../providers.dart';  
  Doe hetzelfde voor models en repositories

- **056. GetWidget volledig verwijderen (2 uur)**  
  Vervang alle GetWidget, GetMaterialApp, GetBuilder etc. door pure MaterialApp + Riverpod + custom widgets  
  Update main.dart, themes en alle screens  
  Verwijder get: ^4.x uit pubspec

- **057. AiService abstractie maken (1.5 uur)**  
  Maak lib/core/services/ai/ai_service.dart (abstract class met Future<String> generate(...))  
  Implementeer OpenAiLangchainService erin  
  Update alle calls in AI chat, task suggestions, etc.  
  Maak makkelijk om later Gemini/Claude toe te voegen via feature flag

- **058. Firebase alleen voor FCM houden & documenteren (1 uur)**  
  Maak supabase_fcm_setup.md met exacte Edge Function + Supabase → FCM flow  
  Verwijder onnodige Firebase deps indien mogelijk (of laat staan als push-notificaties werken)

- **059. Test coverage + badge toevoegen (1 dag)**  
  Voeg flutter test --coverage toe aan CI  
  Upload naar Codecov of Coveralls  
  Voeg badge toe in README  
  Streef naar >85% coverage op core + repositories

- **060. Golden tests voor kritieke UI (1-2 dagen)**  
  Golden tests voor: DashboardCard, AiChatBubble, GanttChart, TaskListItem, Theme switcher  
  Voeg flutter_test golden configuratie toe

- **061. Volledige GitHub Actions CI/CD workflows (2 dagen)**  
  .github/workflows/flutter_test.yml (analyze, test, coverage, web build)  
  .github/workflows/flutter_desktop.yml (Windows/macOS/Linux build)  
  .github/workflows/semantic_pr.yml + release.yml (conventional commits)  
  Trigger op pull_request en push main

- **062. Hive encryptie implementeren voor gevoelige boxes (3 uur)**  
  Gebruik encrypt package + key uit FlutterSecureStorage  
  Maak EncryptedHiveBox wrapper  
  Encrypt: auth, settings, AI usage history, local tokens  
  Update HiveInitializer

- **063. supabase_setup.md + RLS policies documenteren (1 uur)**  
  Maak nieuw MD-bestand met alle SQL, RLS policies, storage buckets, Edge Functions  
  Inclusief "hoe nieuwe policy toevoegen" instructies

- **064. Infinite scroll toevoegen in ProjectsList & TasksList (4 uur)**  
  Gebruik Riverpod AsyncNotifier met pagination + scrollController  
  Voeg loading indicator + "einde bereikt" toe

- **065. App size analyse & optimalisatie (1 uur)**  
  Run flutter build apk --analyze-size --split-per-abi  
  Verwijder onnodige fonts/icons/assets  
  Documenteer resultaat in README

- **066. Offline indicator + sync status badge (2 uur)**  
  Globale widget boven AppBar (Connectivity + SyncService status)  
  Kleur: groen (synced), oranje (syncing), rood (offline)  
  Tap → toont laatste sync tijd + manual sync button

- **067. Onboarding flow voor nieuwe users (1 dag)**  
  Eerste launch: wizard (welcome → create first project → AI intro → invite team)  
  Gebruik shared_preferences + Riverpod flag

- **068. Toegankelijkheid (Accessibility) verbeteren (1 dag)**  
  Voeg Semantics labels toe op alle buttons, icons, lists  
  Verhoog contrast dark mode (controleer met Flutter Accessibility Inspector)  
  Test met TalkBack (Android) & VoiceOver (iOS) + web

- **069. Gantt chart upgraden of fork moderniseren (2-3 dagen)**  
  Vervang legacy_gantt_chart door gantt_chart of syncfusion_flutter_gantt (of fork + Material 3 update)  
  Zorg voor dark mode support en touch gestures

- **070. Modularisatie: core als apart package (3-4 dagen)**  
  Maak packages/pma_core met alle core providers, services, models, utils  
  Features blijven in main app maar importeren pma_core  
  Update go_router met deferred loading waar mogelijk

- **071. Feature flags via Supabase (2 uur)**  
  Maak FeatureFlagProvider die supabase.from('feature_flags').select() leest + cache  
  Gebruik in AI, Gantt, onboarding etc.

- **072. Globale ErrorBoundary widget + Sentry breadcrumbs (2 uur)**  
  ErrorBoundary wrapper rond hele app  
  Log alle errors + user actions als breadcrumbs

- **073. Analytics toevoegen (Supabase of Firebase) (3 uur)**  
  Track belangrijke events: project_created, task_completed, ai_used, invite_sent  
  Maak AnalyticsService abstract

- **074. PWA support voor web (1 dag)**  
  Voeg web/manifest.json + service worker toe  
  Test offline mode in Chrome

- **075. Release pipeline voorbereiden (2 dagen)**  
  GitHub Releases + changelog (semantic-release)  
  Fastlane voor iOS/Android + desktop builds  
  Interne TestFlight / Play Store internal testing setup
