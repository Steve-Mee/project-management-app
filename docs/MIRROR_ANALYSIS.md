# Mirror Feature — Diepgaande Architectuuranalyse

> **Gegenereerd door:** GitHub Copilot (senior Flutter/Supabase architect review)  
> **Datum:** 2026-03-21  
> **Scope:** Volledige Mirror AI Coding Studio implementatie inclusief 36 prompts van Supabase-laag t/m UI-integratie.

---

## 1. Algemene beoordeling

### Sterke punten

- **Strikte compute-scheiding** via `// ARCHITECTURE LOCK` comment die herhaal wordt in elk kritiek bestand. De gateway voert geen AI-compute uit — alleen auth, autorisatie, idempotency en doorsturen.
- **Defence-in-depth autorisatie**: twee onafhankelijke lagen (client-side `MirrorAccessPolicy` + server-side `use_mirror` RPC + `has_cloud_mirror_access` RPC).
- **Drie-laags offline-resilience**: `MirrorOfflineCache` (mode/variant persistence), `MirrorDraftCacheService` (editor-concepten) en `MirrorOutboxReplayService` (queued compile/apply met circuit-breaker).
- **Apply-integriteitschain van vier onafhankelijke guards**: compile-fingerprint, context-file-fingerprint, signed backup upload vóór forward, en server-side audit events.
- **Schema strict in versioned migrations**: zowel `supabase_setup.sql` als `supabase_policies.sql` redirecten Mirror-schema expliciet naar `supabase/migrations/` (10 bestanden, datumbereik 2026-03-08 t/m 2026-03-17).
- **Idempotency via SHA-256 request-hashing**: de gateway hash de complete genormaliseerde aanvraag (userId + action + payload) zodat duplicate of herhaalde requests safe worden afgehandeld.
- **Uitgebreide contracttests**: 15+ testbestanden in `test/features/mirror/` die gateway-contracten, security-flow, outbox-encryptie, realtime-dedup en preview-apply-consistentie vastleggen.
- **Observability service** (`MirrorObservabilityService`) registreert compile-latency, retry-pogingen, fallback-events en cache-resultaten als gestructureerde telemetriegebeurtenissen.
- **Alle gevoelige Hive-boxes zijn versleuteld**: outbox, draft-cache, audit-history en template-cache gebruiken `EncryptedHiveBox` met fail-closed semantics in productie.
- **Circuit-breaker in outbox**: 4 opeenvolgende fouten openen het circuit gedurende 45 seconden, waarna één probe wordt toegelaten.
- **gRPC + HTTP als backends**: drie concrete implementaties (`PrivateGrpcBackend`, `MirrorGatewayBackend`, `_MirrorDisabledBackend`) achter één `MirrorComputeBackend`-interface — uitstekende dependency inversion.

### Zwakke punten

- **`private_grpc_backend.dart` is de gRPC-implementatie**: de `PrivateGrpcBackend` beheert private gRPC-transport. Cloud-routing loopt via `MirrorGatewayBackend`; opslag-artefacten landen in de canonieke buckets `mirror-signed-inputs` en `mirror-backups`.
- **Geen go_router-route voor `MirrorEditorScreen`**: navigatie is puur imperatief (`Navigator.push`), waardoor deep links via URL ontbreken. Er is een `initialRoute.contains('mirror')` check in `projects_initializer.dart` maar geen gedeclareerde route.
- **Dubbele model-klassen**: `ApplySecurityArtifacts` in `mirror_signed_inputs_backend.dart` en `MirrorSecureApplyArtifacts` in `mirror_secure_apply_service.dart` zijn inhoudelijk identiek; hetzelfde voor `ApplyUploadFailure` / `MirrorSecureApplyUploadFailure`.
- **Overlappende verantwoordelijkheden**: `MirrorEditorRunService` doet een budget-preflight-check en delegeert dan naar `MirrorEditorOrchestrationService`, die zelf ook file-validaties uitvoert. Gedeelde schermen tussen twee servicelagen.
- **Monaco op desktop via HTML fallback**: `monaco_editor_host_io.dart` checkt `InAppWebViewPlatform.instance != null`. Op Windows/Linux/macOS valt dit door naar een gewone `TextField`, wat een significant UX-verschil is van de browser-omgeving.
- **A/B-testing timeout van 3 seconden** kan een merkbare startup-vertraging veroorzaken bij elke sessie-init.
- **Rate-limit telt verlopen/gespeelde requests mee**: de rate-limit-teller in de gateway telt tegen `mirror_request_idempotency`-rijen inclusief verlopen/gecachede entries, waardoor de telling minder nauwkeurig is.
- **Voice input voegt toe aan code-bestanden**: `speech_to_text`-resultaten worden direct aan de bestandsinhoud toegevoegd (inclusief newlines), wat geldige code kan corrumperen als de gebruiker per ongeluk voice activeert in een code-editor.
- **`Supabase.instance.client` als directe singleton** in `mirror_templates_provider.dart` in plaats van het geïnjecteerde client-pattern dat de rest van de codebase hanteert.

### Overall score: **8 / 10**

Een mature, goed-beveiligde implementatie met uitzonderlijk sterke integriteits- en offline-garanties. Puntenaftrek voor de ontbrekende gRPC-CloudFly-abstractie, duplicate models, en de ontbrekende go_router-registratie.

---

## 2. Laag-voor-laag analyse

### 2.1 Supabase / Database laag

**Wat er is:**

| Object | Status |
|--------|--------|
| `ai_sessions` | Volledig gedefinieerd in `20260310_create_ai_sessions_baseline.sql` met UUID PK, `user_id`, `project_id`, `task_id`, `prompt`, `mode`, `status`, `versions JSONB`, `metadata JSONB`, trigger voor `updated_at`, RLS: owner-only read/write. |
| `mirror_request_idempotency` | Aangemaakt in `20260310_mirror_request_idempotency.sql`; `expires_at` en `response_cache`-kolommen toegevoegd in latere patches. State machine: `claimed → in_progress → completed / failed`. |
| `mirror_usage_logs` | Aangemaakt in `20260311_mirror_usage_metering.sql`. Bevat `duration_ms`, `token_estimate`, `status`, `action`, `idempotency_key`. SECURITY DEFINER cleanup-functie met retentie-parameter. |
| `mirror_apply_audit_events` | Aangemaakt in `20260308_mirror_audit_and_ai_sessions_retention.sql`. Audit-lifecycle: `apply_started`, `apply_preparation_failed`, `apply_completed`, `apply_exception`. |
| `mirror_templates` | RLS en sync-beleid in `20260309_mirror_templates_rls_and_sync.sql`. |
| `mirror-signed-inputs` bucket | Aangemaakt in `20260308_mirror_storage_hardening.sql`. |
| `mirror-backups` bucket | Aangemaakt in `20260308_mirror_storage_hardening.sql`. |

**Bevindingen:**

- ✅ Alle Mirror-schema-objecten zijn in versioned migrations, buiten de monolithische setup-SQL. Dit vermindert policy-drift aanzienlijk.
- ✅ RLS is aanwezig op alle tabellen: owner-only policies op `ai_sessions` en `mirror_usage_logs`.
- ✅ `SET search_path TO` beschermt SECURITY DEFINER functies.
- ⚠️ De `mirror_request_idempotency` rate-limit tel-query (`COUNT ... WHERE user_id = $1 AND created_at > NOW() - INTERVAL '1 minute'`) omvat verlopen/gecachede entries. Overweeg een aparte `rate_limit_window_start`-index of een `WHERE status NOT IN ('expired')` filter.
- ⚠️ Er is geen `TTL/expires_at`-based row-cleanup cron voor `mirror_request_idempotency`. Bij hoge traffic kan de tabel ongecontroleerd groeien. De `cleanup_mirror_usage_logs_retention`-functie bestaat voor usage logs maar niet voor de idempotency tabel.
- ⚠️ `ai_sessions.versions` is `JSONB` zonder JSON-schema-validatie. Overweeg een `CHECK constraint` of een `json_schema_validation` trigger om corrupte payloads te weren.
- ⚠️ Broadcast-topics in `20260309_mirror_ai_sessions_broadcast_topics.sql` moeten overeenkomen met de Dart-kant (`project_id::{id}::task::{id}`); een mismatch hier zal realtime stilletjes breken zonder foutmelding.

---

### 2.2 Edge Functions & gRPC backend laag

**Edge Function `mirror-gateway/index.ts`:**

- ✅ Strikte routingcontrole: `resolveActionFromPath()` matcht alleen `/compile` of `/apply`; alles anders geeft 405.
- ✅ Body-grootte-limiet van 512 KB (via `Content-Length` + echte bytestelling).
- ✅ Stale-processing reset: claims ouder dan 300 seconden worden automatisch teruggerold. Dit voorkomt vastgelopen idempotency-slots na crashes.
- ✅ Structurele foutresponsen met `error_family`, `retryable`, `requestId`, `traceId` — volledig parsebaar door de Dart-client voor categorie-specifieke afhandeling.
- ✅ Forward-headers bevatten `x-user-id`, `x-request-id`, `x-trace-id`, `x-idempotency-key` — de Fly.io-runner kan authenticiteit verifiëren zonder de JWT opnieuw te valideren.
- ⚠️ **Rate-limit telt verlopen rijen mee** (zie §2.1). Overweeg `WHERE created_at > NOW() - INTERVAL '1 minute' AND status != 'expired'`.
- ⚠️ Geen `Content-Type`-validatie op het request (alleen `application/json` zou toegestaan moeten zijn).
- ⚠️ De 20-seconden forward-timeout (`MIRROR_FORWARD_TIMEOUT_MS`) is geconfigureerd per environment, maar er is geen uitvoer van de effectieve timeout-waarde in startup-logs — dit maakt debugging van timeouts lastiger.

**`MirrorGatewayBackend` (Dart):**

- ✅ Volledig injecteerbare dependencies voor testing (`httpClient`, `client`, `retryPolicy`, etc.).
- ✅ `_validatePreviewApplyConsistency()` — vier controles vóór apply: compile-fingerprint aanwezig, fingerprint matcht, context-file-fingerprint matcht, preview reuse payload consistent.
- ✅ Correcte gzip-compressie via platform-conditional `_gzip_helper` / `_gzip_helper_io.dart`.
- ⚠️ **`Supabase.instance.client` als fallback** in `_resolveClient()` — de gateway accepteert `null` en valt terug op de singleton. Dit maakt unit-testing van de auth-stroom moeilijker dan nodig.
- ⚠️ Response-parsing in `_compileResultFromRaw()` accepteert zowel een raw string (legacy) als JSON-object. De legacy-pad zou met een deprecation-wrapper moeten zijn afgebakend om per ongeluk gebruik ervan te tracken.

**`PrivateGrpcBackend` (Dart):**

- ✅ Productie-transport-guard: blokkeert insecure `ChannelCredentials` bij `kReleaseMode || _isProductionGrpcRuntime`.
- ✅ Short-lived channels per RPC (niet gedeeld) — voorkomt file-descriptor leakage bij langlopende sessies.
- ✅ Apply-fingerprint-validatie identiek aan de gateway-implementatie.
- ⚠️ `grpc_generated/` .dart-bestanden zijn gegenereerd maar het `.proto`-bronbestand is niet aanwezig in de repo. Als schema verandert moet dit manueel gesynchroniseerd worden en er is geen automatische regeneratie pipeline.

---

### 2.3 Dart/Flutter core & providers laag

**`MirrorComputeBackend` (interface + extensions):**

- ✅ Schoone interface met drie methoden: `generate`, `compile`, `apply`.
- ✅ `computeCompileResultFingerprint()` is een pure functie (SHA-256 inputs + output) — deterministisch en testbaar.
- ⚠️ **Extensions op de interface (`MirrorPatchTools`, `MirrorApplySecurity`, `MirrorPromptBuilder`)**: door functionaliteit via extensions op de `MirrorComputeBackend` abstract class te mixen, koppelt de interface aan implementatiedetails (Hive, Supabase, diff-algoritmen). Dit schendt Interface Segregation Principle. Overweeg aparte service-klassen.

**`MirrorSessionProvider` (family)**:

- ✅ `AutoDisposeFamilyNotifier` per `"$projectId::$taskId"` — correcte geheugen-lifecycle.
- ✅ Dual hydration (draft-cache-first, daarna repository) met correcte merge-strategie.
- ✅ `setCompileValidationArtifacts()` valideert niet-lege fingerprint vóór opslaan.
- ⚠️ Draft-persistentie is na 500ms debounce + `unawaited` call in `dispose()`. Als de app onverwacht crashed kan het laatste schrijven verloren gaan.
- ⚠️ Context-bestanden worden opgebouwd in `_buildContextFiles()` met vaste sleutels (`context/project.json`, `context/tasks.json`, etc.). Als een projectnaam of task-ID een `::` bevat, kan de session-key misleidend zijn.

**`MirrorOfflineCacheProvider` + `MirrorNotifier`:**

- ✅ Auth-change-invalidation: als `currentUserId` verschilt van het gecachede `__auth_user_id__`, wordt alles gewist.
- ✅ Premium-change-invalidation bij transitie.
- ⚠️ A/B `assignVariant()` wordt aangeroepen met een hard-coded 3-seconden timeout. Als de AB-service traag reageert blokkeert dit elke `setMode()`-aanroep zichtbaar.
- ⚠️ `MirrorOfflineCache` gebruikt Hive schema versie 4 met clear-on-mismatch. Bij een schema-upgrade verliezen gebruikers stille hun gecachede modus zonder melding.

**`MirrorEntitlementProvider`:**

- ✅ `mirrorBackendProvider` resolutie-keten is correct: feature flag → premium check → mode-resolution → backend selectie.
- ✅ `onCompileValidated` callback schrijft fingerprint+token terug in de sessie-notifier.
- ⚠️ `mirrorGatewayBackendProvider` is een `Provider` (niet `FutureProvider`), maar leest intern een `FutureProvider` (`mirrorPremiumProvider`) via `ref.watch`. Dit kan race-conditions veroorzaken als premium-status verandert terwijl een compile actief is.

**`MirrorOutboxReplayService`:**

- ✅ Circuit-breaker volledig geïmplementeerd: `closed → open (na 4 mislukkingen) → half-open (na 45s) → probe → closed/open`.
- ✅ Idempotency-key deduplicatie via `LinkedHashMap` met last-write-wins conflict-strategie.
- ✅ Context-budget enforcement vóór enqueue — voorkomt dat te grote payloads de outbox opblazen.
- ⚠️ `replayTickInterval = 8s` is een hard-coded waarde. Bij hogere replay-volumes kan 8 seconden te lang zijn; overweeg configureerbaar te maken.
- ⚠️ Terminal entries (bij `maxReplayAttempts = 8`) worden stilletjes overgeslagen. Er is geen user-facing melding dat een entry permanent mislukt is.

---

### 2.4 UI & UX laag (editor, dialogs, realtime)

**`MirrorEditorScreen`:**

- ✅ Permissie-revocation via `listenManual` — als `use_mirror` ingetrokken wordt tijdens een actieve sessie, wordt realtime gestopt, STT gestopt en de sessie geïnvalideerd.
- ✅ Structured error parsing (`_tryParseStructuredMirrorError`) met visuele retry-kaart voor retryable fouten.
- ✅ `_isRunInProgress` vergrendelt alle inputs tijdens een run om race-conditions te voorkomen.
- ⚠️ **Voice input risico**: `speech_to_text`-resultaten worden letterlijk aan het geselecteerde bestand toegevoegd. Als de gebruiker voice activeert in een Dart/Python/TypeScript-bestand, wordt syntactisch ongeldige tekst ingevoegd. Overweeg voice te beperken tot een apart prompt-veld.
- ⚠️ `Terminal(maxLines: 1000)` is een hard limit. Na 1000 regels scrolt de terminal niet meer terug naar vroege output. Overweeg een export-knop of verhoog de limiet.
- ⚠️ `_liveOutputScrollController` wordt niet gedisposed in `dispose()`. Dit is een kleine resource-leak.
- ⚠️ Monaco op desktop (`monaco_editor_host_io.dart`) vereist `InAppWebViewPlatform.instance != null`. Dit is niet gegarandeerd op Windows/Linux zonder expliciete `InAppWebViewPlatform.initialize()` aanroep in de `main()`. Als dit ontbreekt valt de editor terug op een `TextField` zonder waarschuwing.

**`ApplyDialog`:**

- ✅ `compileFingerprint` wordt als constructor-parameter doorgegeven — de dialog kan niet worden misbruikt om een andere payload te laten bevestigen dan de compile.
- ✅ `acceptRisk` checkbox vereist expliciete instemming.
- ✅ Diff rendering via `MirrorDiffService.buildUnifiedDiffLines()` — kleur-gecodeerd met hunk-headers.
- ⚠️ De dialog toont geen bestandsnaam bij multi-file diffs — alleen `widget.title` (eerste bestand). Bij meerdere aangepaste bestanden ziet de gebruiker niet welke andere bestanden wijzigen.

**`TemplatesGallery`:**

- ✅ Responsieve grid (1 kolom < 640px, configurable > 640px).
- ✅ Simpele, zuivere widget zonder Supabase-afhankelijkheid — provider-data wordt van boven doorgegeven.
- ⚠️ Geen lege-state widget als `templates.isEmpty`. De gallery toont dan een lege grid zonder feedback.

**Realtime (`MirrorRealtimeService` + `MirrorEditorRealtimeController`):**

- ✅ Payload-guards: `maxCharsPerLine = 500`, `maxLinesPerEvent = 50`, `maxRealtimeCharsPerDebounceWindow = 10000`.
- ✅ Deduplicatie via `Set<String> _processedRealtimeEventIds` + `Queue` voor LRU-evictie bij max 2000 entries.
- ✅ Scope-check: events buiten het huidige project/task worden stilletjes genegeerd.
- ⚠️ `_realtimeDebounceTimer` wordt niet geannuleerd als het kanaal tijdelijk verbroken is — dangling timer kan een flush triggeren voor een verbroken kanaal.
- ⚠️ `debugRealtimeRecords` stream in de test-harness bypast `enforceScope = false`. Dit is correct voor tests, maar zou per abuis ook in ikke-test code gebruikt kunnen worden.

---

### 2.5 Security, permissions & premium checks

| Controle | Waar | Status |
|----------|------|--------|
| `use_mirror` RPC check | Edge Function (server) | ✅ |
| `has_cloud_mirror_access` RPC | Edge Function (cloud mode only) | ✅ |
| `hasPermissionProvider(AppPermissions.useMirror)` | Flutter client | ✅ |
| `MirrorAccessPolicy.resolveRequestedMode()` | Flutter client (mode-downgrade) | ✅ |
| `mirror_enabled` feature flag | Beide lagen | ✅ |
| `mirror_admin_testing_bypass` flag | Beide lagen (admin only) | ✅ |
| Stripe/premium check | `mirrorPremiumProvider` via `MirrorPremiumService` | ✅ |
| gRPC TLS enforcement in productie | `PrivateGrpcBackend._enforceProductionTransportSecurity()` | ✅ |
| Signed URL TTL 300s default | `mirror_secure_apply_service.dart` | ✅ (configureerbaar) |
| Path sanitization voor storage | `_sanitizeStoragePath` met regex whitelist | ✅ |
| Encrypted Hive outbox | `EncryptedHiveBox` + fail-closed in productie | ✅ |
| Payload 512 KB limiet | Edge Function body check | ✅ |
| Rate limiting | Edge Function (10/min default + 30/3min burst) | ✅ (zie ⚠️) |

**Bevindingen:**

- ✅ Geen hardcoded secrets in Dart-code aangetroffen. Alle endpoints zijn via environment-variabelen of AppConfig geconfigureerd.
- ✅ `_sanitizeStoragePath` vervangt onveilige tekens met een whitelist-regex — voorkomt path-traversal in storage-uploads.
- ⚠️ **Signed URL replay window**: 300 seconden is kort maar niet nul. Signed URLs in logs of browser history zijn gedurende 300 seconden bruikbaar door derden die deze URL kunnen aflezen. Overweeg een kortere TTL (60s) voor production of IP-binding waar de storage provider dit ondersteunt.
- ⚠️ **Rate-limit nauwkeurigheid** (zie §2.2): geteld over verlopen/gecachede rijen kan leiden tot false-positieve 429s bij hoge replay-volumes.
- ⚠️ **`allowAdminBypass` in `MirrorAccessPolicy`** is een boolean parameter die vanuit `mirrorAdminTestingBypassProvider` wordt meegegeven. Als de feature flag tabel gecompromitteerd is, kan een aanvaller bypass activeren. Overweeg een extra RLS-check op de `feature_flags` tabel voor `mirror_admin_testing_bypass`.
- ⚠️ **JWT niet herevalueerd na token-expiry** tijdens een langlopende compile/apply. Als een token verloopt tijdens een 25-seconden out-box replay, stuurt de gateway een 401 die correct als retryable wordt afgehandeld — maar de client hernieuwt het token pas bij de volgende Supabase-aanroep. Overweeg een proactieve token-refresh vóór het starten van een compile.

---

### 2.6 Offline / Hive / caching laag

| Cache | Box | Encryptie | TTL | Schema-versie |
|-------|-----|-----------|-----|---------------|
| Mode/variant | `mirror_offline_cache` | ✅ | 7 dagen | 4 (clear-on-mismatch) |
| Editor drafts | `mirror_editor_drafts` | ✅ | — (max 40 sessies) | — |
| Templates | `mirror_templates_cache` | ❌ (publieke data) | 10 minuten (in-memory) | 1 |
| Outbox | `mirror_outbox` | ✅ | — | — |
| Apply audit | `mirror_apply_audit` | ✅ | — | — |

**Bevindingen:**

- ✅ Template-cache is terecht onversleuteld (publieke data). Andere boxes zijn versleuteld conform het gevoeligheidscriterium.
- ✅ `MirrorOfflineCache` heeft auth-change-invalidation — wist gecachede state als de gebruiker wisselt.
- ✅ `MirrorDraftCacheService` begrenst de cache op 40 sessies, 80 bestanden per sessie, 300.000 tekens totaal en 25.000 per bestand.
- ⚠️ **Draft-evictie-strategie** bij overschrijding van 40 sessies is niet eenduidig gedocumenteerd — welke sessies worden verwijderd (FIFO? LRU?)? Controleer de implementatie op een gedocumenteerde evictie-volgorde.
- ⚠️ **Schema-versie voor `mirror_editor_drafts`** is niet gedocumenteerd. Bij een breaking draft-formatwijziging kunnen stale drafts niet silent worden weggegooid maar leiden tot parse-fouten.
- ⚠️ **`unawaited(persistDraft(...))`** in de `dispose()` van `MirrorSessionNotifier` kan de final draft verliezen bij crashes die de Flutter engine doden voordat de async call completeert.
- ⚠️ Templates worden gecached in een **in-memory singleton** (`_MirrorTemplatesMemoryCache.snapshot`) naast de Hive-persistent cache. Als twee sessies tegelijk starten, kan de in-memory cache een race hebben bij initialisatie.

---

### 2.7 Integratie met bestaande app

**Navigatie & routing:**

- ✅ Beide entry points (`project_detail_screen.dart` en `expandable_task_card.dart`) gebruiken hetzelfde `AiChatBridgeNotifier.openMirrorFromTask()` pad — consistente gating.
- ✅ Null-payload wordt correct afgehandeld met een `SnackBar` (l10n-sleutel `mirrorUnavailableForAccount`).
- ⚠️ **Geen go_router route**: `MirrorEditorScreen` is niet geregistreerd in `routes.dart`. Deep links via URL (bijv. vanuit een e-mailnotificatie naar een specifieke taak) kunnen de editor niet openen. Er is een `initialRoute.contains('mirror')` check in `projects_initializer.dart` maar geen handelaar.
- ⚠️ **Back-navigatie verliest sessie-state**: omdat `MirrorEditorScreen` via `MaterialPageRoute` wordt gepusht en `mirrorSessionProvider` een `AutoDisposeFamilyNotifier` is, wordt de sessie vernietigd bij pop. Heropen van dezelfde taak zal de cache opnieuw hydrateren (draft-cache), maar realtime-subscriptie wordt niet hervat.

**`AiChatBridgeProvider`:**

- ✅ `openMirrorFromTask()` checkt feature flag + permissie vóór state-mutatie.
- ✅ `clearMirrorLaunchRequest()` reset de launch-payload na navigatie.
- ⚠️ `ref.read(aiChatProvider)` wordt aangeroepen in `openMirrorFromTask()` zonder duidelijk doel — dit ziet eruit als een overgebleven side-effect call. Verwijder of documenteer waarom de AI-chat provider hier nodig is.

**Lokalisatie:**

- ✅ Alle Mirror-gerelateerde strings in de UI (`_l10n.mirrorTerminalReady`, `mirrorRunStarting`, `mirrorApplyConfirm`, etc.) zijn gelokaliseerd.
- ⚠️ Voice-input-toegankelijkheids-feedback ontbreekt — `_isListening` wordt bijgehouden maar er is geen `Semantics`-widget of auditieve feedback.

---

## 3. Concrete aanbevelingen

### Wijzigingen (bestaande bestanden aanpassen)

| # | Bestand | Wijziging |
|---|---------|-----------|
| W1 | `lib/features/mirror/services/mirror_editor_run_service.dart` | Verwijder de dubbele budget-preflight-check (zit ook in orchestration service). Houd één authoritative check in `MirrorEditorOrchestrationService`. |
| W2 | `lib/features/mirror/mirror_signed_inputs_backend.dart` | Verplaats `MirrorPatchTools`, `MirrorApplySecurity` en `MirrorPromptBuilder` extensions naar aparte service-klassen in de `services/` map. Dit verwijdert de ISP-overtreding. |
| W3 | `lib/features/mirror/mirror_gateway_backend.dart` | Vervang `_resolveClient(null)` fallback naar `Supabase.instance.client` door een verplichte constructor-parameter met `@visibleForTesting` override, zodat de singleton niet stilletjes de injectie omzeilt. |
| W4 | `lib/features/mirror/providers/mirror_templates_provider.dart` | Vervang `Supabase.instance.client` op regel 18 door een geïnjecteerde client via een provider (conform rest van codebase). |
| W5 | `lib/features/mirror/mirror_editor_screen.dart` | `_liveOutputScrollController.dispose()` is reeds correct aanwezig in de `dispose()`-methode. ✅ Geen actie vereist — notatie ter bevestiging van correctheid. |
| W6 | `lib/features/mirror/mirror_editor_screen.dart` | Beperk voice-input tot een apart `_voicePromptController` veld (singleline `TextField`) in plaats van voice-resultaten direct in het actieve code-bestand te injecteren. |
| W7 | `lib/core/providers/mirror_entitlement_provider.dart` | Zet `mirrorGatewayBackendProvider` om van `Provider` naar `FutureProvider` om race-conditions te vermijden wanneer `mirrorPremiumProvider` herschikt na een Stripe-event. |
| W8 | `lib/core/providers/mirror_offline_cache_provider.dart` | Verminder A/B testing timeout van 3 seconden naar 1 seconde, of maak de timeout configureerbaar via `AppConfig`. |
| W9 | `lib/features/mirror/apply_dialog.dart` | Toon alle gewijzigde bestandsnamen als een tab-bar of dropdown bij multi-file diffs, niet alleen het eerste bestand in de titel. |
| W10 | `lib/features/mirror/templates_gallery.dart` | Voeg een `Center(child: Text(l10n.mirrorNoTemplatesAvailable))` empty-state toe wanneer `templates.isEmpty`. |
| W11 | `lib/core/providers/mirror_session_provider.dart` | Documenteer de sessie-evictie-volgorde in `MirrorDraftCacheService._maxSessions` (FIFO vs. LRU). |
| W12 | `lib/core/providers/ai_chat_provider.dart` | Verwijder of documenteer `ref.read(aiChatProvider)` op de betreffende regel in `openMirrorFromTask()`. |
| W13 | `supabase/migrations/` | Voeg een cleanup-query/cron toe voor `mirror_request_idempotency` rijen waarvan `expires_at < NOW()` om ongecontroleerde tabelgroei te voorkomen. |
| W14 | `supabase/functions/mirror-gateway/index.ts` | Voeg `WHERE status != 'expired'` toe aan de rate-limit tel-query, zodat vervallen idempotency-entries niet bijdragen aan het rate-limit-venster. |
| W15 | `supabase/functions/mirror-gateway/index.ts` | Voeg `Content-Type: application/json` request-header-validatie toe (405-equivalent voor verkeerd content-type). |

---

### Toevoegingen (nieuwe bestanden of features)

| # | Bestand / Feature | Beschrijving |
|---|-------------------|--------------|
| A1 | `lib/core/routes.dart` + `MirrorEditorScreen` | Registreer een `GoRoute` voor Mirror zoals `/projects/:projectId/tasks/:taskId/mirror`, zodat deep links werken. Hergebruik `AiChatBridgeNotifier.openMirrorFromTask()` in de `redirect` callback voor permissie-check. |
| A2 | `lib/features/mirror/services/mirror_draft_cache_service.dart` | Implementeer en documenteer een expliciete LRU-evictie (bijv. via Hive-sleuzel-tijdstempel) voor de 40-sessies-limiet. |
| A3 | `lib/features/mirror/mirror_editor_screen.dart` | Voeg `Semantics`-labels toe aan de voice-input knop en de run-knop voor screen-reader toegankelijkheid. |
| A4 | `supabase/migrations/20260322_mirror_idempotency_cleanup.sql` | Cron-job of SECURITY DEFINER functie voor het verwijderen van verlopen `mirror_request_idempotency`-rijen (analoog aan de bestaande `cleanup_mirror_usage_logs_retention`). |
| A5 | `lib/features/mirror/services/mirror_session_heartbeat_service.dart` | Proactieve JWT-refresh voor het starten van een compile/apply om 401-retries bij lang-open sessies te voorkomen. |
| A6 | `packages/pma_core/lib/services/` | Definieer een `MirrorTokenRefreshPolicy` die de Supabase-session-refresh aanroept als het token binnen N seconden verloopt vóór een backendaanroep. |
| A7 | `lib/features/mirror/widgets/mirror_terminal_export_button.dart` | Exporteer de volledige terminal-log als `.txt`-bestand via `share_plus`, zodat gebruikers lange outputs buiten de 1000-regels-limiet kunnen bekijken. |
| A8 | `server/mirror-shared/lib/mirror.proto` (of `lib/features/mirror/grpc_generated/`) | Voeg het `.proto`-bronbestand toe aan de repository. Voeg een `tool/generate_grpc.sh`-script toe voor deterministisch regereren van `.pb.dart`-bestanden. Zonder dit kan een schema-update stille incompatibiliteit introduceren. |
| A9 | `test/features/mirror/mirror_templates_provider_test.dart` | Voeg unit tests toe voor `mirrorTemplatesProvider`: memory-cache hit, persistent-cache hit, netwerk-onjuiste-versie (cache bypass), en offline fallback. |
| A10 | `docs/MIRROR_RUNBOOK.md` | Operationeel runbook: hoe te debuggen als rate-limit te vroeg triggert, hoe de idempotency tabel te dumpten voor een specifieke gebruiker, hoe de outbox te resetten na circuit-breaker open. |

---

### Verwijderingen (overtollige of vereenvoudigbare code)

| # | Bestand | Wat te verwijderen | Reden |
|---|---------|---------------------|-------|
| D1 | `lib/features/mirror/mirror_signed_inputs_backend.dart` (+ `mirror_secure_apply_service.dart`) | Elimineer `ApplySecurityArtifacts` / `ApplyUploadFailure` / `ApplyUploadFailureCode` duplicate model-klassen. Kies één definitie (recommend: `mirror_secure_apply_service.dart`) en laat `mirror_signed_inputs_backend.dart` ernaar verwijzen. | Twee identieke klassen met verschillende namen verhogen cognitieve last en veroorzaken merge-fouten. |
| D2 | `lib/core/providers/ai_chat_provider.dart` | Verwijder de zinloze `ref.read(aiChatProvider)` aanroep in `openMirrorFromTask()` als die geen side-effect heeft. | Dead code / verborgen side-effect zonder documentatie. |
| D3 | ~~Opgelost~~: documentatie en code gebruiken nu uitsluitend `MirrorGatewayBackend` en `PrivateGrpcBackend` voor Mirror-transport. | — | Naming drift volledig opgeruimd. |
| D4 | `lib/features/mirror/widgets/monaco_editor_host_stub.dart` | Overweeg dit stub-bestand te verwijderen als het nergens geïmporteerd wordt (enkel `monaco_editor_host.dart` barrel + `_io` + `_web` zijn in gebruik). | Dode code verhoogt navigatiekosten. |
| D5 | `lib/features/mirror/services/mirror_editor_run_service.dart` | De budget-preflight dupliceert `MirrorEditorOrchestrationService`. Na refactoring (W1) kan `MirrorEditorRunService` worden omgezet tot een thin wrapper of verwijderd ten gunste van directe aanroep van `MirrorEditorOrchestrationService`. | Overtollige laag met gedeelde verantwoordelijkheid. |

---

## Prioriteit samenvatting

| Prioriteit | Items |
|-----------|-------|
| 🔴 **P0 — Productie-blocker** | W7 (race condition premium/backend), A4 (idempotency tabel cleanup cron), W14 (rate-limit nauwkeurigheid) |
| 🟠 **P1 — Vóór GA** | A1 (go_router deep links), W3 (singleton client DI), W4 (templates provider DI), W6 (voice input veiligheid), W9 (multi-file diff), A8 (proto source + regeneratie script) |
| 🟡 **P2 — Post-launch** | W1, W2, W8, W10, W11, W12, W13, W15, A2, A3, A5, A6, A7, A9, A10, D1–D5 |

---

*Analyse voltooid op basis van volledige codebase-inspectie van Supabase-migraties, Edge Function TypeScript-broncode, Dart/Flutter providers, UI-laag, gRPC-gegenereerde stubs, contracttests en integratiekoppelingen.*
