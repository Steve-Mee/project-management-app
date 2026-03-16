### 1. Algemene beoordeling
- Sterke punten
  - De architectuur is inhoudelijk sterk opgezet en grotendeels clean uitgevoerd. De kernscheiding klopt: `MirrorEditorScreen` is vooral UI-wiring, `mirror_provider.dart` beheert policy en backend-selectie, `MirrorComputeBackend` abstraheert transport, `supabase/functions/mirror-gateway/index.ts` blijft thin proxy, en de runners doen het echte compute-werk.
  - De Supabase-laag is bovengemiddeld goed gehard. `ai_sessions`, `mirror_templates`, `mirror_request_idempotency`, `mirror_usage_logs` en de storage-buckets `mirror-signed-inputs` en `mirror-backups` hebben duidelijke owner-scoped policies, retention helpers en indexes.
  - De feature is niet als los eiland gebouwd. Mirror haakt netjes in op bestaande permissies, task/project-flow, Riverpod, realtime, Hive en de huidige navigatie via `openMirrorFromTask` in `lib/core/providers/ai_chat_provider.dart`.
  - Offline-first is serieus genomen. De combinatie van encrypted Hive-cache, replayable outbox, budget enforcement en connectivity-triggered replay is productiegericht en duidelijk beter dan een simpele “retry later”-implementatie.
  - Testing en documentatie zijn opvallend volwassen voor een nieuwe feature. Er is contracttest-dekking rond gateway, realtime-deduplicatie, permission guards, output parsing, outbox-encryptiebeleid en integratiegedrag, plus ondersteunende docs zoals `docs/mirror-architecture.md`, `docs/mirror-threat-model.md` en `docs/mirror-ops-runbook.md`.

- Zwakke punten
  - De zwaarste bevinding is dat cloud-toegang nu vooral client-side op premium wordt afgedwongen. In `lib/core/providers/mirror_provider.dart` en `lib/core/services/mirror_premium_service.dart` wordt cloud-mode beperkt tot premium users, maar `supabase/functions/mirror-gateway/index.ts` controleert alleen `use_mirror` en geen premium entitlement. Dat is een business-rule bypass voor iedereen die de edge function direct aanroept met een geldige sessie en permissie.
  - Rollout-control is nog niet volledig aangesloten op de bestaande codebase-conventies. In de rest van de app bestaat een feature-flag-infrastructuur (`featureFlagProvider`), maar Mirror runtime-code gebruikt die niet. Daardoor ontbreekt een echte server- en client-side kill switch voor controlled rollout.
  - De apply-flow is veilig maar duur. Zowel `MirrorGatewayBackend.apply()` als `PrivateGrpcBackend.apply()` doen extra compile/preflight-werk om preview/apply-consistentie af te dwingen. Functioneel correct, maar latency, compute-kosten en runnerbelasting lopen hierdoor onnodig op.
  - De editor-sessie is offline-bestendig voor queued operations, maar niet voor lokale drafts. `lib/core/providers/mirror_session_provider.dart` hydrateert context uit project/task-data, maar persistente draftopslag voor onopgeslagen editorwijzigingen ontbreekt. Bij app-herstart verlies je dus sessiestaat die nog niet applied is.
  - Er zitten een paar maintainability-signalen in de implementatie: een ongebruikte `servicePath` property in `lib/features/mirror/private_grpc_backend.dart`, dubbele statuscommunicatie via snackbar/terminal/live output, en een verwarrende splitsing tussen server-side audit events en lokale Hive apply-history.

- Overall score (1-10)
  - 8.4/10. Architectonisch sterk, security- en reliability-bewust, goed geïntegreerd en testbaar. Nog niet volledig productie-hard door ontbrekende server-side premium enforcement, rollout gating en draft persistence.

### 2. Laag-voor-laag analyse
- Supabase / Database laag
  - `supabase/migrations/20260310_create_ai_sessions_baseline.sql` is een goede baseline: idempotent, met trigger voor `updated_at`, goede constraints en een strakke owner-policy via `FOR ALL` op `auth.uid() = user_id`.
  - `supabase/migrations/20260309_mirror_templates_rls_and_sync.sql` is netjes DB-first opgezet. Dat past goed bij een beheerbare catalogus van templates en voorkomt dat UI of seed-code de facto source of truth wordt.
  - `supabase/migrations/20260310_mirror_request_idempotency.sql` en `supabase/migrations/20260311_mirror_idempotency_status_alignment.sql` laten zien dat idempotency serieus is genomen. Dat is cruciaal voor apply-operaties.
  - `supabase/migrations/20260308_mirror_storage_hardening.sql` is sterk: private buckets, owner-folder enforcement via `storage.foldername(name)[1] = auth.uid()::text`, cleanup-functie en pg_cron integratie.
  - `supabase/migrations/20260308_mirror_audit_and_ai_sessions_retention.sql` en `supabase/migrations/20260311_mirror_usage_metering.sql` voegen precies de tabellen toe die je in productie nodig hebt: auditability, retention en usage metering.
  - Zwak punt: deze laag is goed ontworpen maar operationeel nog niet helemaal “closed loop”. `docs/mirror-production-readiness-checklist.md` laat expliciet zien dat staging dry-runs, rollback-SQL, verificatiescripts en een deel van de release-gates nog openstaan. De schema-laag is dus sterker dan de deployment-discipline eromheen.

- Edge Functions & gRPC backend laag
  - `supabase/functions/mirror-gateway/index.ts` is inhoudelijk één van de sterkste onderdelen van de implementatie. De function valideert auth, normalizeert requests, begrenst payloads, claimt en finalizet idempotency, doet stale-claim recovery, stuurt structured errors terug en blijft trouw aan het thin-proxy principe.
  - `lib/features/mirror/mirror_gateway_backend.dart` is technisch degelijk: retry policy, timeout handling, compile/apply consistency checks, secure apply metadata forwarding en observability hooks zijn aanwezig.
  - `lib/features/mirror/private_grpc_backend.dart` volgt hetzelfde contract netjes en houdt de Flutter-side transportwissel klein. Dat is goed voor maintainability.
  - De shared runner code in `server/mirror-shared/lib/http_gateway.dart`, `runner_service.dart` en `compile_runner.dart` toont verstandige grenzen rond workspace size, file count en execution windows. Dat helpt zowel security als performance.
  - Grootste zwakte in deze laag: server-side cloud entitlement ontbreekt. De gateway valideert `use_mirror`, maar niet of een gebruiker ook cloud-mode mag gebruiken. Daardoor is cloud-access geen echte server-enforced business rule.
  - Tweede zwakte: de private gRPC-backend is impliciet “localhost dev only”, maar dat contract is niet scherp genoeg gecodeerd. `ChannelCredentials.insecure()` en een ongebruikte `servicePath` property maken de intentie diffuser dan nodig.

- Dart/Flutter core & providers laag
  - `lib/core/providers/mirror_provider.dart` combineert mode policy, premium state, A/B varianten, offline cache en backend-selectie op een logische manier. De file doet veel, maar wel op een samenhangende plek.
  - `lib/core/services/mirror_premium_service.dart` is goed opgezet: deduplicatie van in-flight requests, TTL-cache met jitter, auth-state refresh en fallback van app metadata naar subscriptions-tabel zijn volwassen keuzes.
  - `lib/core/providers/ai_chat_provider.dart` is een nette bridge en voorkomt duplicated launch-logic in task- en projectschermen.
  - `lib/core/providers/mirror_session_provider.dart` is slim in hoe het project- en task-context omzet naar editor-bestanden (`README.md`, `context/*.json`, `context/current_task.md`). Dat is consistent met het domein van deze app.
  - Zwak punt: `mirror_session_provider.dart` bewaart runtime edits niet duurzaam. Dat betekent dat Mirror operationeel offline-first is voor queued backend-acties, maar niet offline-first voor de editor zelf.
  - Zwak punt: Mirror gebruikt A/B testing wel, maar integreert de bestaande feature-flag infrastructuur niet in de runtime-laag. Daardoor wijkt deze feature af van de bredere codebase-conventie rond rollout governance.

- UI & UX laag (editor, dialogs, realtime)
  - `lib/features/mirror/mirror_editor_screen.dart` is ondanks de scope verrassend beheersbaar gebleven. Realtime-subscriptie, run lifecycle en orchestration zijn uit de widget geëxtraheerd. Dat is een duidelijke clean-architecture winst.
  - `lib/features/mirror/services/mirror_editor_realtime_controller.dart` en `mirror_realtime_service.dart` zijn goed doordacht. Scope filtering, debounced flush, FIFO dedup en caps op lines/chars beschermen de UI tegen noisy of oversized realtime payloads.
  - `lib/features/mirror/services/mirror_editor_orchestration_service.dart` is inhoudelijk sterk: generate, preview, compile fingerprint, apply dialog en patch application hangen logisch aan elkaar.
  - `lib/features/mirror/templates_gallery.dart`, `apply_dialog.dart` en de Monaco hosts maken de feature UX-volwassen; het voelt niet als een proof-of-concept maar als een echte productfeature.
  - Zwak punt: er is nog te veel dubbele statuspresentatie. Dezelfde gebeurtenis kan in snackbar, terminal en live output verschijnen. Dat maakt UX-consistentie en toekomstige onderhoudslast slechter.
  - Zwak punt: `_selectedMode` in `mirror_editor_screen.dart` shadowt provider-state. De code synchroniseert dit wel in `build()`, maar het blijft onnodige state-duplicatie.

- Security, permissions & premium checks
  - Permission gating is op meerdere niveaus aanwezig en dat is goed: UI-gate via `hasPermissionProvider(AppPermissions.useMirror)`, launch bridge, gateway permission RPC en owner-scoped RLS op data- en storage-laag.
  - De signed-input- en backup-flow in `mirror_secure_apply_service.dart` is inhoudelijk sterk. De object-paths zijn owner-prefixed, TTL is kort en artifacts zijn expliciet gekoppeld aan `projectId`, `taskId` en `backupId`.
  - De idempotency-aanpak in de gateway is een echt sterk punt. Vooral stale-claim takeover en finalize-ownership guard zijn precies de details die veel teams overslaan.
  - Grootste security/business-gap: premium gating voor cloud is niet server-side enforced. Een client mag cloud niet selecteren zonder premium, maar de server valideert dat niet nogmaals. Voor een betaalde compute-feature is dat niet voldoende.
  - Tweede aandachtspunt: als private gRPC ooit meer wordt dan localhost-development, dan zijn `ChannelCredentials.insecure()` en het ontbreken van een expliciet runner trust model onvoldoende.

- Offline / Hive / caching laag
  - `lib/features/mirror/services/mirror_outbox_replay_service.dart` is sterk gebouwd. Encrypted Hive, fail-closed in productie, budget enforcement, backoff+jitter, replay ticker en connectivity listeners maken dit tot een serieuze offline-laag.
  - De premium- en variant-caches in `mirror_provider.dart` plus `mirror_premium_service.dart` zijn netjes afgestemd op auth/premium veranderingen. Dat voorkomt onnodige netwerkbelasting.
  - `mirror_secure_apply_service.dart` en `mirror_audit_history_service.dart` laten zien dat lokale artefact- en auditondersteuning bewust is ontworpen, niet ad hoc.
  - Zwak punt: de offline-architectuur is beter voor operations dan voor auteurschap. Queueing en replay zijn goed, maar conceptueel verwacht je van een editorfeature ook draft persistence en recovery van onopgeslagen bestandstoestand.
  - Zwak punt: de secure apply flow uploadt en signeert elk bestand twee keer, voor input en backup. Dat is veilig maar wordt op schaal duur in storage API-calls, uploadvolume en latency.

- Integratie met bestaande app
  - De integratie in `lib/features/project/project_detail_screen.dart` en `lib/features/project/expandable_task_card.dart` is consistent. Beide gebruiken exact dezelfde bridge en openen exact dezelfde `MirrorEditorScreen`.
  - Mirror past goed in bestaande paden: permissies, Supabase-auth, Riverpod, realtime, Hive en project/task repositories worden hergebruikt in plaats van omzeild.
  - De contextinjectie in `mirror_session_provider.dart` sluit logisch aan op het productdomein van deze app. Mirror werkt hier als AI coding studio bovenop project- en taskcontext, niet als generieke IDE voor de volledige app-repo.
  - Zwak punt: juist omdat Mirror breed integreert met permissies, subscriptions, storage, runners, realtime en offline-caching, is de regressie-impact hoog. Zonder sterkere end-to-end gates in CI blijft deze feature relatief risicovol om verder te versnellen.
  - Zwak punt: qua governance is Mirror nog niet volledig consistent met de rest van de codebase, omdat de bestaande feature-flag infrastructuur niet de eerste-class rolloutlaag voor Mirror is geworden.

### 3. Concrete aanbevelingen
- Wijzigingen (met exacte bestandsnamen en wat te veranderen)
  - `supabase/functions/mirror-gateway/index.ts`
    - Voeg server-side entitlementcontrole toe voor cloud-mode. Controleer niet alleen `use_mirror`, maar ook of de gebruiker cloud compute mag gebruiken op basis van subscription/plan of een dedicated entitlement RPC. Zolang dit ontbreekt, is premium cloudgebruik technisch te omzeilen.
  - `lib/core/services/mirror_premium_service.dart`
    - Behandel deze service expliciet als UX/cache-laag en niet als autorisatielaag. Gebruik hem voor snelle clientbeslissingen, maar documenteer en codeer dat de definitieve cloud-authorisatie server-side gebeurt.
  - `lib/core/providers/mirror_provider.dart`
    - Integreer Mirror met de bestaande feature-flag infrastructuur (`featureFlagProvider`) zodat de feature kill-switch, staged rollout en eventueel quota-varianten niet alleen via A/B testing of permissies lopen.
  - `lib/core/providers/mirror_session_provider.dart`
    - Voeg persistente draftopslag per sessie toe in Hive. Bewaar minimaal `files`, `selectedFile` en een timestamp, en herstel die bij app-herstart voordat repository-context opnieuw wordt opgebouwd.
  - `lib/features/mirror/services/mirror_editor_orchestration_service.dart`
    - Verminder dubbele compile-stappen door preview/apply te koppelen aan een expliciete server-side `serverVersionToken` of vergelijkbare immutable preview token. De huidige aanpak is correct maar duur.
  - `lib/features/mirror/mirror_gateway_backend.dart`
    - Haal gedeelde retry-, timeout- en apply-preflightlogica verder uit elkaar zodat compile/apply niet elk een bijna parallel pad onderhouden. Dat verlaagt onderhoudslast en maakt foutgedrag consistenter.
  - `lib/features/mirror/private_grpc_backend.dart`
    - Verwijder de ongebruikte `servicePath` property en maak de local-only intent explicieter. Voeg desnoods een assert of named constructor toe die duidelijk maakt dat deze backend alleen voor localhost/dev bedoeld is.
  - `lib/features/mirror/mirror_editor_screen.dart`
    - Verwijder de lokale `_selectedMode` shadow state en laat de selector rechtstreeks op provider-state draaien. Dat versimpelt de widget en voorkomt subtiele state drift.
  - `lib/features/mirror/services/mirror_secure_apply_service.dart`
    - Evalueer of backup signed URLs echt vooraf nodig zijn. Voor apply zelf lijken input URLs en backup object writes voldoende; backup download signing kan on demand later. Dat bespaart storage-calls en verkleint het lekoppervlak.
  - `lib/features/mirror/services/mirror_audit_history_service.dart`
    - Maak de scheiding duidelijk tussen lokale apply-history en server-side audit trail. De naam en eventsemantiek suggereren nu deels hetzelfde, terwijl het twee verschillende waarheidsbronnen zijn.

- Toevoegingen (nieuwe bestanden/features met korte beschrijving)
  - `supabase/migrations/20260316_mirror_cloud_entitlement_rpc.sql`
    - Nieuwe RPC of view-laag die server-side bepaalt of een gebruiker cloud Mirror mag gebruiken, gebaseerd op permissies en actieve subscription/plan.
  - `test/features/mirror/mirror_cloud_entitlement_bypass_test.dart`
    - Contracttest die valideert dat een gebruiker zonder premium via directe gateway-aanroep geen cloud-mode mag gebruiken.
  - `test/features/mirror/mirror_feature_flag_gate_test.dart`
    - Test dat Mirror netjes blokkeert of fallbackt wanneer de feature via de bestaande feature-flag infrastructuur wordt uitgezet.
  - `test/features/mirror/mirror_editor_draft_persistence_test.dart`
    - Widget/service test voor durable draft recovery na app-herstart of provider dispose/rebuild.
  - `test/supabase/mirror_entitlement_contract.sql`
    - SQL-contracttest voor de nieuwe entitlement-RPC of entitlement-view, inclusief premium/non-premium scenario's.
  - `lib/features/mirror/services/mirror_draft_cache_service.dart`
    - Nieuwe service die sessiedrafts veilig serialiseert naar Hive, met caps op bestandsgrootte en total payload.
  - `docs/mirror-component-map.md`
    - Kort, canoniek overzicht van Mirror componenten, backends, buckets, RPC’s en verantwoordelijkheden. Dit voorkomt drift tussen prompts, docs en implementatie.
  - `docs/mirror-rollout-plan.md`
    - Praktisch rollout-document met kill-switch, canary-strategie, metrics en rollbackbeslissingen specifiek voor Mirror.

- Verwijderingen (wat weg kan en waarom)
  - `lib/features/mirror/private_grpc_backend.dart`
    - Verwijder de ongebruikte `servicePath` property. Het is dode configuratie die de API groter maakt zonder functionele waarde.
  - `lib/features/mirror/mirror_editor_screen.dart`
    - Verwijder de lokale `_selectedMode` state zodra provider-driven selection volledig is doorgetrokken. Dit scheelt synchronisatielogica en maakt de UI eenvoudiger.
  - `lib/features/mirror/services/mirror_secure_apply_service.dart`, `lib/features/mirror/mirror_compute_backend.dart` en `lib/features/mirror/services/mirror_audit_history_service.dart`
    - Verwijder eager generatie en doorgesleepte `backupSignedUrls` als die alleen nog voor lokale history-fingerprints worden gebruikt. Bewaar in dat geval liever backup paths of backup ids en signeer pas bij expliciete restore/download.
  - Dubbele Mirror-statusberichten over snackbar, terminal en live output
    - Verwijder de minder waardevolle duplicaten en kies per gebeurtenistype één primaire statusroute. Dit reduceert UX-ruis en onderhoud.
  - Overlappende documentatie die hetzelfde thin-proxy verhaal op meerdere plekken opnieuw vertelt
    - Verwijder duplicaatuitleg en verwijs vanuit runbooks/checklists naar `docs/mirror-architecture.md` als canonieke bron. Dat houdt de documentatieset lichter en consistenter.
