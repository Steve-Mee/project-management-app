# Mirror Analyse (Diepgaand)

Datum: 2026-03-21
Scope: volledige Mirror-implementatie in Supabase, Edge Functions, gRPC runners, Flutter core/providers, UI en bestaande app-integratie.

### 1. Algemene beoordeling
- Sterke punten
  - De architectuurkeuze is sterk en consistent uitgevoerd: een thin gateway in `supabase/functions/mirror-gateway/index.ts`, compute gescheiden in runners (`server/mirror-cloud-runner`, `server/mirror-local-runner`) en een duidelijke contractlaag via `MirrorComputeBackend` in `lib/features/mirror/mirror_signed_inputs_backend.dart`.
  - Security is meerlaags ingericht en niet alleen client-side: permission checks (`has_permission('use_mirror')`), cloud-entitlement RPC, RLS op kern-tabellen, owner-scoped storage policies en auth guards in runners.
  - De apply-flow is volwassen: idempotency, structured errors, audit events (`mirror_apply_audit_events`), secure signed-input/backup artifacts en preview/apply consistency fingerprinting.
  - Offline-first is serieus geïmplementeerd: encrypted outbox (`mirror_outbox`), retry + replay met circuit breaker, draft caching en context budget guards.
  - Integratie met bestaande app is coherent: launch bridge via `openMirrorFromTask` in `lib/core/providers/ai_chat_provider.dart`, gebruik vanuit `project_detail_screen.dart` en `expandable_task_card.dart`, plus route guard in `mirror_route_guard_provider.dart`.
  - Testoppervlak is bovengemiddeld voor een nieuwe AI-feature: contracttests voor gateway/idempotency/RLS, widgettests en offline/replay tests.
- Zwakke punten
  - Orchestratie is functioneel sterk maar te verdeeld over meerdere services (`mirror_editor_orchestration_service.dart`, `mirror_orchestrator_service.dart`, execution paths, backend workflow helpers), wat onderhoud en onboarding lastiger maakt.
  - De gateway (`supabase/functions/mirror-gateway/index.ts`) is zeer uitgebreid geworden voor een thin-proxy rol; er zit relatief veel businesslogica in (idempotency, rate limiting, circuit breaker, metering, audit), wat blast radius vergroot.
  - Er zit nog technische overlap in verantwoordelijkheden: patch-building/persisting gebeurt op meerdere lagen (backend workflows + editor orchestration), waardoor regressies rond preview/apply moeilijker traceerbaar worden.
  - De gebruikerservaring van voice->code is nog risicovol: transcript kan in de huidige flow relatief direct in editor-context terechtkomen; dit vraagt sterkere guardrails voor production UX.
  - Sommige maintainability-patronen zijn half-hybride: zowel provider-driven dependency injection als singleton fallback (`Supabase.instance.client`) worden gebruikt.
  - Operationele hardening is grotendeels aanwezig, maar de observability-taxonomie (zelfde event voor compile/apply latency) kan strakker om productie-debugging te versnellen.
- Overall score (1-10)
  - 8.6/10

### 2. Laag-voor-laag analyse
- Supabase / Database laag
  - Sterk
    - Migrations zijn volwassen en iteratief verbeterd: idempotency baseline (`20260310_mirror_request_idempotency.sql`), status alignment (`20260311_mirror_idempotency_status_alignment.sql`), expires_at alignment + response cache (`20260317_mirror_request_idempotency_expires_at_alignment.sql`).
    - Storage hardening is correct ingericht in `20260308_mirror_storage_hardening.sql`: private buckets, owner-folder guard via `storage.foldername(name)[1] = auth.uid()::text`, lifecycle cleanup functie.
    - Audit + usage metering zijn netjes gescheiden: `mirror_apply_audit_events` en `mirror_usage_logs` met RLS, indexering en retention hooks.
    - Realtime scope is verbeterd via topic-based broadcast in `20260309_mirror_ai_sessions_broadcast_topics.sql`.
    - Template-catalogus is DB-first gemaakt met seed-sync (`20260309_mirror_templates_rls_and_sync.sql`), wat beheerbaarheid vergroot.
  - Zwak/risico
    - `project_id` en `task_id` in meerdere mirror-tabellen zijn `TEXT` zonder FK; dit is flexibel maar laat data-drift toe als projecten/taken verwijderd of hernoemd worden.
    - Idempotency/usage/audit tabellen zullen op termijn groot worden; retention bestaat, maar query- en indexstrategie moet periodiek herzien worden op werkelijke trafficprofielen.
    - Template-seeding in SQL is praktisch, maar versiebeheer van seed-content in pure SQL wordt snel moeilijk leesbaar bij grotere templategroei.

- Edge Functions & gRPC backend laag
  - Sterk
    - `supabase/functions/mirror-gateway/index.ts` heeft een volwassen foutmodel: typed error families, request/trace/idempotency propagation, timeout handling, circuit breaker gedrag en replay-safe response caching.
    - Auth flow is degelijk: bearer-check, `supabase.auth.getUser()`, permission gate (`use_mirror`) en cloud entitlement gate (`has_cloud_mirror_access`).
    - Runner-architectuur is goed schaalbaar: gedeelde proto/runner-service (`server/mirror-shared`), specifieke cloud/local bootstrap, quota controls en workspace cleanup scheduler.
    - Auth guard in cloud/local runners dwingt token/JWT-validatie af en voorkomt unauthenticated compute.
  - Zwak/risico
    - De gateway combineert veel concerns in een single functionbestand; bij toekomstige changes is regressierisico hoog zonder verdere modulairisering.
    - HTTP<->gRPC contracten zijn functioneel consistent, maar er is nog geen centrale schema-validatie op payload-niveau (bijvoorbeeld zod/io-ts equivalent) in de edge function.
    - Sommige numerieke limieten zijn env-gedreven maar zonder expliciete runtime health endpoint of config dump voor ops-validatie in productie.

- Dart/Flutter core & providers laag
  - Sterk
    - Entitlementrouting is helder via `mirror_entitlement_provider.dart` en `MirrorAccessPolicy` (`packages/pma_core/lib/services/mirror_access_policy.dart`).
    - Session state model (`mirror_session_provider.dart`) houdt context/version/fingerprint/server token bij, wat preview/apply integrity ondersteunt.
    - Feature flags en route guard zijn expliciet en testbaar (`mirror_feature_flag_provider.dart`, `mirror_route_guard_provider.dart`).
    - Backendkeuze (cloud gateway vs private gRPC) is coherent en afgedwongen via policybeslissing.
  - Zwak/risico
    - De mix van `Notifier`, `FutureProvider`, singleton fallback en side-effectful hydration maakt lifecycle-gedrag complex bij race conditions (startup/auth switch/offline).
    - `mirror_provider.dart` fungeert deels als compat/shim laag; dit is bruikbaar op korte termijn maar verhoogt indirectie op lange termijn.
    - De backend-interface (`MirrorComputeBackend`) draagt naast pure transport ook workflow concerns via services, wat strikte clean architecture grenzen vervaagt.

- UI & UX laag (editor, dialogs, realtime)
  - Sterk
    - `mirror_editor_screen.dart` is compleet en production-minded: run state locks, retry feedback, terminal/live output, template gallery, realtime controller en permission revocation handling.
    - `apply_dialog.dart` ondersteunt risicobewuste keuzes (accept-risk + branch suggestie + diff), wat belangrijk is voor AI-gegenereerde patches.
    - `MirrorRealtimeService` heeft robuuste guards tegen spam/oversized payloads/dubbele events.
    - Monaco web host (`monaco_editor_host_web.dart`) bevat origin-checks voor `postMessage`, wat essentieel is voor web security.
  - Zwak/risico
    - UX rond voice input kan veiliger en duidelijker richting "draft first, explicit insert later" op alle platformen.
    - Bij complexe multi-file changes blijft de visuele review in de editor-flow relatief lineair; voor grotere patches ontbreekt nog een echte staged review-ervaring.

- Security, permissions & premium checks
  - Sterk
    - Security is niet afhankelijk van client claims: gateway en DB afdwingen de echte autorisatie.
    - `mirror_admin_testing_bypass` is gekoppeld aan admin-permissions, niet aan gewone gebruikers.
    - Secure apply artifacts gebruiken owner-scoped object paths en korte signed URL TTL.
    - Productieguard tegen insecure private gRPC transport is correct aanwezig in `private_grpc_backend.dart`.
  - Zwak/risico
    - Omdat bypass/experiments via flags lopen, is operationele governance (wie mag togglen, audit trail op toggles) cruciaal buiten code.
    - Logging bevat veel request-context; redaction discipline moet blijvend bewaakt worden bij toekomstige uitbreidingen.

- Offline / Hive / caching laag
  - Sterk
    - Outbox replay (`mirror_outbox_replay_service.dart`) is zeer goed uitgewerkt: retry/backoff/jitter, timeout, circuit breaker, persistence en reconnect-triggered replay.
    - Draft cache (`mirror_draft_cache_service.dart`) heeft harde caps op sessies/files/chars en beschermt zo tegen lokale opslagexplosie.
    - Offline cache invalidatie op auth/premium wijzigingen is aanwezig in `mirror_offline_cache_provider.dart`.
    - Templates cache combineert memory + persistent + TTL + hash validation.
  - Zwak/risico
    - Caches zijn bewust pragmatisch, maar meerdere lokale cachelagen maken invalidatiecomplexiteit hoger bij edge-cases.
    - `unawaited` flush op app lifecycle events kan in uitzonderlijke crash-scenario's nog data verliezen.

- Integratie met bestaande app
  - Sterk
    - Deep-link/route pad is aanwezig en gekoppeld aan guard: `AppRoutes.mirrorEditor`, `mirrorEditorPath`, route builder met `mirrorRouteGuardProvider` in `lib/core/routes.dart`.
    - Integratie vanuit bestaande task/project UI is netjes en consistent (`project_detail_screen.dart`, `expandable_task_card.dart`).
    - Startup initializer houdt rekening met mirror-intents (`lib/core/projects_initializer.dart`) zonder de rest van de appflow te breken.
  - Zwak/risico
    - Er zijn meerdere toegangspaden naar Mirror (router, AI bridge, deep link), wat consistent gedrag sterk afhankelijk maakt van gedeelde guards en policies.
    - Legacy/compat lagen uit eerdere iteraties zijn nog zichtbaar en kunnen op termijn consolidatie gebruiken.

### 3. Concrete aanbevelingen
- Wijzigingen (met exacte bestandsnamen en wat te veranderen)
  - `supabase/functions/mirror-gateway/index.ts`
    - Splits op in modules (auth, idempotency, rate-limit, circuit-breaker, forwarding, metering) om blast radius te verkleinen en testbaarheid te verhogen.
    - Introduceer expliciete input-schema validatie (bijvoorbeeld compacte runtime validator) voor request body voordat normalization start.
    - Maak telemetry-events operationeel eenduidiger met aparte eventnamen voor compile/apply latency.
  - `lib/features/mirror/services/mirror_editor_orchestration_service.dart`
    - Verplaats preview/apply metadata- en patchbeslissingen naar dedicated domain services zodat deze class puur run-coordination blijft.
    - Normaliseer alle "first non empty" foutpaden naar een gedeelde error-mapper voor consistente UX.
  - `lib/features/mirror/services/mirror_orchestrator_service.dart`
    - Vereenvoudig door interactive path en replay path scherper te scheiden in API en status-events.
  - `lib/features/mirror/mirror_gateway_backend.dart`
    - Isoleer fingerprint + consistency checks in een aparte validator service om backend-transportcode smaller te maken.
  - `lib/features/mirror/widgets/mirror_voice_prompt_bar.dart`
    - Maak de veilige draft-flow explicieter in alle states (ook bij errors): nooit directe code mutatie zonder expliciete bevestiging.
  - `lib/features/mirror/providers/mirror_templates_provider.dart`
    - Maak cache invalidatie expliciet triggerbaar vanuit admin/template-management flows zodat stale template windows kleiner worden.
  - `lib/core/providers/mirror_session_provider.dart`
    - Breng draft persist/flush lifecycle naar een expliciet save-commit model op kritieke acties (run/apply/leave) naast debounce.
  - `server/mirror-shared/lib/http_gateway.dart`
    - Voeg uniform request-size + schema guard logging toe met consistente structured error keys gelijk aan edge gateway.
  - `server/mirror-shared/lib/runner_service.dart`
    - Voeg health/readiness metric hooks toe voor ops (bijv. queue/latency/auth deny counters) zodat Fly/local monitoring consistent is.
  - `lib/core/providers/ai_chat_provider.dart`
    - Beperk deze bridge tot launch-intent contract en verplaats mode/policy mutaties naar een centrale launch coordinator om duplicaatlogica te voorkomen.

- Toevoegingen (nieuwe bestanden/features met korte beschrijving)
  - `lib/features/mirror/services/mirror_gateway_request_schema.dart`
    - Centrale schema/normalization laag voor compile/apply payloads, herbruikbaar in tests.
  - `supabase/functions/mirror-gateway/modules/*`
    - Modulair function design (auth.ts, idempotency.ts, ratelimit.ts, circuit_breaker.ts, forward.ts, telemetry.ts).
  - `test/features/mirror/mirror_gateway_schema_validation_test.dart`
    - Contracttests voor payload-validatie en foutclassificatie.
  - `test/features/mirror/mirror_apply_audit_roundtrip_test.dart`
    - End-to-end audit event consistency test (started/completed/failed met fingerprintvelden).
  - `docs/mirror_operational_runbook.md`
    - Productie-runbook met env vars, SLO's, alerting, incident responses en key rotation procedures.
  - `docs/mirror_threat_model.md`
    - Formele threat model voor prompt-injectie, artifact leakage, signed URL abuse en privilege escalation.
  - `lib/features/mirror/widgets/mirror_patch_review_sheet.dart`
    - Uitgebreide multi-file patch review UI met staged apply/skip.
  - `lib/features/mirror/services/mirror_launch_coordinator.dart`
    - Uniforme ingang voor route/deeplink/AI launch met gecentraliseerde guard sequencing.

- Verwijderingen (wat weg kan en waarom)
  - `lib/core/providers/mirror_provider.dart`
    - Gefaseerd verwijderen zodra compat-export niet meer nodig is; vermindert indirectie en dubbel statebeheer.
  - Overlap tussen orchestration-lagen (`mirror_editor_orchestration_service.dart` en delen van `mirror_orchestrator_service.dart`)
    - Consolidatie reduceert duplicaatlogica en maakt incident-debugging eenvoudiger.
  - Ongebruikte of dubbele observability-paden in mirror-services
    - Vermindert event-ruis en helpt bij scherpere production dashboards.
  - Legacy fallback-branches die behavior dupliceren zonder unieke waarde
    - Verlaagt onderhoudslast en verkleint kans op inconsistent gedrag tussen cloud/private/offline paden.