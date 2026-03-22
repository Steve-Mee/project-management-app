# Mirror Analyse

**Status**: Core orchestration refactoring completed (PR1-PR3). See "Execution Summary" below.

### 1. Algemene beoordeling
- Sterke punten
  - De Mirror-implementatie is architectonisch overtuigend opgezet als een meerlagig systeem met heldere scheiding tussen Flutter UI, provider-gedreven core state, backend-abstrahering en Supabase-infrastructuur. Die richting is consequent zichtbaar in `lib/features/mirror/mirror_gateway_backend.dart`, `lib/features/mirror/private_grpc_backend.dart`, `lib/features/mirror/services/mirror_backend_workflows.dart` en `supabase/functions/mirror-gateway/index.ts`.
  - De security-baseline is sterk. Mirror vertrouwt niet op client-only checks: permissies worden in Flutter gecontroleerd via `hasPermissionProvider(AppPermissions.useMirror)`, in de gateway via `has_permission('use_mirror')`, en voor cloud mode aanvullend via `has_cloud_mirror_access()`. Bovendien zijn storage buckets private en owner-scoped ingericht in `supabase/migrations/20260308_mirror_storage_hardening.sql`.
  - De Supabase-laag is production-minded uitgewerkt. `ai_sessions`, `mirror_request_idempotency`, `mirror_apply_audit_events`, `mirror_templates` en `mirror_usage_logs` hebben expliciete RLS-policies, indexering en retention/cleanup-paden. Dat is bovengemiddeld volwassen voor een nieuwe AI-feature.
  - De offline-first aanpak is inhoudelijk sterk. `lib/features/mirror/services/mirror_outbox_replay_service.dart`, `lib/features/mirror/services/mirror_draft_cache_service.dart` en `lib/core/providers/mirror_offline_cache_provider.dart` laten zien dat queueing, retry, replay, lokale drafts en cache-invalidering structureel zijn ontworpen.
  - De integratie met de bestaande app is coherent. Mirror wordt geopend vanuit taak- en projectcontext via `lib/core/providers/ai_chat_provider.dart`, guarded via `lib/features/mirror/providers/mirror_route_guard_provider.dart`, en geroute via `lib/core/routes.dart`. Dat sluit goed aan op bestaande app-patronen.
  - De implementatie is duidelijk ontworpen met schaalbaarheid in gedachten: abstracte backendcontracten, meerdere runnerpaden, contracttests voor database/security en observability/metering hooks zijn al aanwezig.
- Zwakke punten
  - De orchestration-laag is te verspreid geraakt. Verantwoordelijkheden zitten nu verdeeld over `mirror_orchestrator_service.dart`, `mirror_run_flow_service.dart`, `mirror_backend_workflows.dart`, `mirror_patch_pipeline_service.dart` en delen van de backends. Dat verhoogt cognitieve last en regressierisico.
  - De gateway is formeel een thin proxy, maar feitelijk bevat `supabase/functions/mirror-gateway/index.ts` veel middleware- en domeinlogica: normalisatie, auth, entitlement, idempotency, rate limiting, circuit breaker, usage logging en audit writes. Dat werkt functioneel, maar wijkt af van de architectuurintentie en vergroot de blast radius van wijzigingen.
  - De state-hydration in de Flutter core combineert meerdere async bronnen tegelijk: auth state, premium hints, feature flags, A/B-varianten, repositorycontext en offline cache. In `lib/core/providers/mirror_provider.dart` en `lib/core/providers/mirror_session_provider.dart` werkt dit, maar het maakt timinggedrag gevoelig voor race conditions en complexer om te testen.
  - De templates-cache in `lib/features/mirror/providers/mirror_templates_provider.dart` kan bij netwerkproblemen stale data tonen zonder expliciete user-facing waarschuwing. Voor een AI coding studio is dat productmatig riskanter dan bij gewone lijstdata.
  - `project_id` en `task_id` worden in meerdere Mirror-tabellen als `TEXT` opgeslagen zonder relationele koppeling. Dat houdt de feature losjes gekoppeld, maar verzwakt datakwaliteit, cleanup en rapportage op de lange termijn.
  - Er is nog rest-overlap tussen compat/shim-lagen en de huidige architectuur. `lib/core/providers/mirror_provider.dart` fungeert deels nog als compatibele façade naast nieuwere providers en services, wat het state-eigenaarschap minder scherp maakt.
- Overall score (1-10)
  - 8.7/10

### 2. Laag-voor-laag analyse
- Supabase / Database laag
  - De database-opzet is degelijk en consistent met een production-grade Mirror feature. `supabase/migrations/20260310_create_ai_sessions_baseline.sql` definieert `ai_sessions` met owner-based RLS, update-trigger en indexen. `supabase/migrations/20260310_mirror_request_idempotency.sql` en opvolgende migraties laten zien dat idempotency niet alleen bestaat, maar ook iteratief is gehard.
  - `supabase/migrations/20260308_mirror_storage_hardening.sql` is sterk opgezet: de buckets `mirror-signed-inputs` en `mirror-backups` zijn private, policies zijn user-scoped, en artifact cleanup is als service-role functie ingebouwd. Dat past goed bij secure apply en signed URLs.
  - `supabase/migrations/20260308_mirror_audit_and_ai_sessions_retention.sql` en `supabase/migrations/20260311_mirror_usage_metering.sql` scheiden audit events en usage metering netjes. Dat is goed voor compliance, incidentanalyse en latere billing/abuse detectie.
  - `supabase/migrations/20260309_mirror_ai_sessions_broadcast_topics.sql` beperkt realtime naar topic-gebaseerde user/project/task scopes. Dat is veiliger en schaalbaarder dan brede listeners op de volledige tabel.
  - `supabase/migrations/20260309_mirror_templates_rls_and_sync.sql` maakt templates DB-first en seed-managed. Dat is sterk voor beheerbaarheid, maar seed content in pure SQL wordt op termijn minder prettig schaalbaar wanneer templates rijker of complexer worden.
  - Zwakke plek: meerdere tabellen gebruiken `project_id` en `task_id` als `TEXT` zonder FK-relatie naar kernentiteiten. Daardoor blijven dangling references, minder betrouwbare analytics en moeilijkere cleanup waarschijnlijker.
  - Zwakke plek: statusmodellen zijn verdeeld over meerdere tabellen (`ai_sessions.status` versus `mirror_usage_logs.status`). Dat is niet direct fout, maar vraagt strakke documentatie en querydiscipline om inconsistent rapportagegedrag te vermijden.

- Edge Functions & gRPC backend laag
  - De gateway in `supabase/functions/mirror-gateway/index.ts` is technisch volwassen. De functie heeft duidelijke request identity (`requestId`, `traceId`, `idempotencyKey`), structured errors, replay-safe idempotency, quota- en rate-limitlogica, circuit breaker gedrag en audit/metering hooks.
  - De beveiliging is correct gelaagd. De gateway valideert auth, `use_mirror` en cloud entitlement voordat compute wordt doorgelaten. Daardoor wordt client-side modekeuze geen echte autorisatiebeslissing.
  - De backend-abstrahering is goed ontworpen. In Flutter scheiden `MirrorGatewayBackend` en `PrivateGrpcBackend` cloud en private transport, terwijl `MirrorComputeBackend` als contractlaag fungeert. Dat maakt de feature uitbreidbaar en testbaar.
  - `lib/features/mirror/private_grpc_backend.dart` bevat een expliciete production guard tegen insecure gRPC transport. Dat is een belangrijk hardening-detail dat vaak ontbreekt in local-first runner-opzetten.
  - `server/mirror-shared/lib/runner_service.dart` is degelijk opgezet: auth verifier hook, compile/apply RPC handling, workspace cleanup scheduler en metric snapshot hooks zijn aanwezig. Dat ondersteunt schaalbaarheid richting Fly.io of andere runneromgevingen.
  - `server/mirror-shared/lib/http_gateway.dart` laat zien dat de compute-runners zelf ook quota- en payload-validatie hebben. Dat is goed als defense-in-depth, maar introduceert ook validatieduplicatie tussen edge gateway en runner gateway.
  - Grootste zwakte: `supabase/functions/mirror-gateway/index.ts` is te groot voor zijn architecturale rol. Auth, normalization, rate limits, circuit breaker, forwarding, metering en audit zitten nog te dicht bij elkaar. Verdere modularisatie is nodig om de thin-proxy intentie daadwerkelijk af te dwingen.
  - Tweede zwakte: runtime payload-validatie is grotendeels handmatig en verspreid. Er is normalisatie, maar nog geen centrale request schema-laag die compile/apply payloads eenduidig specificeert en herbruikbaar testbaar maakt.

- Dart/Flutter core & providers laag
  - `lib/core/providers/mirror_provider.dart` laat een duidelijke policy-gedreven aanpak zien. De combinatie van `MirrorAccessPolicy`, premium hinting, feature flags, runner variant en offline cache zorgt ervoor dat de user modekeuze niet rechtstreeks in de UI wordt afgehandeld.
  - `packages/pma_core/lib/services/mirror_access_policy.dart` is compact, goed leesbaar en business-rule gedreven. Dat is een sterk punt: modebeslissingen zijn gecentraliseerd in plaats van verspreid over widgets of losse services.
  - `lib/core/providers/mirror_session_provider.dart` is inhoudelijk sterk omdat het repository-context, drafts, terminal logs en compile metadata samenbrengt. Het model met `contextFingerprint`, `contextVersion`, `compileFingerprint` en `compileServerVersionToken` ondersteunt consistency checks goed.
  - Tegelijk is `mirror_session_provider.dart` te zwaar belast: hydratie uit repository, lokale draft restore, persist debounce en actieve editor/session state zitten samen in één notifier. Dat werkt, maar is onderhoudstechnisch te veel voor één state-object.
  - `lib/core/services/mirror_premium_service.dart` is correct gelabeld als non-authoritative UX hint. Dat is de juiste security-keuze. Wel blijft er daardoor bewust client/server-splitsing bestaan in premium state, wat in edge cases tot UX-conflict kan leiden wanneer de gateway strenger is dan de lokale hint.
  - `lib/core/providers/ai_chat_provider.dart` integreert netjes met de Mirror-flow, maar doet naast launch bridging ook al mode-initialisatie en team-variant refresh. Daardoor is de bridge minder puur dan ideaal is.
  - De providers zijn grotendeels consistent met Riverpod best practices, maar er zit nog te veel side-effectful hydration in providers zelf. Voor langdurige maintainability hoort een deel hiervan in expliciete application services of launch coordinators.

- UI & UX laag (editor, dialogs, realtime)
  - `lib/features/mirror/mirror_editor_screen.dart` is een van de sterkste onderdelen van de implementatie. De screen combineert editor, file explorer, terminal, realtime en voice zonder dat alles direct in build-logica wordt gepropt. Permission revocation wordt correct afgevangen en leidt tot sessie-disable in plaats van half-defect gedrag.
  - De UI voelt ontworpen als productieroute, niet als demo. Run locks, retry feedback, terminal statusregels, templates entrypoint en responsive layout tonen een volwassen benadering.
  - De realtime integratie oogt zorgvuldig. Er is zowel een dedicated realtime service als een editor controller-laag, wat spam, dubbel flushen en state drift helpt beheersen.
  - De aanwezigheid van Monaco, explorer, terminal en voice in één scherm is ambitieus, maar maakt het scherm ook zwaar. Zonder verdere opsplitsing van orchestration en UI-besluiten kan dit scherm na verloop van tijd te veel feature pressure opnemen.
  - De UX rond templates is functioneel sterk, maar cache-fallback zonder expliciete warning is een risico voor vertrouwen in de editor-output.
  - De voice-flow heeft al sanitization (`mirror_voice_draft_sanitizer.dart`), maar voor een AI coding studio blijft het veiliger om voice altijd als expliciete draftlaag zichtbaar te houden voordat codecontext aangepast of gecompileerd wordt. Dat is deels aanwezig, maar verdient nog scherpere UX-guardrails.
  - Voor grote multi-file apply-scenario's ontbreekt nog een echt staged review-model. De huidige apply-flow is verantwoord, maar kan productiegewijs nog sterker met granular review/skip/apply controls per patch of file.

- Security, permissions & premium checks
  - Mirror is goed beveiligd op meerdere niveaus: Flutter route- en action-guards, Supabase RLS, gateway auth, entitlement RPC, signed artifact flow en gRPC transportguard. Dit is een van de sterkste gebieden van de implementatie.
  - `lib/features/mirror/providers/mirror_route_guard_provider.dart` voorkomt dat routing zonder feature flag of permission toch doorvalt naar de editor. Dat is consistent met de rest van de app en minimaliseert bypass-risico via deep links.
  - `lib/core/services/mirror_premium_service.dart` behandelt premium expliciet als UX-hint en niet als autoriteitsbron. Dat is inhoudelijk correct en veilig.
  - De secure apply-aanpak via `mirror_backend_workflows.dart` plus storage hardening maakt de apply flow verdedigbaar en auditbaar. Dat is cruciaal bij AI-gegenereerde codewijzigingen.
  - Zwak punt: entitlement, A/B varianten en admin bypasses zijn verspreid over providers, policy en gateway. Functioneel klopt het, maar governance wordt hierdoor deels procedureel in plaats van uitsluitend technisch. Zonder strakke admin-audit op flagwijzigingen blijft dit een operationeel risico.
  - Zwak punt: logging en structured errors bevatten veel request-context. Dat is nuttig, maar vergt blijvende discipline om te voorkomen dat prompt- of artifactgevoelige gegevens onbedoeld in logs belanden bij toekomstige uitbreidingen.

- Offline / Hive / caching laag
  - Deze laag is inhoudelijk sterk. `lib/features/mirror/services/mirror_outbox_replay_service.dart` bevat niet alleen queueing, maar ook replay planning, retry policy, jitter, circuit breaker, persistent opslag en reconnect-triggered verwerking. Dat is bovengemiddeld goed uitgewerkt.
  - `lib/features/mirror/services/mirror_draft_cache_service.dart` en `lib/core/providers/mirror_offline_cache_provider.dart` laten zien dat lokale state niet onbeperkt groeit. Caps op sessies, files en chars zijn essentieel voor stabiliteit op echte devices.
  - De outbox-laag is robuust, maar complex. Encryptie, replay en fallback-gedrag zitten in een kritiek pad; dat is goed voor veiligheid, maar verhoogt de kans dat edge-case failures lastiger te reproduceren zijn.
  - `MirrorOutboxEntry.fromRaw()` in `mirror_outbox_replay_service.dart` faalt stil met `null` bij parseproblemen. Dat houdt de app resilient, maar kan ook leiden tot stille queue-verliesgevallen zonder voldoende herstelinformatie.
  - `mirror_templates_provider.dart` gebruikt memory + persistent cache + TTL + serverVersion-check. Functioneel is dat efficiënt, maar invalidatie en fallbackgedrag verdienen een explicietere productbeslissing omdat stale templates voor Mirror zwaarder wegen dan stale lijstdata elders in de app.
  - Overall past deze laag goed bij de offline-first richting van de rest van de codebase, maar hij moet vooral verder vereenvoudigd en beter observeerbaar worden, niet fundamenteel herbouwd.

- Integratie met bestaande app
  - De integratie is duidelijk ingebed in bestaande appflows. `lib/core/providers/ai_chat_provider.dart`, `lib/features/project/project_detail_screen.dart`, `lib/features/project/expandable_task_card.dart`, `lib/core/projects_initializer.dart` en `lib/core/routes.dart` vormen samen een logische keten van intent naar navigatie.
  - De route-intent parsing in `lib/core/mirror_route_intent.dart` is klein, helder en passend bij de bestaande routingstijl. Dat is goed clean-code gedrag.
  - Het guard-model sluit aan bij bestaande provider-patronen in de codebase in plaats van Mirror als volledig eigen domein buiten de apparchitectuur te behandelen. Dat maakt de feature consistenter met de rest van de repository.
  - Mirror voelt niet als een los plugin-eiland; het gebruikt bestaande auth-, permission-, routing- en project/taskcontext. Dat is positief voor maintainability.
  - Zwakke plek: er zijn meerdere entrypoints naar dezelfde editorervaring. Dat is logisch vanuit productperspectief, maar betekent dat mode-initialisatie, routeguarding en feature gating echt centraal moeten blijven om drift tussen paden te voorkomen.
  - Zwakke plek: de Mirror-feature heeft een rijkere infrastructuur en strengere security/offline-logica dan veel andere features in de app. Dat is goed voor Mirror zelf, maar vraagt actieve discipline om te voorkomen dat het een architecturale uitzondering wordt waar andere features niet meer op aansluiten.

### 3. Concrete aanbevelingen
- Wijzigingen (met exacte bestandsnamen en wat te veranderen)
  - `supabase/functions/mirror-gateway/index.ts`
    - Splits de resterende concerns verder uit naar afzonderlijke modules voor auth/permission, idempotency, rate limiting, circuit breaker en forwarding. Houd `index.ts` als compositielaag.
    - Voeg een centrale request-schema validatie toe voor compile/apply payloads voordat normalisatie start, zodat validatiegedrag niet meer impliciet verspreid zit.
    - Beperk domeinbeslissingen in de gateway tot policy enforcement; houd runner-specifieke of patch-specifieke interpretatie buiten deze laag.
  - `lib/core/providers/mirror_provider.dart`
    - Verplaats cache-hydration en sommige async refreshes naar expliciete application services of een launch coordinator, zodat deze provider minder lifecycle-complexiteit draagt.
    - Houd deze provider op termijn alleen verantwoordelijk voor user-facing Mirror mode state in plaats van ook compat/shim gedrag.
  - `lib/core/providers/mirror_session_provider.dart`
    - Splits repository context hydration, draft restore en actieve editor/session state op in kleinere verantwoordelijkheden.
    - Maak persistence explicieter op belangrijke lifecycle-momenten zoals run, apply en route-exit, zodat debounced autosave niet de enige waarheid is.
  - `lib/core/providers/ai_chat_provider.dart`
    - Maak `openMirrorFromTask` een small bridge die alleen launch intent opstelt. Verplaats mode-initialisatie en team-variant refresh naar een centrale `mirror_launch_coordinator` service of provider.
  - `lib/features/mirror/providers/mirror_templates_provider.dart`
    - Voeg een user-facing staleness signaal toe wanneer cache fallback wordt gebruikt wegens netwerk- of fetchfouten.
    - Maak invalidering expliciet triggerbaar vanuit beheerflows of seed-sync events in plaats van alleen TTL/serverVersion gestuurd.
  - `lib/features/mirror/mirror_gateway_backend.dart`
    - Isoleer preview/apply consistency-validatie in een dedicated validator of workflow service zodat transportcode kleiner en eenduidiger wordt.
    - Houd compile/apply retry en observability consequent centraal in gedeelde services in plaats van deels in backendimplementaties.
  - `lib/features/mirror/private_grpc_backend.dart`
    - Behoud de production TLS guard, maar verplaats gedeelde secure-apply flow nog verder naar één pad zodat cloud en private backends minder gedrag dupliceren.
  - `server/mirror-shared/lib/http_gateway.dart`
    - Trek payload-validatie en structured error contract strakker gelijk met de edge gateway, zodat cloud/local runtimes minder uiteenlopend falen.
  - `server/mirror-shared/lib/runner_service.dart`
    - Breid metrics hooks uit naar duidelijke counters voor auth deny, timeout, queue pressure en cleanup health, zodat Fly/local operations beter vergelijkbaar worden.

- Toevoegingen (nieuwe bestanden/features met korte beschrijving)
  - `lib/features/mirror/services/mirror_gateway_request_schema.dart`
    - Centrale request schema/validation laag voor Mirror compile/apply requests, herbruikbaar in edge, tests en eventueel runner-side sanity checks.
  - `lib/features/mirror/services/mirror_launch_coordinator.dart`
    - Uniforme coordinator voor route, deep link en AI bridge launches zodat modekeuze, guard sequencing en session bootstrap niet verspreid blijven.
  - `lib/features/mirror/widgets/mirror_patch_review_sheet.dart`
    - Uitgebreidere staged review UI voor multi-file apply met skip/apply per file of patchblok.
  - `test/features/mirror/mirror_gateway_schema_validation_test.dart`
    - Testset voor request-schema, structured errors en invalid payload-handling.
  - `test/features/mirror/mirror_launch_flow_test.dart`
    - Testset die route/deeplink/AI bridge toegangspaden naast elkaar valideert zodat guard drift sneller zichtbaar wordt.
  - `test/features/mirror/mirror_templates_staleness_test.dart`
    - Testset voor cache TTL, version mismatch en fallback-warning gedrag in templates provider.
  - `docs/mirror_operational_runbook.md`
    - Concreet runbook voor gateway env vars, runner deployment, incident response, idempotency cleanup, artifact cleanup en entitlement-debugging.
  - `docs/mirror_threat_model.md`
    - Threat model voor prompt injection, artifact leakage, privilege escalation, signed URL misbruik en admin bypass governance.
  - `supabase/functions/mirror-gateway/modules/`
    - Verdere granularisatie van bestaande gateway modules zodat de thin-proxy intent ook structureel afdwingbaar blijft.

- Verwijderingen (wat weg kan en waarom)
  - `lib/core/providers/mirror_provider.dart` als compat/shim-laag
    - Gefaseerd weghalen zodra afhankelijkheden zijn omgezet naar directere providers/services. Dit vermindert indirectie en maakt state-eigenaarschap duidelijker.
  - `lib/features/mirror/services/mirror_editor_orchestration_service.dart` (VERWIJDERD)
    - Dit was al een `@Deprecated` shim die verwees naar `mirrorInteractiveRunCoordinatorProvider`. Verwijderd in refactoring PR1; echte flow-logica zit in `mirror_run_flow_service.dart`.
  - Dubbele validatie- en foutmappingspaden tussen `supabase/functions/mirror-gateway/index.ts` en `server/mirror-shared/lib/http_gateway.dart`
    - Niet alles hoeft twee keer handmatig gevalideerd te worden. Gedeelde schema- of contractlogica verlaagt drift.
  - Niet-essentiële fallback-indirectie in launch flows via `lib/core/providers/ai_chat_provider.dart`
    - Zodra een centrale launch coordinator bestaat, kan deze bridge dunner of deels verwijderd worden.
  - Oude of tijdelijke compat-patronen rond orchestration en backend workflow helpers
    - Alles wat alleen nog bestaat om eerdere iteraties te ondersteunen maar geen unieke productwaarde meer levert, moet weg om Mirror beheersbaar te houden.

---

## Execution Summary: Orchestration Refactoring (Completed)

The recommendations above have been executed in three coordinated PRs to address the orchestration weakness identified in the assessment.

### PR1: Remove Deprecated Shim
- **Deleted**: `lib/features/mirror/services/mirror_editor_orchestration_service.dart` (6-line deprecated wrapper)
- **Updated**: Test files to reference correct implementation file
- **Impact**: Removed confusion from duplicate/alias services

### PR2: Extract Consistency Validation to Dedicated Service
- **Created**: `lib/features/mirror/services/mirror_apply_validator_service.dart`
  - Centralized compile fingerprint + context snapshot validation
  - Pure domain service (no IO, no side-effects)
  - Returns structured `ValidateConsistencyResult` enum
  
- **Removed from backends**:
  - `mirror_gateway_backend.dart`: Deleted `_validatePreviewApplyConsistency()` + `_fingerprintFileMap()` (moved validation only)
  - `private_grpc_backend.dart`: Updated to call centralized validator service
  
- **Impact**: Eliminated duplication across HTTP and gRPC backends; consistency checks now single source of truth

### PR3: Consolidate Patch Planning Services
- **Merged**: `mirror_patch_pipeline_service.dart` → `mirror_backend_workflows.dart`
  - Moved all patch planning methods (`prepareCompilePlan`, `prepareApplyPlan`)
  - Moved data classes (`MirrorCompilePatchPlan`, `MirrorApplyPatchPlan`)
  - Pipeline was thin orchestrator wrapper over workflows—consolidation justified

- **Updated**: 
  - `mirror_run_flow_service.dart`: Direct calls to workflows methods instead of pipeline indirection
  - Contract tests to reference consolidated location
  
- **Impact**: Reduced service count (7 → 5), eliminated indirection layer

### PR4 & PR5: Streamline BackendWorkflows (Follow-up Optimizations)
- **Created**: `lib/features/mirror/services/mirror_apply_audit_service.dart`
  - Extracted audit history persistence logic from BackendWorkflows
  - Leaves BackendWorkflows focused on patch/plan logic only
  
- **Removed from BackendWorkflows**:
  - `persistApplyToHive()` → moved to MirrorApplyAuditService
  - `buildFullContext()` → not commonly used; direct calls to MirrorPromptBuilderService
  - Unused imports: `MirrorAuditHistoryService`, `MirrorPromptBuilderService`

- **Updated backends** to use new service:
  - `mirror_gateway_backend.dart`: Now calls `_mirrorAudit.persistApplyToHive()`
  - `private_grpc_backend.dart`: Now calls `_mirrorAudit.persistApplyToHive()`

- **Impact**: BackendWorkflows reduced by ~100 LOC, now focused on patches + planning only (~770 lines)

### Code Quality Validation
- **Flutter analyze**: ✅ No errors (latest run clean)
- **Architecture**: Cleaner separation with consistent responsibilities:
  - Orchestrator = retry + outbox + cache invalidation
  - RunFlow = UI interaction + session state
  - BackendWorkflows = patches + planning (core logic)
  - ApplyValidator = consistency checks (pure domain)
  - ApplyAudit = persistence + history recording
  - Backends = transport adapters only

### Remaining Optimization Opportunities (Future)
- Move cache invalidation from orchestrator to dedicated post-apply hooks service
- Extract shared request schema validation (edge gateway ↔ local runtime)
- Extract apply security-mode decision logic from gateway backend → orchestrator
- Add gateway/runner operation runbook and threat model
- Extend template staleness signaling in providers

## Execution Checklist: State Hydration Hardening

- [x] Leg één expliciete eigenaar vast voor user-facing Mirror state in [lib/core/providers/mirror_provider.dart](lib/core/providers/mirror_provider.dart)
- [x] Vervang side-effectful variant hydration door pure snapshot- en resolverlogica in [lib/core/providers/mirror_state_resolver.dart](lib/core/providers/mirror_state_resolver.dart)
- [x] Voeg generation guards toe zodat late async completions geen stale state meer kunnen overschrijven in [lib/core/providers/mirror_provider.dart](lib/core/providers/mirror_provider.dart)
- [x] Maak `mirrorModeProvider` en `mirrorOfflineWarningProvider` afgeleide read-only providers op basis van de centrale mirror state in [lib/core/providers/mirror_provider.dart](lib/core/providers/mirror_provider.dart)
- [x] Haal cross-provider warning writes uit de team- en runner-variant hydration in [lib/core/providers/mirror_provider.dart](lib/core/providers/mirror_provider.dart)
- [x] Centraliseer mode resolution via één deterministische precedence-regel: requested mode → cached mode → feature flags → premium → runner variant in [lib/core/providers/mirror_state_resolver.dart](lib/core/providers/mirror_state_resolver.dart)
- [x] Splits session bootstrap-merge uit naar een pure merge policy in [lib/core/providers/mirror_session_bootstrap.dart](lib/core/providers/mirror_session_bootstrap.dart)
- [x] Vervang parallelle draft/repository writes door één guarded bootstrap run in [lib/core/providers/mirror_session_provider.dart](lib/core/providers/mirror_session_provider.dart)
- [x] Stop met globale mode/warning mutaties vanuit session hydration in [lib/core/providers/mirror_session_provider.dart](lib/core/providers/mirror_session_provider.dart)
- [x] Recompute context fingerprint pas na de definitieve bootstrap-merge in [lib/core/providers/mirror_session_provider.dart](lib/core/providers/mirror_session_provider.dart)
- [x] Voeg pure unit tests toe voor hydration precedence en bootstrap merge ordering in [test/core/providers/mirror_state_resolver_test.dart](test/core/providers/mirror_state_resolver_test.dart) en [test/core/providers/mirror_session_bootstrap_test.dart](test/core/providers/mirror_session_bootstrap_test.dart)
- [x] Voeg gerichte provider-level tests toe voor auth-switch, premium-switch en session-key invalidation met gecontroleerde async voltooiingsvolgorde
- [x] Verplaats Mirror launch-initialisatie uit [lib/core/providers/ai_chat_provider.dart](lib/core/providers/ai_chat_provider.dart) naar een dedicated launch coordinator zodat launch sequencing niet meer verspreid blijft
- [x] Maak hydration provenance zichtbaar in state of diagnostics (`source`, `fallbackReason`, `hydrationPhase`) voor eenvoudiger incidentanalyse en support

## Changelog: State Hydration Hardening

- Introduced deterministic hydration resolver and provenance metadata for Mirror core state.
- Added generation-guarded async hydration to prevent stale completion overwrites.
- Split session bootstrap merge policy into a pure helper with explicit phase/source outputs.
- Added launch coordinator and reduced ai-chat launch provider to bridge behavior only.
- Added targeted race-condition tests for auth-switch, premium refresh overlap, and session-key bootstrap isolation.

## Changelog: State Hydration Hardening (Pass 2)

- Added repository bootstrap timeout guard in session hydration with configurable timeout provider and degraded fallback behavior.
- Added explicit timeout fallback message to improve diagnosability when repository bootstrap exceeds startup budget.
- Implemented coalesced Mirror refresh orchestration to collapse overlapping refresh requests into latest-wins replay.
- Moved refresh invalidation into the effective coalesced refresh run to avoid premature invalidation during in-flight work.
- Guarded post-refresh persistence side effects (`saveMode`) so stale generations cannot write cache state.
- Added new regression coverage for repository timeout degradation and overlapping premium refresh coalescing.