# Mirror Feature - Comprehensive Architecture Analysis

**Analysis Date**: March 18, 2026  
**Overall Implementation Status**: **Mature, production-ready with minor refinements needed**

---

## 1. Algemene beoordeling

### Sterke punten

1. **Architectuur Lock & Clarity**
   - Clear separation: Gateway = thin proxy only; Compute = Fly.io/local runner only
   - No compute logic leaks into gateway—excellent architectural discipline
   - Provider-driven mode selection (private/cloud) with fallback strategy
   - Offline-first caching strategy with Hive for draft, templates, and outbox

2. **Security & RLS**
   - Strong RLS policies on storage buckets (`mirror-signed-inputs`, `mirror-backups`)
   - Owner-scoped path validation: `storage.foldername(name)[1] = auth.uid()`
   - Idempotency table with claim/finalize pattern prevents replay attacks
   - 7-day lifecycle cleanup for signed URL artifacts
   - Premium service hint cache non-authoritative; server-side authoritative
   - Bearer JWT validation at gateway and runner layers

3. **Offline & Caching**
   - Multi-layer caching: draft cache, templates cache, outbox with replay
   - Encrypted Hive storage for sensitive data (drafts, audit history)
   - Graceful fallback: offline warning + cached variant fallback
   - Contextual budget enforcement (file count, byte size, char limits)
   - Circulating dedup queue for realtime events (FIFO-bounded)

4. **Error Handling & Observability**
   - Structured telemetry via `MirrorObservabilityService`
   - Deterministic retry policy with exponential backoff
   - Comprehensive threat model documentation
   - RLS contract tests and idempotency contract tests
   - Permission-based access gating (use_mirror, manage_templates)

5. **User Experience**
   - Smooth editor/terminal/live output UI wiring
   - Diff preview dialog with git branch suggestion
   - Template gallery with icon/tag filtering
   - Permission revocation handler (immediate screen lock-out)
   - Voice input support (speech-to-text integration)

6. **Code Quality**
   - Consistent module boundaries (features/mirror)
   - Extracted service responsibilities (not monolithic screen)
   - Comprehensive model layer with type safety
   - JSON encoding/decoding with fallback safety checks
   - Clear documentation of data contracts

### Zwakke punten

1. **Type Safety & Compile-Time Guards**
   - `ProjectContext.metadata` is `Map<String, dynamic>`—no type-safe schema
   - Unvalidated metadata access in prompt builder can silently fail
   - gRPC request marshalling manually serializes metadata to JSON string
   - No compile-time validation of template seed_content structure

2. **Distributed Request Tracing**
   - No request-id/trace-id propagation from client → gateway → runner
   - Observability service logs events but not linked across layers
   - Difficult to trace single compile/apply through full pipeline in logs

3. **Error Recovery & Resilience**
   - Outbox replay policy not fully documented (retry count limits, backoff)
   - No circuit breaker pattern for repeated runner failures
   - Timeout defaults (30s) not tuned for all scenarios (large contexts)
   - Failed signed URL generation not gracefully downgraded

4. **Test Coverage Gaps**
   - Widget tests for MirrorEditorScreen need platform fallback for inappwebview
   - Integration tests for compile→apply consistency not comprehensive
   - No test cases for concurrent apply requests or race scenarios
   - Template sync seed function not tested against schema version mismatch

5. **Documentation Gaps**
   - Production readiness checklist file exists but is nearly empty
   - Operations runbook incomplete (no deployment, monitoring, incident response sections)
   - No clear SLA or uptime targets documented
   - Dedup behavior and limits (maxProcessedRealtimeEventIds) not well explained

6. **Performance Edge Cases**
   - No batch compile support (only single-file operations)
   - Large context (300 files, 400 KB) may timeout or OOM on weak devices
   - Realtime dedup queue size (2000 events) can become memory-intensive
   - Audit history persists up to 40 entries per session (unbounded growth risk)

7. **Permissions & Feature Flags**
   - `use_mirror` permission checked but no granular controls (e.g., private-only, cloud-only)
   - Feature flag `mirror_enabled` checked via slow future provider on every request
   - No override mechanism for admin testing (feature-flag bypass)
   - Premium check is client-side hint; no server-side enforcement for private mode cost limits

8. **Offline Mode Transitions**
   - Fallback variants (solo → team, cloud → private) not transparent to user intent
   - Offline warning displayed but not actionable (user cannot retry online)
   - Outbox replay does not preserve user's requested mode preference

### Overall Score: **7.8/10**

- **Strengths (50%)**: Excellent architecture, security, caching, observability = **8.2/10**
- **Weaknesses (50%)**: Type safety, tracing, error recovery, gaps in docs/tests = **7.4/10**

**Verdict**: Production-ready for v1 launch. Monitoring and refinement needed post-launch for distributed tracing, test hardening, and performance tuning.

### 2. Laag-voor-laag analyse
- Supabase / Database laag: sterk opgezet met `ai_sessions`, `mirror_templates`, `mirror_apply_audit_events`, `mirror_request_idempotency` en `mirror_usage_logs`. De migraties laten zien dat Mirror niet alleen functioneel is toegevoegd, maar ook lifecycle, audit en abuse/billing-signalen meeneemt.
- Supabase / Database laag: `ai_sessions` is correct voorzien van owner-only RLS, `updated_at` trigger en realtime broadcast trigger. De keuze voor `project_id` en `task_id` als tekstvelden zonder relationele foreign keys houdt de laag losjes gekoppeld, maar laat ook ruimte voor orphaned of semantisch ongeldige sessies als upstream validatie faalt.
- Supabase / Database laag: `mirror_templates` is onderhoudbaar opgezet. DB-first seed sync met `seed_managed` is een goede keuze voor catalogusbeheer en maakt drift tussen seed-data en runtime leesbaar.
- Supabase / Database laag: storage hardening voor `mirror-signed-inputs` en `mirror-backups` is netjes owner-scoped op padsegmentniveau. Dat is pragmatisch en effectief, mits padvorm contractueel stabiel blijft.
- Supabase / Database laag: de eerder risicovolle idempotency-drift is inmiddels opgevangen door align-migraties voor `processing`, `expires_at` en response-cache kolommen. Dat is goed opgelost, maar de afhankelijkheid van meerdere opvolgmigraties betekent dat omgevingen met onvolledige migratiehistorie nog steeds een deployment-risico vormen.
- Edge Functions & gRPC backend laag: `supabase/functions/mirror-gateway/index.ts` is inhoudelijk sterk. Auth, permission check, strict cloud entitlement, idempotency claim/finalize, replay van cached responses, timeout handling en structured errors zijn degelijk geïmplementeerd.
- Edge Functions & gRPC backend laag: de architecture lock wordt goed nageleefd. De Edge Function is daadwerkelijk een thin proxy en voert geen compute uit; compute blijft bij local/private runner of cloud runner.
- Edge Functions & gRPC backend laag: `MirrorGatewayBackend` is een nette cloudadapter. Retry policy, latency metrics, idempotency header forwarding en preview/apply consistency checks zijn goed ingebouwd.
- Edge Functions & gRPC backend laag: `PrivateGrpcBackend` is production-safety aware doordat insecure transport in release builds expliciet wordt geblokkeerd. Dat is een belangrijk pluspunt en voorkomt een klassieke “localhost/debug default lekt naar prod”-fout.
- Edge Functions & gRPC backend laag: schaalbaarheidsmatig zit de voornaamste zwakte in gateway-side databaseverkeer voor rate limiting, idempotency claims en entitlement checks. Dat is verantwoord voor lage tot middelhoge load, maar verdient consolidatie zodra Mirror intensiever gebruikt wordt.
- Dart/Flutter core & providers laag: `lib/core/providers/mirror_provider.dart` combineert mode policy, premium status, experimentvarianten, offline warnings en backendselectie coherent. Riverpod wordt hier correct gebruikt, maar het bestand draagt veel verantwoordelijkheid tegelijk.
- Dart/Flutter core & providers laag: `lib/core/services/mirror_premium_service.dart` is sterk opgebouwd met TTL+jitter, in-flight deduplicatie en auth-event refreshes. Dat voorkomt onnodige Supabase-query pieken en houdt entitlementchecks relatief goedkoop.
- Dart/Flutter core & providers laag: `lib/core/providers/mirror_session_provider.dart` is een goede integratielaag naar de rest van de app. Het verrijkt de editorcontext met project-, task- en planinformatie en herstelt lokale drafts zonder de repositorycontext te verliezen.
- Dart/Flutter core & providers laag: `lib/core/providers/ai_chat_provider.dart` biedt een nette bridge naar Mirror vanuit bestaande task/project flows, maar gate alleen op permissie en niet op `mirror_enabled`. Daardoor kan een gebruiker theoretisch nog steeds een disabled feature openen en pas later op een disabled backend stuiten.
- UI & UX laag (editor, dialogs, realtime): `lib/features/mirror/mirror_editor_screen.dart` biedt een rijke feature-set en blijft verrassend beheersbaar doordat veel gedrag gedelegeerd is. De runtime permission revocation flow is netjes defensief en voorkomt doordraaien van een sessie zonder recht.
- UI & UX laag (editor, dialogs, realtime): realtime is goed afgeschermd. `MirrorRealtimeService` cap’t lijnen, debouncet updates, dedupliceert events en scoped records op user/project/task. Dat is de juiste aanpak voor een editorachtig scherm met potentieel veel output.
- UI & UX laag (editor, dialogs, realtime): `ApplyDialog` is functioneel bruikbaar, maar UX-technisch nog beperkt. Het toont een eenvoudige line-by-line diff en een branch-advieskaart, zonder echte unified diff, conflictcontext of live repositorydetectie. De branch-info is dus informatief, niet operationeel.
- UI & UX laag (editor, dialogs, realtime): de titel- en entrypoint-UX is niet helemaal consistent met de productnaam “Mirror”. In l10n staat de editor als “AI Assistant/AI Assistent”, wat de feature-identiteit verwatert en de koppeling met docs/ops minder duidelijk maakt.
- Security, permissions & premium checks: permissies zijn goed meervoudig afgedwongen. `use_mirror` wordt niet alleen UI-side getoond/verstopt, maar ook bij deeplinks en server-side gevalideerd.
- Security, permissions & premium checks: premium enforcement is inhoudelijk goed, maar heeft twee bronnen van waarheid: client-side heuristiek op metadata/subscriptions en server-side RPC-plus-fallback. Dat werkt, maar is lastiger te auditen en testen dan een volledig server-authoritative model.
- Security, permissions & premium checks: `MirrorSecureApplyService` is production-minded. Signed URLs hebben korte TTL, backups krijgen een eigen artifact-id, upload failures worden per bestand vastgelegd, en apply audit events worden zowel lokaal als backend-side ondersteund.
- Security, permissions & premium checks: feature flags zijn minder streng dan permissies. `_isMirrorFeatureEnabled` faalt bewust open bij tijdelijke flag-onbeschikbaarheid. Dat is verdedigbaar voor DX of rollout-stabiliteit, maar voor een gevoelige feature als Mirror hoort er een expliciete productie-optie voor fail-closed of strict mode te zijn.
- Offline / Hive / caching laag: `MirrorOutboxReplayService` is een van de sterkere onderdelen van de implementatie. Persistent queueing, idempotency, connectivity triggers, jittered retries, terminal states en replay success hooks zijn goed uitgewerkt.
- Offline / Hive / caching laag: de draft cache en offline mode in `mirror_provider.dart` zijn bruikbaar en bewust geversioneerd. Caches worden ook op auth- en premiumwijzigingen geïnvalideerd, wat belangrijk is om entitlement leakage via lokale staat te voorkomen.
- Offline / Hive / caching laag: de template-cache heeft integrity-checks en een simpele maar effectieve versioningstrategie. Dat past goed bij read-heavy catalogusdata.
- Offline / Hive / caching laag: fail-open fallback naar onversleutelde Hive-boxen in non-production is pragmatisch, maar vereist discipline in releaseconfiguratie en CI-validatie. Zonder harde release-instellingen blijft dit een potentieel menselijk foutpad.
- Integratie met bestaande app: integratie met project- en taskschermen is schoon gedaan via `openMirrorFromTask`, en apply-success verversing van tasks/subtasks helpt om Mirror-mutaties zichtbaar te maken in bestaande UI.
- Integratie met bestaande app: `main.dart` start de outbox replay worker vroeg tijdens appbootstrap. Dat is consistent met offline-first gedrag, maar voegt ook startupverantwoordelijkheid toe aan de globale app-init. Voor nu acceptabel, maar het is iets om te bewaken als startup verder groeit.
- Integratie met bestaande app: `ProjectsInitializer` gate deep links alleen op permissie, niet op feature flag. Hierdoor is de integratie met het bestaande appnavigatiemodel nog niet volledig in lijn met het feature-flagmodel van de rest van de codebase.
- Integratie met bestaande app: documentatie en runtime zijn niet overal meer in perfecte sync. De codebase hanteert nu `MirrorGatewayBackend` als canonieke cloudimplementatie; oudere niet-canonieke backendnamen horen alleen nog in migratiehistorie of verouderde context voor en verhogen de cognitieve belasting.

### 3. Concrete aanbevelingen
- Wijzigingen (met exacte bestandsnamen en wat te veranderen): `lib/core/providers/ai_chat_provider.dart` `openMirrorFromTask` uitbreiden met een expliciete `mirror_enabled` check zodat feature-flag gating al vóór schermnavigatie gebeurt.
- Wijzigingen (met exacte bestandsnamen en wat te veranderen): `lib/core/projects_initializer.dart` naast permissiecontrole ook feature-flag gating toevoegen voor deeplink-routes die Mirror openen, zodat launch behavior consistent is met backend policy.
- Wijzigingen (met exacte bestandsnamen en wat te veranderen): `lib/features/mirror/mirror_editor_screen.dart` een expliciete disabled-state tonen wanneer Mirror via feature flag is uitgeschakeld, in plaats van indirect via een disabled backendflow.
- Wijzigingen (met exacte bestandsnamen en wat te veranderen): `lib/core/providers/mirror_provider.dart` opdelen in kleinere verantwoordelijkheden, bijvoorbeeld aparte providers/services voor feature flag gating, entitlement resolution en offline cache hydration, zodat policywijzigingen minder regressiegevoelig worden.
- Wijzigingen (met exacte bestandsnamen en wat te veranderen): `lib/core/services/mirror_premium_service.dart` en `supabase/functions/mirror-gateway/index.ts` entitlementlogica harmoniseren rond één server-authoritative contract, met client alleen als cache/hintlaag.
- Wijzigingen (met exacte bestandsnamen en wat te veranderen): `lib/features/mirror/services/mirror_editor_orchestration_service.dart` preview/apply metadata-opbouw centraliseren in één helper of value object zodat context-fingerprint, preview-reuse en compile/apply parity vanuit één bron komen.
- Wijzigingen (met exacte bestandsnamen en wat te veranderen): `lib/features/mirror/apply_dialog.dart` branchadvies koppelen aan echte repositorystatus of de copy explicieter maken dat het slechts een suggestie is; nu oogt het operationeler dan het werkelijk is.
- Wijzigingen (met exacte bestandsnamen en wat te veranderen): `lib/l10n/app_en.arb`, `lib/l10n/app_nl.arb` en overige ARB-bestanden de editorbenaming expliciet op “Mirror” afstemmen als dat de productnaam is, zodat UI, docs en supportterminologie gelijk lopen.
- Wijzigingen (met exacte bestandsnamen en wat te veranderen): `supabase/functions/mirror-gateway/index.ts` entitlement-, rate-limit- en idempotency-gerelateerde querypaden verder consolideren om database round-trips te verminderen bij hogere load.
- Wijzigingen (met exacte bestandsnamen en wat te veranderen): `docs/mirror-architecture.md`, `README.md` en overige Mirror-documentatie alleen nog de canonieke backendnamen `MirrorGatewayBackend` en `PrivateGrpcBackend` laten gebruiken en oude benamingen verwijderen.
- Toevoegingen (nieuwe bestanden/features met korte beschrijving): nieuw testbestand `test/features/mirror/mirror_feature_flag_launch_gating_test.dart` voor task/project launchflows en deeplinks wanneer `mirror_enabled` uit staat.
- Toevoegingen (nieuwe bestanden/features met korte beschrijving): nieuw testbestand `test/features/mirror/mirror_entitlement_parity_test.dart` dat client-side en gateway-side premiumbeslissingen op dezelfde scenario’s valideert.
- Toevoegingen (nieuwe bestanden/features met korte beschrijving): nieuw testbestand `test/features/mirror/mirror_preview_apply_metadata_contract_test.dart` voor fingerprint-, preview-reuse- en context-parity regressies.
- Toevoegingen (nieuwe bestanden/features met korte beschrijving): nieuwe documentatie `docs/mirror_runner_sandboxing_plan.md` met een concreet production-hardeningplan voor job isolation, netwerkrestricties, workspace cleanup guarantees en secrets boundaries.
- Toevoegingen (nieuwe bestanden/features met korte beschrijving): extra runtime telemetry rond stale idempotency claims, entitlement fallbacks en outbox terminal failures, zodat operationele drift sneller zichtbaar wordt.
- Toevoegingen (nieuwe bestanden/features met korte beschrijving): een server-side policy/RPC die project/task ownership of membership valideert voor Mirror-sessies, zodat `project_id` en `task_id` niet alleen syntactisch maar ook domeinmatig worden gevalideerd.
- Verwijderingen (wat weg kan en waarom): verwijderen van verouderde niet-canonieke backendterminologie uit Mirror-documentatie en promptcontext, omdat de runtimearchitectuur nu vaste canonieke namen gebruikt.
- Verwijderingen (wat weg kan en waarom): verwijderen van impliciete productcopy die Mirror als generieke “AI Assistant” labelt, omdat dat verwarring veroorzaakt tussen feature-identiteit, supportdocs en permissie-/billingbeleid.
- Verwijderingen (wat weg kan en waarom): verwijderen van onnodige duplicatie in entitlementfallbacks zodra een server-authoritative premiumcontract is ingevoerd; dubbele beslispaden maken debugging en auditing moeilijker dan nodig.
