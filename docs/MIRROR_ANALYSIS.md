# Mirror Implementatie - Diepgaande Architectuuranalyse

Analyse datum: 20 maart 2026

### 1. Algemene beoordeling
- Sterke punten: Mirror is end-to-end doorgedacht met schema-, policy-, backend-, provider- en UI-lagen die zichtbaar op elkaar aansluiten, inclusief idempotency, audit trail, secure apply artifacts en realtime scoping.
- Sterke punten: De security-baseline is bovengemiddeld sterk voor een AI feature: owner-scoped RLS op tabellen en storage, expliciete permission-gates (`use_mirror`) op launch/screen/gateway, en extra cloud entitlement check server-side.
- Sterke punten: Offline-first principes zijn serieus toegepast met Hive cache, encrypted box fallback-beleid, outbox replay met retry/jitter/circuit breaker, en cache invalidatie op auth/premium mutaties.
- Sterke punten: De apply-flow bevat belangrijke productie-rails: preview->apply fingerprint matching, signed input + backup, risicobevestiging in UI, en audit events.
- Sterke punten: Integratie in bestaande project/task flows is praktisch en coherent via `openMirrorFromTask` en directe editor-navigatie vanuit task- en projectschermen.
- Zwakke punten: `mirror_provider.dart` combineert te veel verantwoordelijkheden (feature flags, premium, AB-varianten, cachehydratatie, backendselectie), wat testbaarheid en change safety verlaagt.
- Zwakke punten: De gateway-idempotency hash gebruikt een 32-bit FNV-variant, wat voor security/finops-kritische deduplicatie onnodig collision-gevoelig blijft.
- Zwakke punten: In `server/mirror-shared/lib/runner_service.dart` wordt dezelfde compile-runner route gebruikt voor zowel compile als apply zonder aparte apply-engine; dat maakt de semantiek van "apply" potentieel ambigu en moeilijker te verifiëren.
- Zwakke punten: `mirror_usage_logs` is als schema aanwezig, maar de write-path is niet duidelijk zichtbaar in de huidige gatewayflow, waardoor metering/billing/abuse-monitoring incompleet kan zijn.
- Overall score (1-10): 8.4/10

### 2. Laag-voor-laag analyse
- Supabase / Database laag: `public.ai_sessions` baseline is sterk opgezet met constraints, indexes, update trigger en owner-policy; dit is clean en consistent met multitenant user-isolation.
- Supabase / Database laag: Realtime broadcast topic hardening (`mirror_ai_sessions:<user>:<project>:<task>`) is goed ontworpen en significant veiliger/schaalbaarder dan brede table listeners.
- Supabase / Database laag: `mirror_templates` is volwassen DB-first ingericht met seed-sync functie, RLS en beheersrechten (`manage_templates`), wat onderhoud en governance ondersteunt.
- Supabase / Database laag: Storage hardening (`mirror-signed-inputs`, `mirror-backups`) met owner-prefix RLS en retention cleanup is correct en productiegericht.
- Supabase / Database laag: Idempotency-migraties (status alignment, `expires_at`, response cache kolommen) laten goede contractdiscipline zien.
- Supabase / Database laag: Risico is dat gateway afhankelijk is van RPC's zoals `has_cloud_mirror_access` en `has_permission`; als deze niet migration-driven in dezelfde delivery zitten ontstaat fragiele deploy-order coupling.

- Edge Functions & gRPC backend laag: `supabase/functions/mirror-gateway/index.ts` volgt het thin-proxy principe met structured errors, action routing (`/compile`/`/apply`), idempotency ledger, retries/timeouts en audit hooks.
- Edge Functions & gRPC backend laag: Request-tracing (`x-request-id`, trace-id) en gestandaardiseerde error families zijn correct voor observability en supportability.
- Edge Functions & gRPC backend laag: `server/mirror-shared/lib/http_gateway.dart` handhaaft payload quota en execution window; dit is een belangrijke DoS/abuse-control.
- Edge Functions & gRPC backend laag: `PrivateGrpcBackend` blokkeert insecure channel credentials in production runtime; dit is een sterke guardrail.
- Edge Functions & gRPC backend laag: Cloud-routing gebruikt env-resolved endpoints in `MirrorGatewayBackend` en thin-proxy gateway. Canonical backends zijn `MirrorGatewayBackend` (cloud) en `PrivateGrpcBackend` (local).
- Edge Functions & gRPC backend laag: Potentieel semantisch risico is dat runner `apply` op dit moment dezelfde compile-flow gebruikt; voor auditbaarheid, rollback en correctness hoort apply een duidelijk eigen contract/pad te hebben.

- Dart/Flutter core & providers laag: `mirror_provider.dart` en `MirrorAccessPolicy` regelen mode resolving (private/cloud), premium-afweging en admin bypass op een duidelijke policy-first manier.
- Dart/Flutter core & providers laag: `mirror_editor_orchestration_service.dart` implementeert een nette generate->compile->preview->confirm->apply pipeline met context-fingerprinting en metadata-overdracht.
- Dart/Flutter core & providers laag: `mirror_premium_service.dart` documenteert expliciet dat client premium alleen hinting is en server de autoriteit blijft; dit is inhoudelijk juist.
- Dart/Flutter core & providers laag: Onderhoudsrisico blijft de hoge coupling in providerlaag (state + policy + caching + backend keuze in een module), wat regressiekans vergroot.
- Dart/Flutter core & providers laag: Feature-flag defaulting is in niet-strict mode fail-open, wat handig is voor development maar risicovoller is voor gecontroleerde rollout van premium AI-functionaliteit.

- UI & UX laag (editor, dialogs, realtime): `mirror_editor_screen.dart` levert een complete studio-ervaring (Monaco, explorer, terminal, live output, templates, voice) en respecteert permissie-revocation tijdens actieve sessie.
- UI & UX laag (editor, dialogs, realtime): `apply_dialog.dart` is functioneel sterk met duidelijke diff-preview, branch-advies en expliciete risicobevestiging.
- UI & UX laag (editor, dialogs, realtime): Realtime pad via `MirrorEditorRealtimeController` + `MirrorRealtimeService` bevat dedupe, truncation caps en debounce, wat memory en UI-jank beheerst.
- UI & UX laag (editor, dialogs, realtime): Grote stateful screen met veel wiring in een bestand maakt toekomstige UX-iteraties duurder en verhoogt kans op side-effect regressies.

- Security, permissions & premium checks: Permission checks zijn op meerdere lagen aanwezig (launch bridge, screen guard, backend RPC checks), wat defense-in-depth versterkt.
- Security, permissions & premium checks: Secure apply artifacts zijn owner-scoped en TTL-beperkt; dit reduceert replay/leak impact.
- Security, permissions & premium checks: Cloud access enforcement server-side (`has_cloud_mirror_access`) voorkomt dat client-side premium hints als autoritatief worden misbruikt.
- Security, permissions & premium checks: Verdere hardening blijft nodig rond idempotency hash-kwaliteit, expliciete key-rotatie procedures en runner sandbox/egress controls op platformniveau.

- Offline / Hive / caching laag: `mirror_offline_cache_provider.dart` toont goede cachehygiëne met schema-versioning, TTL envelopes en invalidatie op auth/premium change.
- Offline / Hive / caching laag: `mirror_outbox_replay_service.dart` past volwassen retry/replay patronen toe inclusief idempotency keys en circuit-breaker gedrag.
- Offline / Hive / caching laag: `mirror_templates_cache.dart` heeft hash-validatie en schema checks die corruptie en stale snapshots netjes afvangen.
- Offline / Hive / caching laag: Het aantal cachelagen (provider memory, Hive, service state) vraagt scherpere ownershipdocumentatie om "stale truth" situaties te vermijden.

- Integratie met bestaande app: Entry points in `project_detail_screen.dart` en `expandable_task_card.dart` gebruiken dezelfde bridge (`openMirrorFromTask`), wat consistent gedrag oplevert.
- Integratie met bestaande app: Integratie blijft afhankelijk van permissie/flag checks uit bestaande auth/feature-flag infrastructuur en is daardoor consistent met app-breed autorisatiebeleid.
- Integratie met bestaande app: Post-apply refresh in orchestrator helpt taak/subtaakweergave synchroon houden met editor acties.
- Integratie met bestaande app: Er is beperkte zichtbaarheid van deep-link integratie specifiek naar Mirror in `main.dart`; huidige deep-link handling lijkt nog gefocust op invitation-flow.

### 3. Concrete aanbevelingen
- Wijzigingen (met exacte bestandsnamen en wat te veranderen): `supabase/functions/mirror-gateway/index.ts` - vervang idempotency request hashing op FNV-1a door SHA-256 (`crypto.subtle.digest`) en sla hash in vast formaat op voor collision-robustheid.
- Wijzigingen (met exacte bestandsnamen en wat te veranderen): `server/mirror-shared/lib/runner_service.dart` - splits compile en apply technisch en semantisch; introduceer aparte apply-executor of markeer endpoint expliciet als preview-only om contractverwarring te voorkomen.
- Wijzigingen (met exacte bestandsnamen en wat te veranderen): `lib/core/providers/mirror_provider.dart` - refactor naar aparte providers voor mode policy, entitlement resolution en cache hydration; behoud publieke API maar verlaag interne coupling.
- Wijzigingen (met exacte bestandsnamen en wat te veranderen): `lib/features/mirror/mirror_editor_screen.dart` - verplaats side-effects (voice, realtime subscription lifecycle, run lifecycle) naar dedicated controller/provider om widget eenvoudiger en beter testbaar te maken.
- Wijzigingen (met exacte bestandsnamen en wat te veranderen): `lib/core/providers/mirror_feature_flag_provider.dart` - maak productiegedrag expliciet fail-closed voor `mirror_enabled` tenzij expliciet override, en log fallback oorzaak voor audits.
- Wijzigingen (met exacte bestandsnamen en wat te veranderen): `lib/core/services/mirror_premium_service.dart` - voeg tri-state entitlement (`unknown`, `free`, `premium`) toe zodat UX niet foutief "free" toont tijdens tijdelijke lookup failures.
- Wijzigingen (met exacte bestandsnamen en wat te veranderen): `server/mirror-shared/lib/http_gateway.dart` - valideer en corrigeer HTTP status mapping voor authz-fouten (`permissionDenied` => 403) en align met edge gateway structured errors.
- Wijzigingen (met exacte bestandsnamen en wat te veranderen): `supabase/functions/mirror-gateway/index.ts` - schrijf compile/apply usage events consistent weg naar `public.mirror_usage_logs` inclusief duur, status, requestId en idempotency key.

- Toevoegingen (nieuwe bestanden/features met korte beschrijving): `supabase/migrations/20260320_mirror_cloud_entitlement_rpc.sql` - migration met definitie + grants + testquery voor `has_cloud_mirror_access` zodat dependency niet impliciet blijft.
- Toevoegingen (nieuwe bestanden/features met korte beschrijving): `supabase/migrations/20260320_mirror_permission_rpc_contract.sql` - contractmigration voor `has_permission` expected behavior in mirror-context (incl. smoke assertions).
- Toevoegingen (nieuwe bestanden/features met korte beschrijving): `test/features/mirror/mirror_gateway_idempotency_hash_test.dart` - regressietest op deterministische hash, collision-baseline en payload-sensitivity.
- Toevoegingen (nieuwe bestanden/features met korte beschrijving): `test/features/mirror/mirror_apply_contract_test.dart` - end-to-end test die expliciet bewijst dat apply-effect niet enkel compile-echo is maar werkelijke file mutations oplevert.
- Toevoegingen (nieuwe bestanden/features met korte beschrijving): `docs/mirror-backend-contracts.md` - canonieke mapping van runtimecomponenten (MirrorGatewayBackend, PrivateGrpcBackend, mirror-gateway, local/cloud runner, buckets) en request/response contracts.
- Toevoegingen (nieuwe bestanden/features met korte beschrijving): `docs/mirror-security-baseline.md` - concrete productie-hardening checklist voor runner isolation (non-root, seccomp/apparmor, readonly rootfs, egress allowlist, CPU/mem quotas, key rotation).

- Verwijderingen (wat weg kan en waarom): verwijder duplicatieve of overlappende entitlement wiring wanneer `mirror_entitlement_provider.dart` geen unieke waarde toevoegt boven `mirror_premium_service.dart` + `mirror_provider.dart`.
- Verwijderingen (wat weg kan en waarom): verwijder legacy/onduidelijke statusstrings of fallback-berichten in Mirror UX die niet aansluiten op huidige structured error families, om support en observability eenvoudiger te maken.
