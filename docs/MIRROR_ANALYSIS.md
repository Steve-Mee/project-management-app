# Mirror Analyse (Diepgaand)

Datum: 2026-03-21
Scope: volledige Mirror-implementatie in Supabase, Edge Function, gRPC runners, Flutter core/providers, UI, permissies en offline/caching.

### 1. Algemene beoordeling
- Sterke punten
  - Architectuurkeuze is inhoudelijk sterk: een dunne gateway in `supabase/functions/mirror-gateway/index.ts`, compute buiten Supabase (cloud/local runner), en een duidelijke backend-abstractie (`MirrorComputeBackend`) in `lib/features/mirror/mirror_signed_inputs_backend.dart`.
  - Security-by-design is zichtbaar op meerdere lagen: RLS op `ai_sessions`, `mirror_request_idempotency`, `mirror_apply_audit_events`, `mirror_usage_logs` en storage-buckets; client-side feature/permission gating; server-side permission checks (`has_permission('use_mirror')`) en cloud entitlement RPC.
  - Offline-first implementatie is bovengemiddeld volwassen: drafts, encrypted outbox, replay met circuit breaker, budget-enforcement en fallback-caches zijn concreet aanwezig.
  - Apply-flow is professioneel opgezet met preview/apply consistency checks (fingerprints), signed-input + backup artifacts, audit events en idempotency.
  - Integratie in bestaande project/task flows is netjes en laag-invasief via `openMirrorFromTask` in zowel projectdetail als taskcard.
  - Er is al substantiele testdekking rondom Mirror-contracten, idempotency, realtime guards, permission guards en editor/apply flows.
- Zwakke punten
  - Verantwoordelijkheden zijn te versnipperd over `mirror_editor_run_service.dart`, `mirror_editor_orchestration_service.dart`, `mirror_orchestrator_service.dart` en backend-extensions; dit verhoogt cognitieve load en regressierisico.
  - De per-user rate limiter in de gateway telt op basis van `created_at` in de idempotency tabel zonder verfijning op relevante status/expiry, wat op schaal zowel false positives als oneerlijke throttling kan geven.
  - Idempotency cleanup is wel geimplementeerd als SQL-functie, maar niet gepland via `pg_cron` zoals storage/retention cleanup; operationeel is dat nog niet af.
  - UI-kwaliteit is niet overal consistent met een premium coding studio: desktop fallback naar plain `TextField` en voice input die direct code append maakt de editor fragiel.
  - Dependency injection is niet consequent: meerdere Mirror-onderdelen vallen terug op directe `Supabase.instance.client`, wat testbaarheid en uniformiteit verlaagt.
  - Routing/deeplink architectuur is half af: `projects_initializer.dart` detecteert mirror-route intent, maar `routes.dart` heeft geen expliciete Mirror route.
- Overall score (1-10)
  - 8.3/10

### 2. Laag-voor-laag analyse
- Supabase / Database laag
  - Positief:
    - `supabase/migrations/20260310_create_ai_sessions_baseline.sql` is robuust: schema, constraints, `updated_at` trigger, indexen en owner-only RLS in een canonical policy.
    - Idempotency evolutie is goed (`20260310`, `20260311`, `20260317`): status-contract, `expires_at` alignment en response cache kolommen zijn netjes doorontwikkeld.
    - Storage-hardening in `20260308_mirror_storage_hardening.sql` is sterk: private buckets, owner-prefix policy en lifecycle cleanup.
    - `mirror_templates` tabel + RLS + sync functie is production-minded en beter onderhoudbaar dan hardcoded templates.
    - `mirror_usage_logs` en `mirror_apply_audit_events` bieden goede audit/billing basis.
  - Risico's:
    - Geen geplande `pg_cron` voor `cleanup_mirror_request_idempotency_expired()`; tabelgroei en oude claims kunnen oplopen.
    - Gateway rate-limiter queryt op `created_at` zonder filtering op status/expiry; dat past functioneel, maar niet optimaal voor replay-heavy workloads.
    - `project_id`/`task_id` zijn `TEXT` zonder FK. Dat is flexibel, maar bewaakt referentiele integriteit niet in DB-laag.

- Edge Functions & gRPC backend laag
  - Positief:
    - `supabase/functions/mirror-gateway/index.ts` is inhoudelijk correct als thin proxy: auth, permission checks, idempotency, structured errors, forwarding en usage logging.
    - Structured errors zijn consequent en client-vriendelijk (`code`, `retryable`, `error_family`, `requestId`, `traceId`, `stage`).
    - Stale-processing recovery in idempotency claim flow voorkomt vastlopende keys.
    - Runner stack (`server/mirror-shared`, `mirror-cloud-runner`, `mirror-local-runner`) heeft duidelijke quota, workspace cleanup en auth guard.
    - `PrivateGrpcBackend` blokkeert insecure transport in productie/runtime-product.
  - Risico's:
    - gRPC codegen lifecycle is niet expliciet vastgelegd in tooling/CI; drift tussen `proto` en generated clients blijft mogelijk.
    - Gateway-rate limit is request-count based zonder gewichten naar actie/latency/backend-status.
    - Geen expliciete circuit-breaker op gateway -> upstream HTTP forward pad (wel retries/timeouts aan client/runtime kanten).

- Dart/Flutter core & providers laag
  - Positief:
    - Entitlementbeleid is expliciet gemodelleerd in `mirror_entitlement_provider.dart` met `MirrorAccessPolicy`.
    - `mirror_session_provider.dart` bouwt contextfiles uit project/task state en houdt compile fingerprints bij voor apply-integriteit.
    - `mirror_offline_cache_provider.dart` heeft schema-versioning en invalidatie op auth/premium verandering.
    - `mirror_premium_service.dart` documenteert expliciet dat premium client-side niet-authoritative is.
  - Risico's:
    - Te veel lagen met deels overlappende orchestration-verantwoordelijkheid.
    - `mirror_provider.dart` is vooral compatibility exportlaag; beperkte blijvende waarde.
    - Directe singleton client access in templates/secure-apply/gateway backend verbreekt provider-consistentie.
    - `MirrorComputeBackend` extensions bevatten veel cross-cutting concerns (patching, secure apply, prompt building, audit persistence), waardoor abstractie te breed wordt.

- UI & UX laag (editor, dialogs, realtime)
  - Positief:
    - `mirror_editor_screen.dart` bevat complete flow: mode, explorer, editor, terminal, realtime output, templates en apply-confirmatie.
    - `apply_dialog.dart` heeft diff preview, risk acknowledgement en branch-advies; dit is passend voor AI-gegenereerde codewijzigingen.
    - Realtime services hebben payload-guards, dedup en debounce.
    - Permission revocation tijdens actieve sessie wordt correct afgehandeld.
  - Risico's:
    - Voice input schrijft direct naar actieve codefile (`_toggleVoiceInput`); grote kans op ongewenste code-mutaties.
    - Desktop editor fallback (`monaco_editor_host_io.dart`) degradeert stil naar plain `TextField`; productgevoel en veiligheid van editflow dalen sterk.
    - Multi-file preview/apply review is nog beperkt in diepgang voor complexere patches.

- Security, permissions & premium checks
  - Positief:
    - Multi-layer security is aanwezig en correct verdeeld: client UX-gates, server authorization, RLS en object-owner policies.
    - Auth guard in cloud/local runner valideert service token en JWT claims (alg, signature, exp/nbf, issuer/audience).
    - Secure apply artifacts hebben korte TTL (300s default) en owner-scoped paden.
    - Encryption fail-closed toggles bestaan voor offline cache/outbox/audit.
  - Risico's:
    - `mirror_admin_testing_bypass` blijft een gevoelig feature-flag pad en moet strikt operationeel beheerd worden.
    - Signed URL TTL is redelijk, maar voor high-risk omgevingen kan korter (bijv. 60-120s) + striktere log-redaction wenselijk zijn.

- Offline / Hive / caching laag
  - Positief:
    - Outbox replay is sterk ontworpen: idempotency, retry policy, deferred replay, circuit breaker, operation timeouts.
    - Draft cache limieten voorkomen runaway state (max sessies, max files, max chars).
    - Template cache heeft memory + persistent snapshot + network fallback.
  - Risico's:
    - Draft flush in `dispose` gebruikt `unawaited`, dus laatste mutatie kan verloren gaan bij harde afsluiting.
    - `_MirrorTemplatesMemoryCache.snapshot` is globale state buiten Riverpod-lifecycle.
    - Evictie in draft cache is oudste-first op `savedAt` (praktisch), maar niet expliciet gedocumenteerd als gekozen beleid.

- Integratie met bestaande app
  - Positief:
    - Integratie vanuit projectdetail en taskcard is consistent en hergebruikt `openMirrorFromTask`.
    - Mirror is toegevoegd zonder grootschalige verstoring van bestaande project/task architectuur.
  - Risico's:
    - `projects_initializer.dart` behandelt mirror deeplink intent, maar `routes.dart` bevat geen first-class mirror route.
    - `ref.read(aiChatProvider);` in `ai_chat_provider.dart` lijkt een no-op/legacy side effect.
    - Benamingen in implementatie wijken deels af van de aangeleverde context (bijv. `mirror-gateway` in plaats van `mirror_compute`; `MirrorGatewayBackend` in plaats van `CloudFlyBackend`). Functioneel niet fout, maar kan documentatie/ops verwarren als termen door elkaar lopen.

### 3. Concrete aanbevelingen
- Wijzigingen (met exacte bestandsnamen en wat te veranderen)
  - `supabase/functions/mirror-gateway/index.ts`
    - Verfijn `checkPerUserRateLimit()` zodat tellers niet alleen op `created_at` draaien, maar ook op relevante status en `expires_at`.
    - Voeg gestructureerde observability toe voor throttle-beslissingen en upstream timeout/failure classificatie.
  - `supabase/migrations/20260310_mirror_request_idempotency.sql`
    - Laat cleanupfunctie staan, maar plan die via een nieuwe migratie met `pg_cron` (zoals storage cleanup).
  - `lib/features/mirror/mirror_editor_screen.dart`
    - Verplaats speech-to-text output naar prompt/assistant input i.p.v. directe codefile append.
    - Voeg expliciete "insert into code" actie toe voor gecontroleerde overname.
  - `lib/features/mirror/widgets/monaco_editor_host_io.dart`
    - Vervang stille fallback door expliciete degraded-state UI met waarschuwing en herstelactie.
  - `lib/core/routes.dart`
    - Voeg first-class Mirror route(s) toe en verbind met deeplink intent uit `lib/core/projects_initializer.dart`.
  - `lib/core/providers/ai_chat_provider.dart`
    - Verwijder of documenteer `ref.read(aiChatProvider);` wanneer er geen bewust side effect nodig is.
  - `lib/features/mirror/mirror_signed_inputs_backend.dart`
    - Splits backend extensions op in aparte services om interfacebreedte en coupling te verlagen.
  - `lib/features/mirror/providers/mirror_templates_provider.dart`
    - Injecteer `SupabaseClient` via provider i.p.v. directe singleton lookup.
  - `lib/features/mirror/services/mirror_editor_orchestration_service.dart`
    - Beperk verantwoordelijkheden tot orchestration; verplaats diff/patch metadata handling naar dedicated services.
  - `lib/features/mirror/services/mirror_orchestrator_service.dart`
    - Maak expliciete scheiding tussen interactive run path en outbox replay path om gedrag voorspelbaarder te maken.

- Toevoegingen (nieuwe bestanden/features met korte beschrijving)
  - `supabase/migrations/20260322_mirror_request_idempotency_cron.sql`
    - Schedule voor periodieke idempotency cleanup (`cleanup_mirror_request_idempotency_expired`).
  - `tool/generate_mirror_grpc.ps1`
    - Reproduceerbare codegen script voor `lib/features/mirror/grpc_generated/*` vanaf `server/mirror-shared/proto/mirror.proto`.
  - `.github/workflows/mirror-grpc-contract.yml`
    - CI-check die failt als generated gRPC files niet overeenkomen met proto.
  - `lib/features/mirror/widgets/mirror_voice_prompt_bar.dart`
    - Dedicated voice UX voor prompt-invoer met expliciete "apply to editor" stap.
  - `lib/features/mirror/providers/mirror_route_guard_provider.dart`
    - Centrale route/deeplink guard met feature-flag + permission + entitlement checks.
  - `test/features/mirror/mirror_route_guard_test.dart`
    - Testen voor deeplink-routing inclusief denied/disabled/fallback gevallen.
  - `test/features/mirror/mirror_templates_provider_test.dart`
    - Testmatrix voor memory/persistent/network cache en version mismatch scenario's.

- Verwijderingen (wat weg kan en waarom)
  - `lib/core/providers/mirror_provider.dart`
    - Kan weg zodra imports naar concrete providers wijzen; verlaagt indirection zonder functioneel verlies.
  - `ref.read(aiChatProvider);` in `lib/core/providers/ai_chat_provider.dart`
    - Verwijderbaar als er geen bewust side effect meer bestaat; reduceert ruis en ambiguiteit.
  - Overlap tussen `lib/features/mirror/services/mirror_editor_run_service.dart` en `lib/features/mirror/services/mirror_editor_orchestration_service.dart`
    - Consolidatie reduceert dubbel gedrag in budget/preflight/run paden.
  - Overmatige cross-cutting extensions op `MirrorComputeBackend` in `lib/features/mirror/mirror_signed_inputs_backend.dart`
    - Refactor naar losse services; houdt backend-interface klein en stabiel.