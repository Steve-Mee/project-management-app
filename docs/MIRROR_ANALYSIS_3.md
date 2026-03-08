### 1. Algemene beoordeling
- Sterke punten
  - Duidelijke lagen en scheiding van verantwoordelijkheden: contract (`lib/features/mirror/mirror_compute_backend.dart`), transport/backends (`lib/features/mirror/edge_function_backend.dart`, `lib/features/mirror/private_grpc_backend.dart`, `lib/features/mirror/cloud_fly_backend.dart`), provider-orchestratie (`lib/core/providers/mirror_provider.dart`) en UI (`lib/features/mirror/mirror_editor_screen.dart`).
  - Security-basis is bovengemiddeld voor een nieuwe feature: owner-scoped storage-RLS, apply-audit schema, idempotency header propagation, JWT/service-token guard in cloud runner.
  - Offline-first intentie is goed uitgewerkt in providerlaag met lokale cache, auth/premium invalidatie en AB fallback.
  - Integratie in bestaande flows is aanwezig op project- en taakniveau (`lib/features/project/project_detail_screen.dart`, `lib/features/project/expandable_task_card.dart`).
- Zwakke punten
  - Endpoint/protocol-matrix is nog fragiel: cloud/local runner exposeert gRPC `Compile`, terwijl applaag ook HTTP `/compile` en `/apply` contracten verwacht. Dit is architectonisch nog niet volledig dichtgetimmerd.
  - `Generate` is in private/cloud backend niet geïmplementeerd, maar contract exposeert het wel; dit verhoogt onderhoudslast en verwarring.
  - Mirror templates bestaan dubbel: statisch in Flutter (`lib/features/mirror/templates_gallery.dart`) en DB-catalog (`supabase_setup.sql`), zonder synchronisatiepad.
  - Realtime feed in editor luistert op `ai_sessions` met filter op `task_id`; dat blijft gevoelig voor noisy updates als task IDs niet strikt uniek zijn over contexten.
  - Supabase schema staat deels in legacy `supabase_setup.sql` en deels in migrations; dat belemmert consistente deployment governance.
- Overall score (1-10)
  - 8.1/10

### 2. Laag-voor-laag analyse
- Supabase / Database laag
  - `ai_sessions`, `mirror_templates` en RLS-polities zijn functioneel aanwezig (`supabase_setup.sql`, `supabase_policies.sql`).
  - Storage hardening voor nieuwe apply-flow is netjes gemigreerd via `supabase/migrations/20260308_mirror_storage_hardening.sql` met owner-folder policies op `mirror-signed-inputs` en `mirror-backups`.
  - Apply audit en retention zijn production-minded (`supabase/migrations/20260308_mirror_audit_and_ai_sessions_retention.sql`): audit-event tabel, retention function, pg_cron hook.
  - Risico: canonieke waarheid is verdeeld over setup-script en migrations; voor CI/CD hoort alles naar versioned migrations met idempotente seed-strategie.
  - Risico: `project_id`/`task_id` zijn `TEXT` zonder FK-relaties; dit is flexibel maar minder sterk voor data-integriteit en query-optimalisatie.

- Edge Functions & gRPC backend laag
  - Edge function (`supabase/functions/mirror_compute/index.ts`) heeft goede guardrails: auth-validatie, route dispatch (`/compile`/`/apply`), timeout, structured error schema, request-id en idempotency-key.
  - Kritieke implementatiekloof is nu deels opgelost: apply-security velden (`backupId`, `fileSetFingerprint`, `actorUserId`, `signedInputUrls`) worden nu door edge genormaliseerd en doorgestuurd in payload.
  - Cloud runner (`server/mirror-cloud-runner/lib/main.dart`) heeft sterke auth-gate (`server/mirror-cloud-runner/lib/auth_guard.dart`) en metrics (`auth_metrics.dart`).
  - Risico: runner-service implementeert alleen gRPC `Compile`; expliciete `/apply` executie aan runner-zijde is niet zichtbaar, terwijl applaag en edge-contract dit wel verwachten.
  - Risico: protocolkeuze (HTTP proxying naar endpoint dat mogelijk gRPC-only is) vraagt een expliciete gateway-architectuur of uniform HTTP runner API.

- Dart/Flutter core & providers laag
  - `mirrorProvider` is goed ontworpen: mode policy, premium-refresh, variant-refresh, cache-hydratatie en waarschuwingstoestand zijn coherent (`lib/core/providers/mirror_provider.dart`).
  - `openMirrorFromTask` in bridge-notifier is correct sequentieel (`await setMode`, `await refreshTeamModeVariant`) en daardoor race-safe (`lib/core/providers/ai_chat_provider.dart`).
  - `MirrorPremiumService` biedt nette caching + in-flight dedupe (`lib/core/services/mirror_premium_service.dart`).
  - Risico: backendselectie gebruikt zowel premium-policy als mode-policy; houd 1 centrale beslisfunctie om divergent gedrag op termijn te vermijden.
  - Risico: session state is in-memory only (`lib/core/providers/mirror_session_provider.dart`) en gaat verloren bij app kill; dat past deels bij editor, maar beperkt echte offline herstelbaarheid.

- UI & UX laag (editor, dialogs, realtime)
  - Mirror editor heeft sterke basis met explorer/editor/terminal/live output/voice input in een responsive layout (`lib/features/mirror/mirror_editor_screen.dart`).
  - Output-capping is aanwezig (`_maxLiveOutputLines = 500`) en voorkomt ongecontroleerde geheugen-groei.
  - Apply-dialog is veilig ontworpen met risico-acknowledgement + diff-preview + branch-advies (`lib/features/mirror/apply_dialog.dart`).
  - Risico: Monaco host moet functioneel geverifieerd blijven (webview/lifecycle/IME), omdat editor-UX hier cruciaal is.
  - Risico: realtime subscription gebruikt table-level feed op `ai_sessions`; bij hoge load kan dit chatty worden zonder striktere server-side channel partitionering.

- Security, permissions & premium checks
  - Toegang is goed gelaagd: permission (`use_mirror`) in auth-rollen, startup route gate, runtime check in bridge-provider (`lib/core/projects_initializer.dart`, `packages/pma_core/lib/repository/impl/hive_auth_repository.dart`, `lib/core/providers/ai_chat_provider.dart`).
  - Cloud entitlement wordt op meerdere plekken gecontroleerd (`MirrorAccessPolicy`, `MirrorPremiumService`, `CloudFlyBackend`) en dat reduceert bypass-risico.
  - Storage-RLS en audit-events versterken traceability en blast-radius-control.
  - Risico: meerdere entitlement-bronnen (metadata + subscriptions table) vereisen formele precedence-regels en monitoring op inconsistenties.
  - Risico: lokale Docker compose gebruikt dev-secret (`server/mirror-local-runner/docker-compose.yml`), wat prima is voor local dev maar expliciet afgeschermd moet blijven van staging/prod pipelines.

- Offline / Hive / caching laag
  - Offline caching is degelijk: encryptiepad met fallback, schema-versioning, TTL op values en invalidatie op auth/premium changes (`lib/core/providers/mirror_provider.dart`).
  - Apply-history/audit wordt lokaal opgeslagen (`mirror_apply_history`, `mirror_apply_audit`) voor herstelbaarheid en debugging (`lib/features/mirror/mirror_compute_backend.dart`).
  - Risico: fallback naar unencrypted Hive bij key/open failure is pragmatisch maar security-technisch een downgrade; maak dit meetbaar via telemetry en policy-flag.
  - Risico: grote `updatedFiles` snapshots in history kunnen storage druk geven op low-end devices; compressie/limieten per entry zijn wenselijk.

- Integratie met bestaande app
  - Mirror launch vanuit project en task is aanwezig en coherent via bridge-provider (`lib/features/project/project_detail_screen.dart`, `lib/features/project/expandable_task_card.dart`, `lib/core/providers/ai_chat_provider.dart`).
  - Architectuurdocument en ops-runbook sluiten redelijk goed aan op implementatie (`docs/mirror-architecture.md`, `docs/mirror-ops-runbook.md`).
  - Risico: README verwijst nog naar niet-canonieke paden (`lib/features/projects/project_details_widget.dart`, `lib/features/tasks/task_card.dart`) i.p.v. actuele bestanden.
  - Risico: dubbele exportstructuur voor session provider (`lib/features/mirror/providers/mirror_session_provider.dart` -> core provider) kan op termijn verwarring geven zonder duidelijke conventie.

### 3. Concrete aanbevelingen
- Wijzigingen (met exacte bestandsnamen en wat te veranderen)
  - [DONE] `supabase/functions/mirror_compute/index.ts`
    - [DONE] Kritieke fix toegepast: behoud en forward van `backupId`, `fileSetFingerprint`, `actorUserId` en `signedInputUrls` in normalisatie + upstream payload, zodat apply-security flow end-to-end klopt.
    - [DONE] Request body size guard toegevoegd (max 512KB).
  - [DONE] `lib/features/mirror/cloud_fly_backend.dart`
    - [DONE] Expliciete contract-check op upstream capability (`supportsApply`) met fail-fast typed foutpad voor `/apply`.
    - [DONE] Endpoint-resolutie gecentraliseerd via `EdgeFunctionBackend`.
    - [DONE] `generate` geïmplementeerd (mapping via `compile`) i.p.v. placeholder.
  - [DONE] `lib/features/mirror/private_grpc_backend.dart`
    - [DONE] `generate` geïmplementeerd.
  - [DONE] `lib/features/mirror/mirror_compute_backend.dart`
    - [DONE] `updatedFiles` persistence begrensd (max 50 files / 100k chars) in `persistApplyToHive`.
    - [DONE] Event-name constants toegevoegd voor apply-audit.
  - [DONE] `lib/features/mirror/mirror_editor_screen.dart`
    - [DONE] Debounce/coalescing toegevoegd in `_handleRealtimeRecord` (300ms).
    - [DONE] Striktere filtering toegevoegd met `task_id` + `project_id` + `user_id` validatie (server-side filter op `user_id`, aanvullende client-side scope-check).
  - [DONE] `README.md`
    - [DONE] Mirror related files gecorrigeerd naar actuele paden: `lib/features/project/project_detail_screen.dart` en `lib/features/project/expandable_task_card.dart`.
  - [DONE] `supabase_setup.sql`
    - [DONE] Mirror schema-definities verplaatst naar migrations-only beleid en setup script gemarkeerd als bootstrap/legacy.

- Toevoegingen (nieuwe bestanden/features met korte beschrijving)
  - [DONE] `supabase/migrations/20260309_mirror_templates_rls_and_sync.sql`
    - [DONE] RLS + DB-first beheerstrategie toegevoegd voor `mirror_templates` inclusief seed sync.
  - [DONE] `server/mirror-cloud-runner/lib/apply_service.dart`
    - [DONE] Expliciete apply-service toegevoegd (gRPC/HTTP signature gelijk aan compile).
  - [DONE] `server/mirror-local-runner/lib/apply_service.dart`
    - [DONE] Apply-service toegevoegd voor Private Mode ondersteuning.
  - [DONE] `test/features/mirror/apply_flow_contract_test.dart`
    - [DONE] End-to-end contracttest toegevoegd voor signed uploads, metadata forwarding en audit consistency.
  - [DONE] `test/core/services/mirror_premium_service_integration_test.dart`
    - [DONE] Precedence-tests metadata vs subscriptions toegevoegd.
  - [DONE] `docs/mirror-production-readiness-checklist.md`
    - [DONE] Volledige production readiness checklist toegevoegd.

- Verwijderingen (wat weg kan en waarom)
  - [DONE] `lib/features/mirror/providers/mirror_session_provider.dart`
    - [DONE] Verwijderd als pure re-export; direct gebruik van `lib/core/providers/mirror_session_provider.dart`.
  - [DONE] Statische template duplicatie in `lib/features/mirror/templates_gallery.dart`
    - [DONE] Hardcoded `defaultTemplates` verwijderd (DB-first).
  - [DONE] Legacy Mirror blokken in `supabase_setup.sql`
    - [DONE] Verwijderd; migrations zijn leidend.
