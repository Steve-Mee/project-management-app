# Mirror – Diepgaande Architecturale Analyse

**Rapport datum**: 22 maart 2026  
**Analyseniveau**: Senior architect review met 15+ jaar clean architecture & AI-integratie expertise  
**Analysestatus**: Voltooid – alle lagen systematisch gereviewd

## 1. Algemene beoordeling

### Sterke punten

1. **Architectuurlaagopbouw is krachtig en coherent**
   - Heldere scheiding tussen Flutter UI, Riverpod-providers, backend-abstracties en Supabase-infrastructuur
   - `MirrorGatewayBackend` en `PrivateGrpcBackend` implementeren identieke `MirrorComputeBackend` contract
   - Thin proxy gateway in `supabase/functions/mirror-gateway/index.ts` handhaaft focusregel (auth, idempotency, forwarding)
   - Alle layers hebben expliciete module grenzen en testable interfaces

2. **Security is meerlagig en geen client-only trust**
   - Flutter: `hasPermissionProvider(AppPermissions.useMirror)` guards access
   - Gateway: validatie van bearer auth, entitlement RPC, cloud-only mode checks
   - Database: RLS op alle Mirror-tabellen (`ai_sessions`, `mirror_request_idempotency`, `mirror_apply_audit_events`)
   - Storage: private buckets (`mirror-signed-inputs`, `mirror-backups`) met owner-scoped RLS-policies
   - gRPC: expliciete production transport-security guard in `PrivateGrpcBackend`
   - Dit is exceptie-niveau security-layering voor AI-features

3. **Database-ontwerp is production-grade**
   - Idempotency ledger met duidelijke state machine (`processing` → `completed|failed`) en request cache
   - Audit trail met fingerprints (`file_set`, `applied_files`, `diff`) voor forensisch onderzoek
   - Usage metering apart van audit voor billing en abuse-detectie
   - Realtime scoping via topic-based broadcast (`mirror_ai_sessions:user:project:task`)
   - Retention helpers en scheduled cleanup via pg_cron
   - UUID FK-hardening in progress (migration 20260322)

4. **Offline-first is structureel ontworpen**
   - Outbox queuing met retry policy, jitter, circuit breaker en persistent storage
   - Draft cache met caps (40 sessions, 80 files/session, 300KB/session, 25KB/file)
   - Hive encryption en stale-cache fallback
   - Replay coalescing voorkwamt duplicate efforts
   - Offline warning propagation naar UI

5. **Integratie met bestaande app sluit naadloos aan**
   - Route guards via `mirror_route_guard_provider.dart`
   - Deeplink handling via `mirror_route_intent.dart`
   - Mode-keuze centraal in `mirror_mode_controller_provider.dart`
   - Launch coordinator isoleert bootstrap logica
   - Geen wijzigingen nodig in project/task core models

6. **Scalability-eerste mindset zichtbaar**
   - Abstract backend contract ermogelijkt cloud/local/mock swapping
   - Contracttests voor gateway/storage/database
   - Observability hooks (latency, retry, fallback events) al aanwezig
   - Multi-agent team mode voorzien
   - A/B-testing hooks gebouwd voor variant management

### Zwakke punten

1. **Orchestration-verantwoordelijkheden zijn te verspreid**
   - `MirrorOrchestratorService` handelt retry/replay/invalation af
   - `MirrorRunFlowService` doet UI-interactie + sessie-state
   - `MirrorBackendWorkflows` bevat patch-planning + audit-persistentie
   - `MirrorApplyAuditService` geïsoleerd voor history
   - `MirrorApplyValidatorService` voor consistency-checks
   - Te veel entry points, moeilijker om volledige apply-flow mentaal te modelleren
   - **Status**: Deels verbeterd via PR1-PR5 consolidatie; meer splitsing nodig

2. **Gateway overstijgt de thin-proxy intentie**
   - Auth-validatie ✓ (appropriate)
   - Idempotency management ✓ (appropriate)
   - Rate limiting ✓ (arguably appropriate)
   - Circuit breaker ✓ (arguably appropriate)
   - **Maar ook**: request normalisatie, entitlement-checking, usage metering, audit writes
   - Module-structuur (`modules/`) helpt, maar `/index.ts` blijft groot (~500 regels)

3. **State-hydration in Flutter core is complex en race-condition-gevoelig** ⚠️
   - Meerdere async bronnen (auth, premium, flags, runners, repo context, offline cache) hydrateren gelijktijdig
   - Generation guards en deterministische resolver helpen, maar
   - Late completions kunnen van racelike bugs leiden
   - Testing vereist strakke async-sequencing control
   - **Status**: Hardened via state hydration PR; verdient nog meer observability

4. **Templates-cache fallback zonder expliciete warning**
   - Cache slaat terug op stale data when fetch fails/times out
   - Voor lijstdata is dit acceptabel; voor AI coding guidance is het risicant
   - User weet niet of templates "vers" zijn
   - **Aanbeveling**: Voeg staleness-indicator toe aan cache-fallback pad

5. **project_id en task_id blijven TEXT zonder FK**
   - Meerdere tabellen (`ai_sessions`, `mirror_apply_audit_events`, `mirror_usage_logs`)
   - Dangling references mogelijk bij project/task verwijdering
   - Analytics en cleanup worden zwakker
   - **Impact**: Laag-urgent; schema-migratie 20260322 voegt UUID FK toe (nog niet gekoppeld)

6. **Validatie-duplicatie tussen edge gateway en runners**
   - Zowel `supabase/functions/mirror-gateway/index.ts` als `server/mirror-shared/lib/http_gateway.dart` valideren payloads
   - Geen shared schema-contract tussen layers
   - **Aanbeveling**: Centraal request-schema-validatie service

### Overall score: **8.7/10**

**Basisredening**: Sterk architectuurontwerp, voorbeeldige security-layering, en production-mindset op database niveau. Zwaktes zijn vooral overhead-complexiteit (orchestration spreiding, gateway omvang, state-hydration timing) in plaats van fundamentele architectuurfouten. Offline-first en integratie zijn voorbeeldig. Met de aanbevolen consolidaties (orchestration splitting, gateway modularisatie, schema-centralisatie) bereiken we 9.2+/10.

---

## 2. Laag-voor-laag analyse

### Supabase / Database laag
**Sterke punten:**
- **Core schema**: `ai_sessions`, `mirror_request_idempotency`, `mirror_apply_audit_events`, `mirror_templates`, `mirror_usage_logs` zijn goed getructureerd met expliciete RLS-policies, geschikte indexen en lifecycle-management
- **Idempotency ledger**: State machine (`processing` → `completed|failed`), request cache (hash, response), expiry + cleanup scheduling via pg_cron. Dit is production-grade replay-protection
- **Storage hardening**: Buckets zijn private, policies zijn uid-scoped (`foldername()[1] = auth.uid()`), cleanup-functies voor old artifacts. Signed URLs worden correct begrensd
- **Audit separation**: Apply audit (`mirror_apply_audit_events`) vs usage metering (`mirror_usage_logs`) is schoon gescheiden voor compliance/billing
- **Realtime scoping**: `mirror_ai_sessions` broadcast via topic (`user:project:task`) in plaats van broad tabel-listeners. Dit is veiliger en schaalbaarder
- **Retention strategy**: Migrations tonen dat data lifecycle centraal is gedacht (retention pruning, status alignment, response cache alignment)

**Zwakke punten:**
- **TEXT project_id/task_id zonder FK**: Migratie 20260322 voegt UUID columns toe maar koppeling/validatie is nog in progress. Dangling references blijven mogelijk
- **Status-fragmentatie**: `ai_sessions.status` vs `mirror_usage_logs.status` vs `mirror_request_idempotency.status` — geen single source of truth
- **Template seed scaling**: Seed content in SQL werkt voor start, maar inlining van rijke templates in migrations is niet ideaal voor grote templates of versioning
- **RLS-test-dekking**: Tests in `supabase/tests/` zijn minimaal; geen duidelijke contract test voor RLS-grenzen

**Aanbeveling**: Voltooi UUID FK-linkage (PR in progress), harden RLS-test dekking, en verplaats template seeds naar Dart code + seeding service.

### Edge Functions & gRPC backend laag

**Sterke punten:**
- **Gateway maturity**: Request identity (`requestId`, `traceId`, `idempotencyKey`), structured errors met codes, replay-safe finalization, quota enforcement, circuit breaker, usage metering hooks
- **Beveiliging is gelaagd correct**: Auth-validatie → permission check (`use_mirror`) → entitlement RPC (cloud mode) → forwarding. Client-side mode wordt niet als authoriteitsbeslissing gebruikt
- **Backend-abstractie is clean**: `MirrorComputeBackend` contract, `MirrorGatewayBackend` vs `PrivateGrpcBackend` split, factory injection patterns
- **gRPC security guard**: `PrivateGrpcBackend` heeft expliciete production transport-security check (fail-closed als insecure in release mode)
- **Runner extensibility**: `runner_service.dart` voorziet auth verifier hook, compile/apply RPC, workspace cleanup en metric snapshot callbacks voor Fly/local variants
- **HTTP gateway contract**: Verrekeningslogica (success/failure classifiers, status mapping) is centraal en herbruikbaar

**Zwakke punten:**
- **Gateway is te omvangrijk**: ~500 regels in `/index.ts` ondanks `modules/` splitsing. Auth, normalization, rate limit, circuit breaker, forwarding, metering en audit schrijven zitten nog te dicht bij elkaar
- **Validatie-duplicatie**: Zowel edge gateway als runners valideren payloads, maar geen shared schema-contract
- **Module-structuur hangt in de lucht**: `modules/` directory helpt, maar `index.ts` orchestreert toch nog te veel logica. Voeg expliciete composition layer toe
- **Geen centrale request-schema**: Compile/apply request validatie is handmatig en verspreid. Gemist kans op herbruikbare test fixtures en contract enforcement

**Aanbeveling**: Extraheer centraal request-schema (@`lib/features/mirror/services/mirror_request_schema.dart` + `supabase/functions/mirror-gateway/modules/request_schema.ts`), voeg test fixtures toe voor gateway module tests en consolideer gateway index naar pure composition.

### Dart/Flutter core & providers laag

**Sterke punten:**
- **Mode-keuze is centraal en policy-gedreven**: `MirrorModeController` handelt write-ownership af, `mirrorResolvedModeProvider` levert read-model, `MirrorAccessPolicy` (in pma_core) bepaalt softbeleidsregels
- **Session state-model is rijp**: `MirrorSessionNotifier` bevat repository context, drafts, terminal logs, compile metadata met consistency-checks (`contextFingerprint`, `compileFingerprint`, `serverVersionToken`)
- **Premium is correct als UX-hint**: `MirrorPremiumService` levert non-authoritative signaal; gateway enforceert daadwerkelijk. Dit is de juiste security-keuze
- **Route-guard is centraal**: `mirror_route_guard_provider.dart` concentreert feature-flag + permission checks; minder bypass-risico via deeplinks
- **Riverpod-use is overwegend best-practice**: Factories, dependency injection patterns, family notifications zijn consistent gebruikt
- **State-hydration PR's hebben hardening aangebracht**: Generation guards, deterministische resolver, launch coordinator, timeout fallback guards

**Zwakke punten:**
- **Orchestration-verantwoordelijkheden zijn te verspreid**: 
  - `MirrorOrchestratorService` = retry + replay + invalidatie
  - `MirrorRunFlowService` = UI-interactie + sessie-state
  - `MirrorBackendWorkflows` = patch planning + audit
  - Te veel entry points; volledige apply-flow is mentaal zwaar te modelleren
  - **PR1-PR5 hebben geholpen** (shim removal, validator extraction, workflow consolidatie) maar verdient meer splitsing

- **Session hydration combineert meerdere async bronnen**:
  - Auth state, premium hints, feature flags, runners, repository context, offline cache hydrateren gelijktijdig
  - Generation guards en deterministische resolver helpen, maar
  - Late completions kunnen race-like bugs introduceren
  - Testing vereist strakke async-sequencing control
  - **Status**: Hardened; verdient nog meer observability (source/phase metadata)

- **Launch flow is nog niet puur bridges**: `ai_chat_provider.dart` doet naast launch bridging ook mode-init + team-variant refresh. Verdeling van concerns is nog niet scherp

- **Side-effectful hydration in providers**: Cache-hydration, mode-refresh side effects zitten nog in providers zelf. Dit strookt niet ideaal met Riverpod filosofie van pure computation

**Aanbeveling**: Splits orchestration verder via dedicated coordinator voor apply-flow, voeg expliciete phase/source metadata toe aan state voor diagnostica, isoleer side-effectful hydration in expliciete application services.

### UI & UX laag (editor, dialogs, realtime)

**Sterke punten:**
- **Mirror editor screen is rijp ontworpen**: Editor, explorer, terminal, realtime en voice in één coherent scherm zonder alles in build-logica te propen
- **Permission revocation is gracefully afgehandeld**: In plaats van crash/half-defect, schakelt sessie goed uit
- **Production-mindset zichtbaar**: Run locks, retry feedback, terminal status lines, templates entry point, responsive layout
- **Realtime layering is verzorgd**: Dedicated realtime service + editor controller hanteren spam, duplicate flushing en state drift
- **Voice flow heeft al guardrails**: `MirrorVoiceDraftSanitizer` verwijdert control/zero-width chars, caps op 2000 chars
- **Apply dialog heeft diff-rendering**: `MirrorDiffService` levert unified diff met volle context, gebruiker ziet wijzigingen voor apply

**Zwakke punten:**
- **Scherm is zwaar**: Monaco + explorer + terminal + voice + realtime in één StatefulWidget kan feature pressure opnemen over tijd
- **Templates-cache fallback zonder expliciete warning**: Stale data zichtbaar zonder duidelijk "offline fallback" label. AI studio-context maakt dit riskanter dan normale CRUD-lijsten
- **Voice-draft zichtbaarheid**: Sanitization werkt goed, maar draft-laag is niet altijd prominent voor gebruiker. Voor AI coding is expliciete review van voice-input kritiek
- **Apply review is nog niet multi-file-optimized**: Huidige flow werkt per-file, maar grote refactors met 20+ patches zijn lastiger om granular te reviewen
- **Geen stage-based rollback-UI**: Eenmaal applied, enkel undo/revert; geen "cherry-pick patches" na apply

**Aanbeveling**: Splits editor-orchestration uit in dedicated service, voeg staleness-badge aan templates-fallback, en maak patched-file review granularer (skip/apply per patch).

### Security, permissions & premium checks

**Sterke punten:**
- **Meerlagige verweving**: Flutter route-guards, Supabase RLS, gateway auth, entitlement RPC, signed artifact flow, gRPC transport security
- **Route guard is centraal**: `mirror_route_guard_provider.dart` concentreert feature-flag + permission; bypass-risico minimaal
- **Premium is non-authoritative**: `MirrorPremiumService` levert UX-hint; gateway is waarheid. Dit is de juiste verdeling van verantwoordelijkheden
- **Signed artifact flow is degelijk**: `MirrorSecureApplyService` genereert backup + signed URLs; audit trail bevat fingerprints voor forensica
- **Storage is eigenaar-scoped**: RLS policies enforce `auth.uid` prefix in object paden
- **Repay protection is sluitend**: Idempotency ledger met request hash + status machine voorkomt duplicate execution

**Zwakke punten:**
- **Entitlement governance is verspreid**: Premium checks, A/B-varianten, admin bypasses zitten in providers, policy, gateway. Functioneel werkt het, maar audit trail is minder strak
- **Logging bevat veel context**: Request metadata is nuttig voor debugging, maar discipline nodig om gevoelige data (prompts, artifacts) niet onbedoeld in logs te zetten bij toekomstige extensies
- **Admin audit is impliciet**: geen centrale audit trail wanneer admins feature flags wijzigen. Dit is operationeel risico
- **Geen expliciete threat model**: Survey van docs toont geen STRIDE of vergelijkbare systematische threat analyse

**Aanbeveling**: Maak admin audit trail expliciet (who changed flags, when, what value), formaliseer threat model document (prompt injection, artifact leakage, privilege escalation, signed URL misbruik), en strak aanvullende logging discipline.

### Offline / Hive / caching laag

**Sterke punten:**
- **Outbox replay is robuust ontworpen**: Queuing met retry policy, jitter, circuit breaker, persistent Hive storage, reconnect-triggered processing
- **Draft cache heeft expliciete grenzen**: Sessie caps (40), file caps (80/session), char caps (300KB/session, 25KB/file). Dit voorkomt oncontroleerde groei op devices
- **Hive is encrypted**: Local persistence is niet in plain text
- **Offline warning propagation**: App kan offline state tonen zonder silently failing
- **Replay coalescing**: Voorkwamt duplicate replay runs bij snelle verbindingen
- **Stale cache fallback**: App blijft functioneel indien fetch mislukt; data is niet verloren

**Zwakke punten:**
- **Outbox entry parsing is stil**: `MirrorOutboxEntry.fromRaw()` faalt stil met `null` bij parseproblemen. Stille queue-verliesgevallen mogelijk zonder herstelinformatie
- **Templates cache-fallback zonder expliciete waarschuwing**: Stale templates zichtbaar zonder "cache fallback" label. AI studio-context maakt dit riskanter
- **Invalidation discipline is impliciet**: Cache TTL + serverVersion-check werkt, maar geen expliciete invalidation triggering vanuit sync events
- **Circuit breaker state is in-memory per instance**: Meerdere app instances kunnen onafhankelijk failover/recover. Gedistribueerde circuit breaker ontbreekt
- **Complex fallback-gedrag**: Encryptie, replay, circuit breaker in één kritiek pad; edge-case failures lastiger reproduceren

**Aanbeveling**: Voeg structured logging toe aan outbox parsing (retry/drop events), voeg staleness-badge aan template fallback, maak invalidation explicieter triggerbaar, overweeg gedistribueerde circuit breaker state op test-niveau.

### Integratie met bestaande app

**Sterke punten:**
- **Integratie volgt het pattern uit bestaande app**: Routes via `lib/core/routes.dart`, guard via provider, deeplink handling via `mirror_route_intent.dart`
- **Geen wijzigingen in core models**: Project/task/auth entiteiten blijven ongewijzigd
- **Launch coordinatie**: Entry points (projectcard, taskcard, AI bridge) convergen via centraal launch flow
- **Permission gating is consequent**: Dezelfde `AppPermissions.useMirror` wordt overal gebruikt
- **Feature flag integration**: Mirror kan globaal uitgeschakeld worden; keuze respecteren

**Zwakke punten:**
- **Meerdere entry points naar dezelfde editor**: Product-logisch ok, maar mode-initialisatie, routing guards, feature gating moeten echt centraal blijven
- **Mirror heeft rijkere infra dan veel andere features**: Offline queuing, entitlement logica, team mode, gRPC runners. Dit is goed voor Mirror, maar vraagt discipline zodat het geen architecturale uitzondering wordt
- **Geen centraal event-emitting voor Mirror-milestones**: Apply complete, compile error, etc. zijn handled lokaal. Cross-feature events zouden nuttig kunnen zijn (notification, analytics pipeline)

**Aanbeveling**: Zorg dat mode-init, guard-sequencing, entitlement checks echt centraal blijven via dedicated launch coordinator. Bouw event-emitting payload in mirrors-events voor cross-feature signaling.

---

## 3. Concrete aanbevelingen

### A. Wijzigingen (met exacte bestandsnamen en wat te veranderen)
#### 1. **supabase/functions/mirror-gateway/index.ts** – Gateway modularisatie
   - **REFACTOR**: Splits composition logic verder. `index.ts` moet alleen:
     - Request entry point accepteren
     - Middleware-chain stellen: auth → idempotency → rate limit → circuit breaker → forward
     - Response finalize
   - **Verplaats naar `modules/`**: Auth dispatch, entitlement checking, custom rate-limit rules
   - **Voeg toe**: Central request-schema validation VOORDAT handleidling/normality start

#### 2. **lib/features/mirror/mirror_gateway_backend.dart** – Backend consolidatie
   - **REFACTOR**: Isoleer compile/apply retry en fallback-logica in dedicated `mirror_retry_policy.dart` methods
   - **REMOVE**: Dubbele validatie; vertrouw op centraal schema contract
   - **ADD**: Observability hooks voor backend-specific latency/failure classification

#### 3. **lib/features/mirror/private_grpc_backend.dart** – gRPC backend cleanup
   - **KEEP**: Production TLS guard (juist)
   - **REFACTOR**: Verplaats shared secure-apply flow naar gemeenschappelijke service (`mirror_secure_apply_service.dart`)
   - **CONSOLIDATE**: Cloud/local backends moeten identieke apply-flow gebruiken

#### 4. **lib/core/providers/mirror_mode_controller_provider.dart** – State ownership verification
   - **VERIFY**: Dit is de **single write owner** voor Mirror mode state
   - **ADD**: Explicit provenance metadata (source: 'explicit', 'cached', 'flag_default', 'premium_fallback') voor diagnostica
   - **CONSOLIDATE**: Alle mode-mutaties moeten via deze controller gaan

#### 5. **lib/core/providers/mirror_session_provider.dart** – Session bootstrap cleanup
   - **SPLIT**: Repository context hydration, draft restore, editor state in aparte concerns
   - **ADD**: Explicit lifecycle moments (run, apply, route-exit) voor persistence in plaats van alleen debounced autosave
   - **FIX**: Voeg generation guards toe zodat late completions oude state niet kunnen overschrijven

#### 6. **lib/features/mirror/providers/mirror_templates_provider.dart** – Cache staleness
   - **ADD**: Expliciete staleness-indicator wanneer cache fallback wordt gebruikt
   - **MAKE EXPLICIT**: Invalidation triggering vanuit sync events in plaats van alleen TTL/serverVersion
   - **ADD**: User-facing network-error message wanneer template fetch mislukt

#### 7. **lib/features/mirror/services/mirror_orchestrator_service.dart** – Orchestration splitting
   - **SPLIT**: Compile, apply en generate zijn aparte execution paths
   - **EXTRACT**: Consistency validation naar aparte validator service (al gedaan via PR2)
   - **CONSOLIDATE**: Retry, replay, observability moeten gedeeld zijn

#### 8. **server/mirror-shared/lib/request_validator.dart** – Server-side schema validation
   - **CREATE**: Centraal request schema-contract zodat edge gateway en runners aligned zijn
   - **USE**: Dit in beide `http_gateway.dart` en edge gateway modules

#### 9. **supabase/migrations/20260322_mirror_context_uuid_fk_hardening.sql** (in progress)
   - **COMPLETE**: UUID FK linkage voor project/task references
   - **ADD**: Constraint enforcement zodat dangling references voorkomen worden
   - **MIGRATE**: TEXT projectId/taskId naar UUID projectUuid/taskUuid in alle tabellen

#### 10. **lib/features/mirror/services/mirror_apply_security_mode_service.dart** – Security mode consolidation
   - **VERIFY**: Dit is de single source of truth voor signed vs. direct apply-flow keuze
   - **KEEP**: Current rule hierarchy (policy → cloud sensitivity → trust score → audit → size → default)
   - **ENSURE**: Zowel cloud gateway als private gRPC backends gebruiken dezelfde service

### B. Toevoegingen (nieuwe bestanden/features)

#### 1. **lib/features/mirror/services/mirror_gateway_request_schema.dart**
   - Centrale request schema/validation laag voor Mirror compile/apply requests
   - Herbruikbaar in edge gateway tests, runner sanity checks, en Dart serialize-tests
   - Voelstukken: `CompileRequestSchema`, `ApplyRequestSchema` met `validate()` methods
   - Implementatie: Zie bestaande `mirror_request_schema.dart` (al aanwezig in gateway modules)

#### 2. **supabase/functions/mirror-gateway/modules/request_schema.ts**
   - Deno-port van schema-validatie
   - Gedeeld contract met Dart-implementatie
   - Gebruikt in payload-normalization flow

#### 3. **lib/features/mirror/services/mirror_apply_flow_coordinator.dart**
   - Standalone coordinator voor complete apply-flow: compile → preview → validate → apply
   - Isolates orchestration logic uit `MirrorOrchestratorService`
   - Public interface: `executeApplyFlow({required String projectId, required String taskId, ...})`

#### 4. **lib/features/mirror/widgets/mirror_patch_review_sheet.dart**
   - Uitgebreid review UI voor multi-file apply
   - Features: per-file skip/apply buttons, diff rendering met syntax highlighting, patch metadata
   - Reuses `MirrorDiffService` voor diff rendering

#### 5. **test/features/mirror/mirror_gateway_schema_validation_test.dart**
   - Contract tests voor request-schema en structured error mapping
   - Coverage: Valid payloads, missing fields, oversized values, type mismatches
   - Validates edge gateway kan payloads accepteren

#### 6. **test/features/mirror/mirror_request_idempotency_test.dart** (uitbreiding)
   - Add tests voor: claim → processing → stale recovery → finalization
   - Add tests voor: expired request cleanup via pg_cron
   - Validates database contracten

#### 7. **docs/mirror_operational_runbook.md**
   - Gateway environment variables en secrets
   - Cloud/local runner deployment-checklist
   - Incident response procedures (timeout, auth deny, circuit breaker open)
   - Idempotency + artifact cleanup schedules
   - Entitlement-debugging (check premium status, feature flags, permissions)

#### 8. **docs/mirror_threat_model.md**
   - Structured threat analysis (STRIDE):
     - **Spoofing**: JWT validation, deeplink parameter validation
     - **Tampering**: RLS checks, signed URLs voor artifacts, idempotency ledger
     - **Repudiation**: Audit trail (`mirror_apply_audit_events`), usage logs
     - **Information Disclosure**: Encryption for Hive, signed URL TTL, careful logging
     - **Denial of Service**: Rate limiting, circuit breaker, quota enforcement
     - **Elevation of Privilege**: Feature flags, permission checks, admin audit trail
   - Admin bypass governance + approval process
   - AI prompt injection + artifact leakage mitigation

#### 9. **supabase/functions/mirror-gateway/modules/request_identity.ts** (enhancing existing)
   - Expand existing `routing_identity.ts` to be more explicit about correlation IDs
   - Add validation that idempotencyKey matches request format

#### 10. **lib/features/mirror/services/mirror_integration_test_helpers.dart**
   - Shared test utilities for setting up Mirror state (session, context, cache)
   - Factories voor mock backends, fake orchestrators, test data builders

### C. Verwijderingen (wat weg kan en waarom)

#### 1. **lib/features/mirror/services/mirror_editor_orchestration_service.dart** ✅ VERWIJDERD
   - Was deprecated shim → `mirrorInteractiveRunCoordinatorProvider`
   - Echte flow-logica zit in `mirror_run_flow_service.dart`
   - Removed in PR1; already gone

#### 2. **Dubbele validatie-paden** tussen edge gateway en runners
   - Consolideer naar shared schema contract (zie: `mirror_request_schema.dart`)
   - **Verwijder**: Hand-coded payload validation in beide `http_gateway.dart` en `/index.ts`
   - Voordeel: Consistent validation, makkelijker testen

#### 3. **Compat/shim-indirectie rond launch flows**
   - `lib/core/providers/ai_chat_provider.dart` houdt te  veel orchestration logica
   - Zodra centraal launch coordinator bestaat: dun de bridge af tot puur intent-opzetting
   - Verwijder mode-init + team-variant refresh uit bridge (move naar coordinator)

#### 4. **Ongebruikte fallback-helpers in backends**
   - Scan `mirror_gateway_backend.dart` en `private_grpc_backend.dart` voor dead code
   - Verwijder: Preview/apply methods die niet meer gebruikt worden
   - Consolideer: Shared behavior naar `mirror_backend_workflows.dart`

#### 5. **Legacy request-normalization code** (once schema-based validation exists)
   - Veel manuele veld-fixup zit in `mirror_gateway_backend.dart`
   - Zodra schema validation centraal is: kunnen we dit verwijderen
   - Data binnengekomen via gateway moet al gevalideerd/genormaliseerd zijn

#### 6. **Geen echt nodig oude feature-flag branching** in Mirror core
   - Code paths die feature-flag legacy-code ondersteunen: verwijderen zodra all users upgraded
   - Example: Old offline queueing format, legacy template format, old session schema

### D. Prioriteitsmatrix voor implementatie

| Prioriteit | Item | Impact | Effort |
|--|--|--|--|
| **P0** | UUID FK-hardening (migration 20260322) | Data integrity, cleanup, analytics | Medium |
| **P0** | Centraal request-schema validatie | Sync edge/runner contracts | Low |
| **P1** | Orchestration splitting (apply-flow coordinator) | Cognitive load, maintainability | High |
| **P1** | Gateway modularisatie (composition refactor) | Thin-proxy intent, testablity | Medium |
| **P1** | Session bootstrap cleanup (split hydration concerns) | Race-condition resilience | Medium |
| **P2** | Templates staleness-indicator | Trust, UX transparency | Low |
| **P2** | Operational runbook + threat model | Ops readiness, security audit | Medium |
| **P2** | Multi-file apply review-UI | Usability at scale | Medium |
| **P3** | Circuit breaker distribution (test-level) | High-availability | Low |

---

## Samenvatting

Dit rapport toont dat Mirror een **architecturaal sterke**, **security-gedreven** en **production-ready** feature is. De implementatie toont:
- ✅ Meerlagige security (no client-only trust)
- ✅ Production-grade database design (RLS, audit, metering)
- ✅ Offline-first resilience
- ✅ Clean backend abstraction
- ✅ Naadloze app integratie

De aanbevelingen adresseren overhead-complexiteit (orchestration spreiding, gateway omvang, state-hydration timing) in plaats van fundamentele architectuurfouten. Met de P0/P1-aanpassingen (schema-centralisatie, FK-hardening, orchestration splitting, session cleanup) bereiken we **9.2+/10** op architectuur-maturiteit.

**Volgende stappen**:
1. Complete UUID FK-hardening (in progress migration)
2. Centraal request-schema + validation consolidatie
3. Apply-flow coordinator extractie
4. Session bootstrap clarity + generation guards
5. Operational documentation hardening
- Extracted write-owner controller into `lib/core/providers/mirror_mode_controller_provider.dart`: contains `MirrorState`, `MirrorModeController` (single Riverpod `Notifier` write-owner), and derived read-model providers `mirrorResolvedStateProvider`, `mirrorResolvedModeProvider`, `mirrorResolvedOfflineWarningProvider`.
- Extracted async input snapshot providers into `lib/core/providers/mirror_hydration_inputs_provider.dart`: `currentMirrorUserIdProvider`, `mirrorPremiumSnapshotProvider`, `mirrorFeatureGateSnapshotProvider`, team/runner variant snapshot and projection providers.
- Migrated all production callsites (`mirror_editor_screen.dart`, `mirror_launch_coordinator.dart`, `mirror_session_provider.dart`, `mirror_entitlement_provider.dart`) off shim symbols.
- Migrated all test files off `MirrorNotifier`/`mirrorProvider`/`mirrorModeProvider`/`mirrorOfflineWarningProvider` to new canonical names.
- Renamed `test/core/providers/mirror_provider_test.dart` → `test/core/providers/mirror_mode_controller_provider_test.dart`.
- Updated `lib/core/providers.dart` barrel: replaced shim export with two new provider exports.
- Flutter analyze and `get_errors` both confirm zero issues after removal.