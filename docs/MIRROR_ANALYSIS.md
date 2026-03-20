# Mirror Implementatie - Diepgaande Architectuuranalyse

Analyse datum: 20 maart 2026

### 1. Algemene beoordeling
- Sterke punten
   - De implementatie is functioneel compleet en volwassen over meerdere lagen: database, edge gateway, private/cloud runners, Riverpod state, editor UX, realtime en offline replay.
   - Security-by-default is op veel plekken zichtbaar: owner-scoped RLS op kern-tabellen, route-level auth in de gateway, `use_mirror` permission checks op client en server, en extra cloud entitlement gate voor cloud mode.
   - Offline-first is sterk uitgewerkt: draft cache, outbox met retry/jitter/circuit breaker, cache-restore van varianten en context-budgeting om payloads beheersbaar te houden.
   - De apply-flow bevat goede veiligheidsrails: preview/apply fingerprint checks, context-fingerprint checks, signed input + backup artifacts, audit logging en idempotency caching.
   - Integratie met bestaande project/task flows is consistent en direct bruikbaar via `openMirrorFromTask` en navigatie naar de editor vanuit task- en projectcontext.
   - Testdekking voor Mirror is bovengemiddeld breed met Dart tests plus SQL contracttests voor RLS/idempotency.
- Zwakke punten
   - Architecturale fragmentatie in naming en contracten: in de context noem je `EdgeFunctionBackend`, `CloudFlyBackend`, `mirror_staging` en `mirror_compute`, maar in code staan feitelijk `MirrorGatewayBackend`, `PrivateGrpcBackend`, `mirror-gateway` en buckets `mirror-signed-inputs` / `mirror-backups`.
   - De gateway gebruikt FNV-1a 32-bit voor idempotency request-hashing; dat is snel maar collision-gevoeliger dan nodig voor een security-kritische dedupe-laag.
   - `mirror_provider.dart` combineert policy, entitlement, AB-varianten, cache-hydratie en backend-selectie in een grote orchestrator; onderhoudbaarheid en regressierisico nemen daardoor toe.
   - Productie-entitlement leunt in client op metadata/subscriptions hinting; server is wel autoritatief, maar UX-gedrag en mode-switching kunnen tijdelijk inconsistent aanvoelen.
   - Runner sandboxing is vooral pad-/bestandstype-gericht; process-isolatie en network egress controls zitten vooral buiten appcode (container/platform), wat extra ops-discipline vereist.
   - Usage metering is gemigreerd (`mirror_usage_logs`), maar wordt in de huidige gatewayflow niet zichtbaar gevuld, waardoor observability/billing-data incompleet kan zijn.
- Overall score (1-10)
   - 8.7/10

### 2. Laag-voor-laag analyse
- Supabase / Database laag
   - `supabase/migrations/20260310_create_ai_sessions_baseline.sql` is degelijk: constraints, update trigger, owner-policy en relevante indexen.
   - `supabase/migrations/20260308_mirror_storage_hardening.sql` is sterk: private buckets met owner-folder RLS en lifecycle cleanupfunctie.
   - `supabase/migrations/20260309_mirror_templates_rls_and_sync.sql` laat een volwassen DB-first templatecatalogus zien met `seed_managed` governance en beheerdersrechten.
   - Idempotency-migraties (`20260310`, `20260311`, `20260317`) laten goede contract-hardening zien (status alignment, expires_at alignment, response cache kolommen).
   - Realtime topic-scoping (`20260309_mirror_ai_sessions_broadcast_topics.sql`) beperkt broadcast selectief per user/project/task, wat goed past bij least-privilege.
   - Kritisch aandachtspunt: de gateway verwacht RPC `has_cloud_mirror_access`, maar een bijbehorende migration/DDL hiervoor staat niet zichtbaar in de repo; dit is een deployment-risico.

- Edge Functions & gRPC backend laag
   - `supabase/functions/mirror-gateway/index.ts` is inhoudelijk sterk: auth, permission checks, cloud entitlement check, payload caps, idempotency claims/replay/finalize, gestructureerde fouten en request tracing.
   - Stale-processing handling is verbeterd met fallback op `updated_at`/`created_at`; dit is een volwassen herstelpad voor half-afgebroken requests.
   - `server/mirror-shared/lib/http_gateway.dart` en `runner_service.dart` hebben quota, timeout en auth-through metadata forwarding; goed als thin gateway patroon.
   - `private_grpc_backend.dart` blokkeert insecure transport in productie-runtime, wat belangrijk is voor hardening.
   - Risico 1: idempotency request hash gebruikt `fnv1a32`; collision-kans is niet nul in multitenant/hoog-volume scenario’s.
   - Risico 2: in `http_gateway.dart` vertaalt `_grpcToHttpStatus` `permissionDenied` naar 401 i.p.v. 403, wat semantisch en operationeel minder correct is.
   - Risico 3: edge gateway doet meerdere DB-calls per request (permission, entitlement, idempotency, rate-limit, audit), wat onder load schaalbaarheid en p95 latency kan drukken.

- Dart/Flutter core & providers laag
   - `mirror_provider.dart` + `MirrorAccessPolicy` implementeren mode-resolutie met premium, runner variant en admin bypass op een nette, expliciete manier.
   - `mirror_session_provider.dart` bouwt contextbestanden slim op uit project/tasks en ondersteunt draft-merge plus fingerprinting.
   - `mirror_editor_orchestration_service.dart` heeft een correcte generate-compile-preview-apply keten met user confirmation en metadata-overdracht.
   - `mirror_premium_service.dart` is goed gedocumenteerd als non-authoritative hint en bevat TTL/jitter/in-flight dedupe.
   - Zwak punt: duplicaat-achtige providerdefinitie (`mirror_entitlement_provider.dart`) en brede verantwoordelijkheden in providerlaag maken grens tussen policy en orchestration diffuus.
   - Zwak punt: defaultgedrag voor `mirror_enabled` blijft fail-open buiten strict production mode; handig voor DX, maar rollout-control is minder strak.

- UI & UX laag (editor, dialogs, realtime)
   - `mirror_editor_screen.dart` biedt complete editorflow (Monaco, file explorer, terminal, realtime, templates, voice) met permission revoke handling tijdens sessie.
   - Realtimecontroller/services bevatten dedupe, truncation caps en debounce; dit voorkomt UI-overbelasting en memory drift.
   - `apply_dialog.dart` gebruikt nu een betere unified diff-benadering via `mirror_diff_service` en expliciete risk acknowledgment.
   - Responsiveness is redelijk opgezet met compact/non-compact layout split.
   - Verbeterpunt: `mirror_editor_screen.dart` is erg groot en bevat veel mixed concerns (state wiring, UI layout, IO side-effects), wat testbaarheid en refactoring-last verhoogt.

- Security, permissions & premium checks
   - Positief:
      - Permission guard aanwezig op launch, scherm en backend.
      - Cloud mode heeft extra server-side entitlement check.
      - Secure apply artifacts worden owner-scoped opgeslagen met korte signed URL TTL.
      - Outbox/draft/offline caches proberen encrypted Hive te gebruiken met fail-closed toggles in productie.
   - Aandachtspunt:
      - Security-contracten zijn sterk, maar sommige governance-functies (zoals cloud-entitlement RPC-definitie) lijken buiten deze codebase te leven; zonder infra-checks is dat fragiel.
      - Runner compileert/verwerkt user-inhoud; zonder harde runtime sandbox policies op containerniveau blijft dit een potentieel abusevlak.

- Offline / Hive / caching laag
   - Outbox-architectuur in `mirror_outbox_replay_service.dart` is robuust (encryptie, idempotency keys, retries, replay scheduler, circuit breaker, connectivity hooks).
   - `mirror_offline_cache_provider.dart` bevat schema versioning + TTL envelopes + invalidatie op auth/premium wijziging; sterk voor cachehygiëne.
   - `mirror_templates_cache.dart` heeft hash-validatie en schema-checks, waardoor corrupte cache netjes wordt verworpen.
   - Verbeterpunt: meerdere parallelle cachelagen (memory + Hive + provider state) vragen expliciete invalidatie- en ownershipdocumentatie om edge-case staleness te beperken.

- Integratie met bestaande app
   - Integratiepunten zijn goed gelegd in `ai_chat_provider.dart`, `project_detail_screen.dart` en `expandable_task_card.dart`.
   - Startup gating in `projects_initializer.dart` voorkomt toegang bij ontbrekende permission of uitgeschakelde feature-flag.
   - Post-apply cache refresh van tasks/subtasks helpt consistency met bestaande projectschermen.
   - Consistentierisico: context/README noemt onderdelen die niet exact matchen met huidige implementatienamen; dat vergroot overdrachtsfouten tussen teamleden.

### 3. Concrete aanbevelingen
- Wijzigingen (met exacte bestandsnamen en wat te veranderen)
   - `supabase/functions/mirror-gateway/index.ts`: vervang `fingerprintValueFnv1a32` in idempotency request hashing door SHA-256 (bijv. via `crypto.subtle.digest`) voor collision-robuustheid.
   - `server/mirror-shared/lib/http_gateway.dart`: wijzig `_grpcToHttpStatus` mapping voor `StatusCode.permissionDenied` van 401 naar 403.
   - `lib/core/providers/mirror_provider.dart`: split in minimaal drie delen: mode policy resolver, entitlement/feature-flag resolver en offline-state hydrator.
   - `lib/features/mirror/mirror_editor_screen.dart`: verplaats runtime side-effects (voice/realtime/run orchestration wiring) naar controller/service + kleinere presentatie-widgets.
   - `lib/core/providers/mirror_feature_flag_provider.dart`: overweeg expliciete runtime-config voor fail-open/fail-closed gedrag per environment, met productie-default fail-closed voor premium AI-features.
   - `lib/core/services/mirror_premium_service.dart`: maak UX-state explicieter door een tri-state (`unknown/free/premium`) zodat tijdelijke metadata/subscription onzekerheid niet als harde free-state voelt.
   - `lib/features/mirror/services/mirror_secure_apply_service.dart`: harmoniseer lokale audit met server audit door gedeeld event-model en sync-policy te definiëren (bijv. server-authoritative + lokale buffer).
   - `supabase/functions/mirror-gateway/index.ts`: voeg write-pad naar `mirror_usage_logs` toe (compile/apply, status, duration, requestId, idempotencyKey) om metering migratie daadwerkelijk te benutten.

- Toevoegingen (nieuwe bestanden/features met korte beschrijving)
   - `supabase/migrations/20260320_mirror_cloud_entitlement_rpc.sql`: expliciete definitie van `has_cloud_mirror_access()` met tests, zodat gateway dependency niet impliciet blijft.
   - `test/features/mirror/mirror_gateway_hash_collision_guard_test.dart`: contracttest dat idempotency hash op SHA-256 zit en payload-sensitive blijft.
   - `test/features/mirror/mirror_gateway_http_status_mapping_test.dart`: regressietest voor correcte 403 mapping op permission denied.
   - `test/features/mirror/mirror_usage_metering_integration_test.dart`: validatie dat gateway requests effectief in `mirror_usage_logs` landen.
   - `docs/mirror-contracts.md`: centrale mapping van gebruikte namen/contracten (gateway endpoint, bucketnamen, provider/backends) om drift met context/docs te voorkomen.
   - `docs/mirror-security-hardening.md`: minimale productiebaseline voor runner sandboxing (non-root, seccomp/apparmor, readonly rootfs, egress policy, CPU/mem limits).

- Verwijderingen (wat weg kan en waarom)
   - Verwijder of archiveer niet-overeenkomende terminologie in projectdocumentatie waar nog gesproken wordt over `mirror_staging`, `mirror_compute`, `EdgeFunctionBackend`, `CloudFlyBackend` als dat niet de actuele implementatie is.
   - Verwijder duplicatieve entitlement-providerlaag (`lib/core/providers/mirror_entitlement_provider.dart`) of consolideer deze met `mirror_premium_service` om API-oppervlak en verwarring te reduceren.
   - Verwijder legacy/fallback tekstpaden die premium/mirror status impliciet als boolean forceren zonder onzekerheidsstatus, zodat UX eerlijker en voorspelbaarder wordt.
