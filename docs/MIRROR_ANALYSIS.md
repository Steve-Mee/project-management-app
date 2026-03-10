### 1. Algemene beoordeling
- Sterke punten
  - Duidelijke architectuurgrenzen zijn expliciet vastgelegd en consequent toegepast: de Edge Function blijft een thin proxy, compute draait in runners, en de UI-orchestratie is opgesplitst over dedicated services.
  - De Mirror-flow bevat meerdere security-rails: compile/apply consistency checks, preview fingerprint-validatie, signed-input/backup artifacts, en owner-scoped bucket policies.
  - De implementatie sluit goed aan op bestaande app-patronen: Riverpod providers, pma_core-hergebruik, project/task-bridge via `openMirrorFromTask`, en niet-blokkerende UX-fallbacks.
  - Realtime-architectuur is volwassen: broadcast topics zijn user/project/task-scoped, payload guarding is aanwezig, en deduplicatie is expliciet ingebouwd.
  - Testoppervlak voor Mirror is breed (contract-, integration-, widget- en security-flow tests) en de CI bevat expliciete Mirror checks.
- Zwakke punten
  - Kritieke DB-contract-gap: in de repository ontbreekt een migration voor tabel `mirror_request_idempotency`, terwijl de gateway deze tabel verplicht gebruikt voor claim/finalize logic.
  - Idempotency-end-to-end is functioneel niet volledig: client-side backends sturen geen stabiele `x-idempotency-key` header mee, waardoor outbox-idempotency niet doorloopt tot de gateway-laag.
  - Autorisatie op schermniveau is impliciet via entrypoints; `MirrorEditorScreen` heeft zelf geen harde permission-guard. Directe navigatie/constructie kan daardoor policy-verwarring geven.
  - Caching/offline gedrag is bruikbaar maar kan stale beslissingen geven (AB-variant en modeherstel met TTL) zonder expliciete freshness-contracten met server-timestamps.
  - Consistentiepunt: `CloudFlyBackend` is aanwezig maar niet opgenomen in de actieve backend-selectieflow; dit verhoogt onderhoudslast en ambiguiteit.
- Overall score (1-10)
  - 8.2/10

### 2. Laag-voor-laag analyse
- Supabase / Database laag
  - Positief:
    - Storage hardening is sterk uitgewerkt in `supabase/migrations/20260308_mirror_storage_hardening.sql` met private buckets (`mirror-signed-inputs`, `mirror-backups`) en owner-folder RLS-guards via `storage.foldername(name)[1] = auth.uid()::text`.
    - Audit + retention is aanwezig in `supabase/migrations/20260308_mirror_audit_and_ai_sessions_retention.sql` met indexes, RLS, cleanup-functie en pg_cron scheduling.
    - Realtime topic-scoping is correct in `supabase/migrations/20260309_mirror_ai_sessions_broadcast_topics.sql`.
    - Templates zijn DB-first met RLS en seed-sync in `supabase/migrations/20260309_mirror_templates_rls_and_sync.sql`.
  - Risico's:
    - `mirror_request_idempotency` schema ontbreekt in migraties (niet gevonden in `supabase/migrations/**` of SQL-bestanden), terwijl `supabase/functions/mirror-gateway/index.ts` deze tabel hard vereist.
    - Template-RLS gebruikt `manage_roles` of `manage_users`; dit is functioneel werkbaar maar semantisch grof voor templatebeheer.
  - Integratiekwaliteit:
    - SQL contracttests bestaan (`test/supabase/mirror_storage_rls_contract_test.sql`, `test/supabase/mirror_rls_contract.sql`), wat governance versterkt.

- Edge Functions & gRPC backend laag
  - Positief:
    - `supabase/functions/mirror-gateway/index.ts` heeft sterke request-validatie: auth-check, payload-limiet, normalisatie, structured errors, timeout handling en idempotency-claim/finalize met stale-claim recovery.
    - Runner-architectuur is coherent: `server/mirror-shared/lib/http_gateway.dart` als gedeelde HTTP->gRPC bridge, plus cloud/local runners met auth guard en quota-config.
    - `server/mirror-shared/lib/compile_runner.dart` heeft write-policy controls (prefix-allowlist, denied segments/extensions, max files/bytes).
  - Risico's:
    - End-to-end idempotency-key propagatie ontbreekt client-side; gateway genereert anders nieuwe key per call.
    - CORS in `supabase/functions/_shared/cors.ts` staat op wildcard (`Access-Control-Allow-Origin: *`), wat voor productie meestal te breed is tenzij upstream strikt afschermt.
  - Best-practice fit:
    - gRPC en HTTP gateway layering is goed en schaalbaar; auth_guard in runners is degelijk (JWT/signature/issuer/audience checks).

- Dart/Flutter core & providers laag
  - Positief:
    - `lib/core/providers/mirror_provider.dart` combineert premium, mode-policy, AB-variants en offline fallback op een nette Riverpod-manier.
    - `packages/pma_core/lib/services/mirror_access_policy.dart` centraliseert mode resolution (requested -> effective).
    - `lib/core/providers/mirror_session_provider.dart` hydrateert context netjes uit repositorydata en houdt editor-state coherent.
  - Risico's:
    - Offline variant/mode cache kan stale worden zonder server-side freshness-marker; TTL alleen is niet altijd voldoende bij snelle experimentwissels.
    - `lib/core/auth/permissions.dart` en `packages/pma_core/lib/auth/permissions.dart` bevatten duplicaat `use_mirror` constant.

- UI & UX laag (editor, dialogs, realtime)
  - Positief:
    - `lib/features/mirror/mirror_editor_screen.dart` is effectief als pure UI-shell en gebruikt extracted services (`mirror_editor_run_service.dart`, `mirror_editor_realtime_controller.dart`, `mirror_editor_orchestration_service.dart`).
    - Apply-flow met preview + risk-acknowledgement + suggested branch in `lib/features/mirror/apply_dialog.dart` past bij veilige AI-changes.
    - Realtime-output wordt gedebounced en bounded verwerkt (`mirror_realtime_service.dart`) om UI-spam te beperken.
  - Risico's:
    - `MirrorEditorScreen` bevat geen expliciete eigen permission-guard, dus vertrouwt volledig op correcte entrypoint-routing.
    - `apply_dialog.dart` gebruikt deels hardcoded NL strings/buttons (`Nee`, `Ja, toepassen`, `Git branch advies`) i.p.v. volledige l10n-consistentie met de rest van de app.

- Security, permissions & premium checks
  - Positief:
    - Permission-gating op launchpad is aanwezig via `openMirrorFromTask` (`lib/core/providers/ai_chat_provider.dart`) met `use_mirror` check.
    - Premium gating is aanwezig in provider-policy en cloud backends (`mirror_premium_service.dart`, `mirror_provider.dart`, `cloud_fly_backend.dart`).
    - Apply security artifacts en storage signatures zijn goed afgedicht in `mirror_compute_backend.dart`.
  - Risico's:
    - Premium fallback leunt op metadata wanneer `subscriptions` query faalt; dit is bewust robust, maar kan entitlement drift geven als metadata niet synchroon is.
    - Outbox-opslag valt in fallback naar onversleutelde Hive bij encryptie-falen (`mirror_outbox_replay_service.dart`), anders dan fail-closed pattern in andere Mirror boxes.

- Offline / Hive / caching laag
  - Positief:
    - Duidelijke offline-architectuur met afzonderlijke encrypted boxes, TTL envelopes, auth/premium invalidation, en replay-mechanisme voor outbox.
    - Replay-engine bevat retries, jittered backoff, periodic ticks, en last-write-wins queue semantics.
  - Risico's:
    - Idempotency key wordt wel lokaal berekend voor outbox, maar niet gepropageerd als transport header naar gateway; daardoor is replay minder strikt deduped server-side.
    - Cachingpolicy voor AB-varianten mist expliciete server-version handshakes.

- Integratie met bestaande app
  - Positief:
    - Integratie is netjes via bestaande project/task UI entrypoints:
      - `lib/features/project/project_detail_screen.dart`
      - `lib/features/project/expandable_task_card.dart`
      - bridge: `lib/core/providers/ai_chat_provider.dart`
    - Mirror sluit aan op bestaande task/subtask invalidation na apply (`mirror_orchestrator_service.dart`).
    - README en docs zijn bijgewerkt met architecture lock en operationele contracten.
  - Risico's:
    - Omdat integratie vooral via imperative `Navigator.push` gebeurt, ontbreekt een centrale route guard voor Mirror op app-routingniveau.

### 3. Concrete aanbevelingen
- Wijzigingen (met exacte bestandsnamen en wat te veranderen)
  - `supabase/migrations/20260310_mirror_request_idempotency.sql`
    - Voeg een nieuwe migration toe die `public.mirror_request_idempotency` creëert met unieke sleutel `(user_id, action, idempotency_key)`, `request_hash`, `request_id`, statusvelden, expiry, indexes en RLS-policy passend bij gateway-gebruik.
  - `lib/features/mirror/mirror_gateway_backend.dart`
    - Voeg support toe voor het meesturen van een stabiele idempotency header (`x-idempotency-key`) vanuit context/metadata zodat retries/outbox op gateway-niveau echt idempotent worden.
  - `lib/features/mirror/cloud_fly_backend.dart`
    - Zelfde idempotency-header propagatie als boven; align compile/apply request headers met gateway-contract.
  - `lib/features/mirror/services/mirror_outbox_replay_service.dart`
    - Zet `idempotencyKey` expliciet in `ProjectContext.metadata` bij enqueue/replay zodat backendlaag deze key kan doorgeven aan HTTP requests.
  - `lib/features/mirror/mirror_editor_screen.dart`
    - Voeg een defensieve runtime guard toe voor `use_mirror` (bijv. read-only fallback of snelle exit-snackbar) om directe screen-instantiatie af te dekken.
  - `lib/features/mirror/apply_dialog.dart`
    - Vervang hardcoded NL tekst door `AppLocalizations` keys voor volledige i18n-consistentie.
  - `supabase/functions/_shared/cors.ts`
    - Beperk `Access-Control-Allow-Origin` in productie naar allowlist i.p.v. wildcard, of maak het env-configureerbaar.
  - `lib/features/mirror/providers/mirror_templates_provider.dart`
    - Overweeg paginering/filtering hooks voor grotere template-catalogi en server-side search-optie.
  - `supabase/migrations/20260309_mirror_templates_rls_and_sync.sql`
    - Introduceer meer specifieke template-admin permission (bijv. `manage_templates`) i.p.v. alleen role/user-management permissies.
  - `lib/core/providers/mirror_provider.dart`
    - Voeg freshness metadata toe (bijv. variant timestamp/version) voor betere invalidatie van AB-variant cache na reconnect.

- Toevoegingen (nieuwe bestanden/features met korte beschrijving)
  - `supabase/migrations/20260310_mirror_request_idempotency.sql`
    - Nieuwe canonical migration voor gateway-idempotency contract.
  - `test/supabase/mirror_idempotency_contract.sql`
    - SQL contracttest voor aanwezigheid, constraints, indexes en policies van `mirror_request_idempotency`.
  - `test/features/mirror/mirror_http_idempotency_header_test.dart`
    - Test dat backends bij retries/outbox dezelfde `x-idempotency-key` doorgeven.
  - `test/features/mirror/mirror_permission_guard_test.dart`
    - Widget/integration test die directe opening van Mirror zonder `use_mirror` permission afvangt.
  - `docs/mirror-security-hardening.md`
    - Compact document met CORS-policy, idempotency schema, key rotation, en expected threat mitigations per laag.

- Verwijderingen (wat weg kan en waarom)
  - `lib/features/mirror/cloud_fly_backend.dart`
    - Verwijder of deprecate als de actieve architectuur exclusief `MirrorGatewayBackend` gebruikt voor cloudpad; voorkomt dubbele codepaden en drift.
  - Eén van de dubbele permission-definities:
    - `lib/core/auth/permissions.dart` of `packages/pma_core/lib/auth/permissions.dart`
    - Houd één canonical bron aan om inconsistentie te voorkomen.
  - Legacy/documentaire verwijzingen naar niet-canonieke bucketnamen (zoals `mirror_staging`) buiten compat-notes.
    - Houd naming strak op `mirror-signed-inputs` en `mirror-backups` om operationele fouten te voorkomen.
