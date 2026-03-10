# Mirror Feature — Diepgaande Architectuur- en Code Review Analyse

**Datum:** 2026-03-10  
**Reviewer:** Senior Flutter/Supabase Architect  
**Scope:** Volledige Mirror-implementatie (Supabase, Edge Function, gRPC Backend, Dart/Flutter Core, UI, Tests, Docs)  
**Geanalyseerde bestanden:** 45+ bestanden inclusief providers, services, migraties, tests en documentatie

---

### 1. Algemene beoordeling

**Sterke punten**

- **Clean Architecture**: Harde scheiding tussen `MirrorComputeBackend` (abstracte contract), concrete backends (`EdgeFunctionBackend`, `CloudFlyBackend`, `PrivateGrpcBackend`) en de UI-laag. Providers delegeren correct naar services.
- **Uitstekende Offline-First**: `_MirrorOfflineCache`, `MirrorOutboxReplayService`, Hive-boxen voor mode-persistentie, fallback-varianten bij AB-test timeout — allemaal correct geïmplementeerd met exponential backoff.
- **Sterke Security-laag**: Owner-prefixed storage paths (`<auth.uid>/<projectId>/...`), RLS op elke tabel, private buckets, fingerprint-checks bij apply, `ApplySecurityArtifacts` flow voor backup/signed-input staging.
- **Gedifferentieerde Auth-checks**: `MirrorAccessPolicy` is een pure, testbare klasse zonder framework-afhankelijkheden. `MirrorPremiumService` heeft in-flight deduplicatie, TTL-cache (5 min) én metadata-fallback.
- **Realtime Hardening**: Scoped broadcast topics (`mirror_ai_sessions:<uid>:<pid>:<tid>`), debouncing (300 ms), deduplicatie via LRU-achtige event-id set (max 2000 items), per-event char- en linelimieten.
- **Audit Trail**: `mirror_apply_audit_events` tabel met fingerprints (`file_set_fingerprint`, `applied_files_fingerprint`, `diff_fingerprint`), actor-veld, en retentielogica. Volledig SECURITY DEFINER met gefixeerd `search_path`.
- **Goede documentatie**: `mirror-architecture.md`, `mirror-threat-model.md`, `mirror-ops-runbook.md`, `mirror-bucket-contract.md`, `mirror-production-readiness-checklist.md` zijn professioneel en volledig.
- **Brede testcoverage**: Dedicated testbestanden voor realtime dedup, security flow, outbox persistence, apply contract, editor integration en premium service.
- **Compile-fingerprint veiligheidsslot**: Apply wordt geblokkeerd bij fingerprint-mismatch — verhindert "time-of-check to time-of-use" aanvallen op de preview.
- **DB-first template beheer**: `sync_mirror_templates_seed()` stored procedure maakt de database de enige source of truth voor templates.
- **`MirrorAccessPolicy` multi-constraint gate**: Controleert zowel `isPremium` als `runnerModeVariant` AB-variant voordat cloud-mode wordt toegestaan.

**Zwakke punten**

- ~~**Hardcoded Nederlandse tekst in `apply_dialog.dart`**~~: ✅ **Opgelost** — `AppLocalizations` import toegevoegd, beide strings vervangen door `mirrorApplyRiskAcknowledgeTitle` en `mirrorApplyRiskAcknowledgeSubtitle` ARB-keys; alle 13 locales bijgewerkt.
- **`PrivateGrpcBackend` gebruikt `ChannelCredentials.insecure()`**: TLS uitgeschakeld voor alle omgevingen — acceptabel voor localhost dev, maar actief beveiligingsrisico bij Docker/productie.
- **Proto-contract semantisch onjuist**: `Apply(CompileRequest) returns (CompileResponse)` — Apply is een distincte operatie. Hetzelfde type als Compile blokkeert toekomstige apply-specifieke velden en wekt verwarring.
- **`EdgeFunctionBackend` wordt nooit geselecteerd via `mirrorBackendProvider`**: Volledig geïmplementeerd maar niet aangesloten op de provider-routing — onduidelijk gebruik.
- **Dubbele modus-state**: `_selectedMode` (lokale Widget state) en `mirrorProvider.state.mode` (Riverpod) worden handmatig gesynchroniseerd via een `if`-check in `build()`. Fragiel en risico op desync.
- **`MirrorOutboxEntry` slaat broncode op in Hive onbeperkt**: Volledige `context.files` geserialiseerd in outbox — security- en opslagrisico bij grote of gevoelige sessies.
- **`mirrorTemplatesProvider` heeft geen TTL of refresh-strategie**: Enkel `FutureProvider` zonder keepAlive of periodieke invalidatie.
- **Geen client-side rate limiting op generate/compile/apply**: UI blokkeert de knop tijdens een actieve run maar beschermt niet tegen parallelle instanties of snelle navigatieopeenvolging.
- **`MirrorEditorScreen` abonneert niet opnieuw na Supabase reconnect**: Kanaal wordt niet opnieuw gesubscribed bij verbindingsherstel.
- **`supabase/functions/mirror_compute/` ontbreekt in de repository**: Vermeld in docs maar niet aanwezig — risico op deployment-drift.
- **Significante hoeveelheid openstaand productie-readiness werk**: Pen-test, staging rollout, load test, canary, JWT-rotation runbook, GDPR/DSAR — allemaal nog open.

**Overall score (1-10): 7.2 / 10**

De implementatie is kwalitatief sterk voor een feature gebouwd via 36 prompts: architectuurkeuzes zijn verdedigbaar, security is serieus aangepakt, en offline-first coverage is boven gemiddeld. De score wordt gedrukt door de ontbrekende Edge Function in de repo, hardcoded Nederlandse tekst, onveilige gRPC-credentials, semantisch zwak proto-contract, en significante openstaande productie-readiness items.

---

### 2. Laag-voor-laag analyse

**Supabase / Database laag**

`mirror_templates` tabel heeft `template_key` (UNIQUE), `is_active`, `seed_managed` flags en deterministische seed-synchronisatie via `sync_mirror_templates_seed()` stored procedure — solide DB-first patroon. RLS-policies zijn correct: SELECT publiek voor `is_active = true`, write-operaties vereisen `manage_roles` of `manage_users`. `COALESCE(..., false)` beschermt tegen NULL-retournerende permission-functies.

`mirror_apply_audit_events` bevat alle forensische kolommen: `actor_user_id`, fingerprints, `artifact_ids`, `idempotency_key`. Retentiefunctie `cleanup_ai_sessions_retention()` is SECURITY DEFINER met gefixeerde `search_path = public` — correct tegen path-injection. Storage RLS gebruikt `storage.foldername(name)[1] = auth.uid()::text` — correcte owner-bounded bucket toegang.

Scoped broadcast topics (`mirror_ai_sessions:<uid>:<pid>:<tid>`) voorkomen cross-user data leakage. De `realtime.messages` RLS-policy controleert `split_part(realtime.topic(), ':', 2) = auth.uid()::text`.

Aandachtspunten:
- DELETE-policy op `mirror_apply_audit_events` staat gebruikers toe eigen audit-records te verwijderen. Audit events dienen immutable te zijn voor forensische volledigheid. Overweeg de policy te verwijderen en retentie uitsluitend via server-side functie af te handelen.
- Geen composite index op `(user_id, project_id, task_id)` voor queries die op alle drie filteren — meest voorkomend bij audit-lookups.
- Geen `BEFORE UPDATE` trigger op `mirror_templates.updated_at` — handmatige updates via admin-UI updaten de timestamp niet automatisch.
- `project_id` en `task_id` zijn tekstvelden zonder DB-FK naar kernentiteiten — dataintegriteit en cleanup afhankelijk van applicatielogica.

---

**Edge Functions & gRPC backend laag**

`EdgeFunctionBackend` heeft correcte retrylogica met exponential backoff, aparte compile/apply endpoint routing, en fingerprint-verificatie. `CloudFlyBackend` voert dubbele premium-check uit per aanroep — defensief juist. `secureApply()` extension coördineert de volledige security-artifact lifecycle op herbruikbare wijze. `computeCompileResultFingerprint()` sorteert file-entries voor de hash — deterministisch bij volgorde-variaties. `persistApplyToHive()` heeft expliciete budgetlimieten: max 50 files, 100k chars, 40 history entries.

Aandachtspunten:
- `PrivateGrpcBackend` serialiseert naar `utf8.encode(jsonEncode(...))` en stuurt ruwe bytes — JSON-over-raw-bytes in plaats van echte protobuf marshaling. Het proto-bestand is documentatieartifact zonder runtime enforcement.
- `PrivateGrpcBackend.apply()` negeert het `compileFingerprint` argument — de fingerprint-check die in `EdgeFunctionBackend` aanwezig is, ontbreekt hier volledig.
- `ChannelCredentials.insecure()` hardcoded voor alle omgevingen. In Docker/Fly.io-scenario geeft dit onversleuteld verkeer.
- `EdgeFunctionBackend.apply()` heeft een `useSecureApply = false` pad — apply zonder security artifacts. De flag heeft default `true` maar een misconfiguratie kan stille achteruitgang veroorzaken zonder productie-guard.
- `EdgeFunctionBackend` wordt nooit geselecteerd via `mirrorBackendProvider` in `mirror_provider.dart` — de provider kiest altijd `CloudFlyBackend` of `PrivateGrpcBackend`.
- `CloudFlyBackend.apply()` doet een dubbele compile-aanroep (preflight + apply) — verdubbelt compute-kosten per apply.

---

**Dart/Flutter core & providers laag**

`MirrorNotifier` extends `Notifier<MirrorState>` (niet `AsyncNotifier`) — correct voor synchrone UI-beschikbaarheid van state. `_hydrateFromCache()` via `unawaited()` vanuit `build()` houdt de build non-blocking. `refreshPremiumFromMetadata()` invalideert provider en forceert terugval naar private mode als premium verlopen is. `MirrorSessionNotifier` als `FamilyNotifier` met `sessionKey` parameter geeft correcte per-sessie-isolatie. `MirrorAccessPolicy` is een pure Dart-klasse zonder framework-afhankelijkheden. `_MirrorOfflineCache.invalidateOnPremiumChange()` en `invalidateOnAuthChange()` voorkomen premium-spoofing via gestale cache na user-switch.

Aandachtspunten:
- `mirrorModeProvider` is een onafhankelijke `StateProvider<String>` die ook gewatcht wordt door `mirrorProvider.build()`. Wanneer `setMode()` wordt aangeroepen, worden zowel `mirrorModeProvider.state` als `state.mode` bijgewerkt — twee bronnen van waarheid die uit sync kunnen lopen.
- `mirrorBackendProvider` is een `FutureProvider` die opnieuw berekend wordt bij mode-wijziging — maar in-flight aanroepen via de oude backend-instantie worden niet geannuleerd. Race conditions mogelijk bij modus-wisseling tijdens actieve run.
- `MirrorOrchestratorService` accepteert `WidgetRef` als parameter per methode — koppelt de service aan de widget-lifecycle. Gebruik liever `Ref` zodat de service ook buiten widgets testbaar is.
- `unawaited()` fouten worden stilzwijgend gesmoord — overweeg logging via `AppLogger` voor traceerbaarheid in productie.
- `MirrorSessionState.initial()` maakt state aan met lege velden en overschrijft direct via `copyWith()` — semantisch verwarrend, initialiseer direct met correcte waarden.

---

**UI & UX laag (editor, dialogs, realtime)**

`MirrorEditorScreen` is responsief met breakpoint op 900px (Row ↔ Column). `_ModeSelector` is een extracte `StatelessWidget` — clean separation. `TemplatesGallery` past `crossAxisCount` dynamisch aan op breedte. Apply dialog toont diff-preview, branch-suggestie en risico-acknowledgement toggle vóór uitvoering. `_openTemplatesGallery()` gebruikt een `Consumer` voor lazy loading — correcte aanpak. Template laadfout toont een retry-knop die de provider invalideert. Voice input is defensief geïmplementeerd met beschikbaarheidscheck en terminal/SnackBar feedback.

Aandachtspunten:
- ~~**Hardcoded Nederlandse tekst** in `apply_dialog.dart` regels ~105-113~~ — ✅ **Opgelost**: beide strings vervangen door `AppLocalizations.of(context)!.mirrorApplyRiskAcknowledgeTitle` / `mirrorApplyRiskAcknowledgeSubtitle`; keys toegevoegd aan alle 13 ARB-locales.
- `_selectedMode` local state desync: synchronisatie via `if`-check in `build()` is een anti-pattern. Gebruik `ref.listen()` voor side-effect-gebaseerde state updates buiten de build-methode.
- `MirrorEditorScreen` hersubscribert niet na Supabase reconnect — `_subscribeToLiveOutput()` eenmalig in `initState()`. Voeg een `ChannelState`-listener toe voor automatisch herstel.
- `ListView` in file explorer gebruikt `sessionState.files.keys.elementAt(index)` — O(n) indexering. Cache de keys als `List<String>` buiten de builder.
- Geen empty-state voor file explorer wanneer `sessionState.files` leeg is bij hydration-fout.
- Terminal-paneel split 50%/50% — bij smalle viewport geeft dit een slecht bruikbare terminal. Overweeg een draggable splitter of vaste minimale breedte.

---

**Security, permissions & premium checks**

`openMirrorFromTask()` controleert `hasPermissionProvider(AppPermissions.useMirror)` — gating op permissieniveau. `MirrorPremiumService._resolvePremium()` heeft dual-check: eerst metadata, dan `subscriptions` DB-tabel met Stripe-validatie. Apply-flow vereist `acceptRisk` toggle. Signed URLs worden nooit volledig gelogd conform het threat model.

Aandachtspunten:
- `mirrorProvider.build()` leest `isPremium` synchroon via `.valueOrNull ?? false` — UI toont kortdurend "niet-premium" ook als gebruiker premium is. Voeg een `isCheckingPremium` loading state toe.
- `PrivateGrpcBackend` heeft geen token-verificatie — stuurt naar `127.0.0.1:50051` zonder auth-header. Expliciete documentatie en bewaking vereist bij productie.
- `MirrorEditorScreen` heeft geen interne fallback-guard voor de `use_mirror` permissie — als de route direct wordt aangeroepen (deep link, test, toekomstige navigatiewijziging) bestaat er geen scherm-niveau guard.
- Audit DELETE-policy ondermijnt forensische integriteit (zie Database-laag).
- `AppPermissions.useMirror` check is client-side only — Edge Function zou ook permissie moeten valideren via JWT-claims.

---

**Offline / Hive / caching laag**

`_MirrorOfflineCache` gebruikt `EncryptedHiveBox` correct. Offline-fallback cascade voor AB-varianten: live → cache → hardcoded fallback. `MirrorOutboxReplayService` heeft idempotency-sleutels, exponential backoff, connectiviteitsdetectie via `connectivity_plus`, en max retry count — productiewaardig outbox-patroon. `persistApplyToHive()` heeft strakke budgetlimieten.

Aandachtspunten:
- `MirrorOutboxEntry` serialiseert volledige `context.files` — bij grote projecten met gevoelige code worden alle bestanden in memory en op schijf bewaard in de outbox. Overweeg slechts fingerprints/paden op te slaan.
- Geen TTL op gecachte AB-test varianten — gebruiker krijgt verouderde assignment tot een succesvolle live-aanroep. Voeg max-age toe (bijv. 24 uur).
- `_processedRealtimeEventIds` set in `MirrorRealtimeService` kan bij hoge event-frequentie significant geheugen innemen vóór eviction (max 2000 items).
- `appendTerminalLine` accepteert een `maxLines` parameter vanuit de UI — de limiet is UI-bepaald, niet notifier-bepaald. Dit maakt de interface fragiel.
- `mirrorSessionProvider` heeft geen `autoDispose` — bij veel unieke sessies accumuleren notifiers in de Riverpod-container.

---

**Integratie met bestaande app**

`openMirrorFromTask()` in `AiChatBridgeNotifier` is de enige entry point — single responsibility. Integratie in `expandable_task_card.dart` en `project_detail_screen.dart` is consistent via dezelfde navigatieflow. `mirrorSessionProvider` als `FamilyNotifier` met `sessionKey` geeft correcte per-sessie-isolatie. `aiChatBridgeProvider` bewaart de launch-payload voor hernavigatie.

Aandachtspunten:
- `MirrorEditorScreen` heeft geen interne permissiecheck — screen-level guard ontbreekt bij directe route-aanroepen (zie Security-laag).
- `aiChatBridgeProvider` state wordt niet gecleard na succesvolle launch — stale payload kan onbedoelde state veroorzaken bij hernavigatie. `clearMirrorLaunchRequest()` moet expliciet worden aangeroepen na het openen van de editor.
- `mirrorProvider` is een globale `NotifierProvider` — bij multi-project bewerkingen (toekomstige feature) zorgt dit voor mode-conflicten. Overweeg te migreren naar een `FamilyNotifier` op projectId.
- `expandable_task_card.dart` bevat hardcoded Nederlandse strings in de sub-task sectie (`'Sub-tasks'`, `'Generate'`, `'Assign task'`) — pre-existing probleem in hetzelfde bestand als de Mirror-integratiecode.

---

### 3. Concrete aanbevelingen

**Wijzigingen (met exacte bestandsnamen en wat te veranderen)**

~~`lib/features/mirror/apply_dialog.dart` — Vervang de twee hardcoded Nederlandse strings door ARB-lokalisatiekeys.~~ ✅ **Toegepast** (2026-03-10): `AppLocalizations` import toegevoegd, `const Text(...)` vervangen door `Text(AppLocalizations.of(context)!.mirrorApplyRiskAcknowledgeTitle/Subtitle)`, keys `mirrorApplyRiskAcknowledgeTitle`, `mirrorApplyRiskAcknowledgeSubtitle` en `mirrorPermissionDenied` toegevoegd aan alle 13 ARB-locales.

`lib/features/mirror/private_grpc_backend.dart` — Maak TLS credentials configureerbaar door een `ChannelCredentials credentials` constructor-parameter toe te voegen die standaard `ChannelCredentials.insecure()` is maar overschrijfbaar voor productie-deployments.

`lib/features/mirror/private_grpc_backend.dart` — Voeg fingerprint-check toe in `apply()` analoog aan `EdgeFunctionBackend.apply()`: vergelijk `compileFingerprint` met de actuele fingerprint van de compile-aanroep vóór toepassing.

`lib/features/mirror/mirror_editor_screen.dart` — Vervang `_selectedMode` lokale variabele en de `if (_selectedMode != mirrorState.mode)` check in `build()` door een `ref.listen<MirrorState>(mirrorProvider, ...)` in `initState()` zodat mode-updates via een side-effect worden verwerkt.

`lib/features/mirror/mirror_editor_screen.dart` — Voeg een `ChannelState`-listener toe aan het Supabase Realtime kanaal die bij `closed` of `errored` status automatisch hersubscribert via `_subscribeToLiveOutput()`.

`supabase/migrations/20260308_mirror_audit_and_ai_sessions_retention.sql` — Verwijder de `mirror_apply_audit_events_delete_own` policy en verplaats retentie exclusief naar de SECURITY DEFINER retentiefunctie.

`lib/features/mirror/mirror_editor_screen.dart` — Cache `sessionState.files.keys.toList()` buiten de `ListView.builder` itemBuilder voor O(1) indexering in plaats van O(n) `elementAt`.

`lib/features/mirror/edge_function_backend.dart` — Markeer `useSecureApply = false` pad als dev-only via een `assert(!kReleaseMode, ...)` guard zodat het nooit stilzwijgend in productie activeert.

`lib/core/providers/mirror_session_provider.dart` — Voeg `autoDispose` toe aan `mirrorSessionProvider` om geheugenaccumulatie bij meerdere unieke sessies te voorkomen. Pas corresponderende test-overrides aan.

`lib/features/mirror/services/mirror_outbox_replay_service.dart` — Beperk de geserialiseerde `context.files` in `MirrorOutboxEntry` tot fingerprints/paden en haal bestanden pas op bij replay, zodat gevoelige broncode niet onnodig opgeslagen wordt.

`lib/core/providers/mirror_provider.dart` — Verwijder de re-exports van `cloud_fly_backend.dart`, `mirror_compute_backend.dart` en `private_grpc_backend.dart`. Concrete implementaties horen niet publiek beschikbaar te zijn via de provider-module.

---

**Toevoegingen (nieuwe bestanden/features met korte beschrijving)**

`supabase/functions/mirror_compute/index.ts` — Voeg de Edge Function toe aan de repository (momenteel gedocumenteerd maar afwezig). Minimale implementatie: bearer token validatie via `supabase.auth.getUser()`, request body size check (max 512 KB), route naar `/compile` of `/apply` endpoint, `x-request-id` en `x-idempotency-key` propagation, structured error responses. Dit is een **P1 blocker** voor productie.

`lib/features/mirror/mirror_editor_screen.dart` — Voeg een interne permissiecheck toe binnen `build()` als vangnet voor directe route-aanroepen:
```dart
final canUseMirror = ref.watch(hasPermissionProvider(AppPermissions.useMirror));
if (!canUseMirror) {
  return Scaffold(body: Center(child: Text(l10n.mirrorPermissionDenied)));
}
```

`supabase/migrations/20260310_mirror_templates_updated_at_trigger.sql` — `BEFORE UPDATE` trigger op `mirror_templates` die automatisch `updated_at = NOW()` instelt bij elke wijziging.

`supabase/migrations/20260310_mirror_audit_composite_index.sql` — Composite index `(user_id, project_id, task_id, created_at DESC)` op `mirror_apply_audit_events` voor queries die op alle drie kolommen filteren.

`l10n/*.arb` — Voeg ontbrekende lokalisatiekeys toe: `mirrorApplyRiskAcknowledgeTitle`, `mirrorApplyRiskAcknowledgeSubtitle`, `mirrorPermissionDenied`.

`lib/features/mirror/providers/mirror_templates_provider.dart` — Voeg periodieke cache-invalidatie toe via een `Timer` in `FutureProvider.autoDispose` (bijv. elke 30 minuten) zodat templates proactief worden ververst zonder app-herstart.

`server/mirror-shared/proto/mirror.proto` — Consolideer de identieke proto-bestanden van local en cloud runner naar één gedeeld bestand. Definieer separate `ApplyRequest`/`ApplyResponse` types:
```protobuf
message ApplyRequest {
  string prompt = 1; string project_id = 2; string task_id = 3;
  string mode = 4; map<string, string> files = 5;
  string metadata_json = 6; string compile_fingerprint = 7; string backup_id = 8;
}
message ApplyResponse {
  bool success = 1; repeated string applied_files = 2;
  string message = 3; repeated string errors = 4;
}
service MirrorComputeService {
  rpc Compile(CompileRequest) returns (CompileResponse);
  rpc Apply(ApplyRequest) returns (ApplyResponse);
}
```

`.github/workflows/` of CI-configuratie — Lint-check op deprecated bucket-namen (`mirror_staging`, `mirror-staging`) en vergeet `supabase/functions/mirror_compute/index.ts` aan te melden in deployment-CI zodat de afwezigheid van de file een build-fout geeft.

---

**Verwijderingen (wat weg kan en waarom)**

`lib/features/mirror/edge_function_backend.dart` — Verwijder het `useSecureApply = false` code-pad volledig zodra de dev-only use-case is geëlimineerd. Het is een security-achteruitgang zonder productiewaarde.

`lib/core/providers/mirror_provider.dart` — Verwijder `mirrorModeProvider` en `mirrorOfflineWarningProvider` als onafhankelijke `StateProvider`-instanties. Consolideer mode en offline warning volledig in `MirrorNotifier.state` en elimineer de dubbele bronnen van waarheid.

`server/mirror-local-runner/proto/mirror.proto` en `server/mirror-cloud-runner/proto/mirror.proto` — Verwijder beide na consolidatie naar `server/mirror-shared/proto/mirror.proto` (zie Toevoegingen). Twee identieke proto-bestanden veroorzaken onnodige drift bij toekomstige wijzigingen.

`lib/core/providers/mirror_provider.dart` export re-exports (`cloud_fly_backend.dart`, `mirror_compute_backend.dart`, `private_grpc_backend.dart`) — Verwijder de re-exports. Concrete implementaties publiceren via de provider-module doorbreekt encapsulatie en vergroot de publieke API onnodig.

---

## Bijlage: Prioriteringsmatrix

| ID | Item | Bestand | Risico | Prioriteit |
|----|------|---------|--------|-----------|
| W1 | ~~Lokaliseer apply_dialog Nederlandse tekst~~ | `apply_dialog.dart` | ~~Medium (i18n breuk)~~ | ✅ **Opgelost** |
| W2 | Configureerbare TLS in PrivateGrpcBackend | `private_grpc_backend.dart` | Hoog (onversleuteld) | **P1** |
| W6 | Verwijder DELETE op audit-tabel | SQL-migratie | Hoog (audit integrity) | **P1** |
| T1 | Edge Function toevoegen aan repo | `supabase/functions/` | Hoog (deployment drift) | **P1** |
| T2 | Permission guard in MirrorEditorScreen | `mirror_editor_screen.dart` | Hoog (bypass risico) | **P1** |
| W3 | Fingerprint-check in PrivateGrpcBackend.apply() | `private_grpc_backend.dart` | Hoog (TOCTOU) | **P2** |
| W4 | Vervang `_selectedMode` met `ref.listen()` | `mirror_editor_screen.dart` | Medium (state desync) | **P2** |
| W5 | Hersubscribeer Realtime bij reconnect | `mirror_editor_screen.dart` | Medium (stille failures) | **P2** |
| T7 | Fix Apply proto-contract (ApplyRequest/Response) | `mirror.proto` | Medium (semantic debt) | **P2** |
| V2 | Consolideer dubbele mirrorModeProvider | `mirror_provider.dart` | Medium (code kwaliteit) | **P3** |
| T3 | `updated_at` trigger voor mirror_templates | SQL-migratie | Laag (data kwaliteit) | **P3** |
| T5 | TTL op mirrorTemplatesProvider | `mirror_templates_provider.dart` | Laag (versheid) | **P3** |
| V1 | Verwijder `useSecureApply = false` pad | `edge_function_backend.dart` | Medium (security hygiene) | **P3** |
| T6 | Composite index op audit tabel | SQL-migratie | Laag (performance) | **P3** |
| V4 | Consolideer identieke proto-bestanden | `server/*/proto/` | Laag (drift) | **P3** |

## Bijlage: Openstaande Productie-Gate Items (per 2026-03-10)

Op basis van `docs/mirror-production-readiness-checklist.md` zijn de volgende items nog open en blokkeren release:

1. Migration dry-run op staging — deadline 2026-03-18
2. Rollback SQL voor alle Mirror-migraties — deadline 2026-03-20
3. Pen-test voor signed URL leakage en replay — deadline 2026-03-24
4. JWT rotation runbook end-to-end getest — deadline 2026-03-19
5. Load test voor burst compile/apply traffic — deadline 2026-03-27
6. End-to-end staging smoke tests in CI — deadline 2026-03-24
7. Staging rollout met gecombineerde versies — deadline 2026-03-30
8. Canary cohort 24u gemonitord — deadline 2026-03-31
9. GDPR/DSAR procedure gevalideerd — deadline 2026-03-28
10. Observability dashboard live — deadline 2026-03-22

**Aanbeveling**: Items 1, 2, 3, 4 en 5 zijn harde pre-release gates. Zonder deze items is Mirror **niet productierijp** ondanks de sterke implementatiekwaliteit.
