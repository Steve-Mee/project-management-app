### 1. Algemene beoordeling
- Sterke punten
  - Goede gelaagde opzet: contract/patch/security in `lib/features/mirror/mirror_compute_backend.dart`, transports in `lib/features/mirror/edge_function_backend.dart`, `lib/features/mirror/private_grpc_backend.dart`, `lib/features/mirror/cloud_fly_backend.dart`, state in `lib/core/providers/mirror_provider.dart`, UI in `lib/features/mirror/mirror_editor_screen.dart`.
  - Security-basis is sterk voor een nieuwe AI-feature: `use_mirror` permissiecheck in client-bridge en edge function, owner-scoped storage policies, audit-events met idempotency/request-id in `supabase/functions/mirror_compute/index.ts`.
  - Offline intentie is aanwezig: encrypted Hive cache + TTL + invalidatie op auth/premium wissels in `lib/core/providers/mirror_provider.dart`.
  - Integratie met bestaande app-flow werkt: launch vanuit `lib/features/project/expandable_task_card.dart` en `lib/features/project/project_detail_screen.dart`.
- Zwakke punten
  - Kritieke contractmismatch: runners leveren compile output als signed artifact URL, terwijl Flutter-laag dit als file patch interpreteert. Dit kan file-content corrupt maken bij apply-flow.
  - DB-template laag is niet gekoppeld aan UI: `mirrorTemplatesProvider` bestaat maar `mirror_editor_screen.dart` gebruikt alleen hardcoded `_defaultTemplates`.
  - Inconsistentie in Mirror-storage ontwerp: request noemt `mirror_staging`, maar actieve migraties gebruiken `mirror-signed-inputs` en `mirror-backups`; `mirror_staging` leeft alleen in legacy `supabase_policies.sql`.
  - Deployment docs en runtime-env zijn niet aligned: `server/mirror-cloud-runner/DEPLOY.md` noemt andere secrets dan verplicht in `server/mirror-cloud-runner/lib/main.dart`.
  - Meerdere legacy paden/policies naast migraties (`supabase_setup.sql`, `supabase_policies.sql`) verhogen drift-risico.
- Overall score (1-10)
  - 7.4/10

### 2. Laag-voor-laag analyse
- Supabase / Database laag
  - Positief
  - `mirror_templates` is netjes als tabel + RLS + seed-sync opgezet in `supabase/migrations/20260309_mirror_templates_rls_and_sync.sql`.
  - `mirror_apply_audit_events` + retention job voor `ai_sessions` zijn production-minded in `supabase/migrations/20260308_mirror_audit_and_ai_sessions_retention.sql`.
  - Realtime topic-scoping op `ai_sessions` via broadcast trigger is goed doordacht in `supabase/migrations/20260309_mirror_ai_sessions_broadcast_topics.sql`.
  - Risico's
  - Geen zichtbare migratie voor `CREATE TABLE public.ai_sessions` in `supabase/migrations/**`; feature leunt op eerder/extern schema.
  - `mirror_staging` is niet gemigreerd maar wel in legacy policies (`supabase_policies.sql`), wat operationele verwarring geeft.
  - `mirror_apply_audit_events` heeft geen expliciete retention/cleanup job, terwijl events hard kunnen groeien.

- Edge Functions & gRPC backend laag
  - Positief
  - `supabase/functions/mirror_compute/index.ts` heeft degelijke request-validatie, size-limit (`MAX_REQUEST_BODY_BYTES`), permissiecheck (`has_permission('use_mirror')`), timeout handling en audit writes.
  - `server/mirror-cloud-runner/lib/auth_guard.dart` is degelijk met constant-time checks, kid-mapping en issuer/audience checks.
  - Risico's
  - Kritiek: `server/mirror-local-runner/lib/main.dart` en `server/mirror-cloud-runner/lib/main.dart` zetten response `output` op signed artifact URL; app verwacht patch/content. Hierdoor klopt end-to-end contract niet.
  - Kritiek: `server/mirror-local-runner/docker-compose.yml` zet `ARTIFACT_BASE_URL` naar `http://127.0.0.1:50051/artifacts` terwijl HTTP gateway op 8080 draait; gegenereerde URL is daardoor onbruikbaar.
  - `EdgeFunctionBackend` bestaat, maar wordt niet gekozen in providers (dead path), wat onderhoudslast en verwarring verhoogt.

- Dart/Flutter core & providers laag
  - Positief
  - `MirrorAccessPolicy` in `packages/pma_core/lib/services/mirror_access_policy.dart` is helder en deterministic.
  - `MirrorPremiumService` (`lib/core/services/mirror_premium_service.dart`) heeft in-flight dedupe en cache TTL, goed voor performance.
  - `AiChatBridgeNotifier.openMirrorFromTask` (`lib/core/providers/ai_chat_provider.dart`) gate't netjes op `use_mirror`.
  - Risico's
  - `lib/core/providers/mirror_provider.dart` kiest cloud/private backend, maar Team Mode variant wordt niet functioneel meegenomen in run-context van editor.
  - `_MirrorOfflineCache` kan buiten production fallbacken naar unencrypted Hive; bewust, maar security posture hangt dan af van build flags.
  - `lib/core/hive_initializer.dart` bevat mirror session cache API die niet zichtbaar gebruikt wordt; dode code-route.

- UI & UX laag (editor, dialogs, realtime)
  - Positief
  - Editor is rijk: explorer + Monaco + terminal + live output + voice + template gallery in `lib/features/mirror/mirror_editor_screen.dart`.
  - Apply dialog met risico-ack + diff + branch-advies in `lib/features/mirror/apply_dialog.dart` is UX-technisch sterk.
  - Risico's
  - Kritiek: `_runCurrentFileInTerminal()` bouwt patch-preview uit `compileResult.output`; met huidige runner-contract wordt dit vaak URL-tekst i.p.v. codepatch.
  - `_applyPreviewPatchesToSession` update alleen files die al bestaan; nieuw aangemaakte files uit patches worden genegeerd.
  - Realtime output parse (`versions[].output`) kan bij grote payloads snel veel UI-noise geven; debouncing bestaat, maar server-side compact events zijn nog beter.

- Security, permissions & premium checks
  - Positief
  - Multi-layer gating aanwezig: UI permissies (`use_mirror`), edge permissiecheck, premium policy in provider/backends.
  - Storage RLS voor owner-only upload/select/update/delete op beide buckets is goed afgedekt in `supabase/migrations/20260308_mirror_storage_hardening.sql` en contracttest `test/supabase/mirror_storage_rls_contract_test.sql`.
  - Risico's
  - `mirror_templates` admin check gebruikt JWT app_metadata role-string; zonder gecentraliseerd role-management kan dit fragiel zijn.
  - Private gRPC backend zelf heeft geen extra auth laag; veiligheid hangt volledig af van netwerk-afscherming en launch gating.

- Offline / Hive / caching laag
  - Positief
  - Mirror mode/team variant caching met TTL en auth/premium invalidatie is netjes gedaan.
  - Local apply history/audit fingerprinting in Hive voorkomt onbegrensde plaintext opslag van signed URLs.
  - Risico's
  - `persistApplyToHive()` bewaart nog steeds potentieel veel content (`updatedFiles`) per entry; er is al limiet, maar geen compressie of expliciete size-metrics.
  - Geen duidelijke restore-flow uit `mirror_apply_history` in UI, dus offline herstel is technisch aanwezig maar functioneel beperkt.

- Integratie met bestaande app
  - Positief
  - Integratiepunten zijn coherent en simpel: `openMirrorFromTask` -> `MirrorEditorScreen` vanuit project/task screens.
  - Core app blijft intact; Mirror hangt er modulair naast.
  - Risico's
  - README noemt verouderde integratiepaden; documentatie klopt niet volledig met actuele code.
  - `lib/features/mirror/providers/mirror_templates_provider.dart` is geïmplementeerd maar niet gebruikt in editor flow, wat inconsistentie tussen backend en UX veroorzaakt.

### 3. Concrete aanbevelingen
- Wijzigingen (met exacte bestandsnamen en wat te veranderen)
  - `server/mirror-local-runner/lib/main.dart`
  - Verander compile/apply response contract zodat `output` patch- of file-map JSON bevat (bijv. `{ files: {path: content} }`) i.p.v. signed URL string.
  - Als artifact URLs nodig blijven, zet die in apart veld (`artifactUrl`) en laat `output` de door app verwachte mutatiepayload zijn.
  - `server/mirror-cloud-runner/lib/main.dart`
  - Zelfde contractfix als local runner; compile/apply semantiek moet overeenkomen met `buildPatchesFromApplyPayload()` in Flutter.
  - Voeg expliciete route- of action-splitting toe zodat `Apply` niet simpelweg `compile()` callt.
  - `lib/features/mirror/mirror_editor_screen.dart`
  - In `_runCurrentFileInTerminal()` valideren dat compile-output patchbaar JSON is; anders hard fail met duidelijke melding en geen patch-preview.
  - In `_applyPreviewPatchesToSession()` ook nieuwe files toevoegen aan `state.files` in plaats van alleen bestaande files updaten.
  - `lib/features/mirror/providers/mirror_templates_provider.dart`
  - Maak mapping consistent met DB schema uit `mirror_templates` migratie: gebruik `template_key` als id, `icon_name` voor icon mapping (nu leest code `kind/type`).
  - `lib/features/mirror/mirror_editor_screen.dart`
  - Vervang `_defaultTemplates` als primaire bron met `mirrorTemplatesProvider` + fallback naar defaults bij fetch-fout.
  - `server/mirror-local-runner/docker-compose.yml`
  - Zet `ARTIFACT_BASE_URL` naar de echte HTTP endpoint (`http://127.0.0.1:8080/artifacts` of public gateway URL).
  - `server/mirror-cloud-runner/DEPLOY.md`
  - Update secrets-sectie zodat minimaal deze required vars erin staan: `SIGNED_URL_SECRET`, `MIRROR_SERVICE_TOKEN`, `MIRROR_JWT_SECRET`, `ARTIFACT_BASE_URL`.
  - `supabase_policies.sql`
  - Markeer legacy policies expliciet als deprecated of verwijder Mirror-specifieke blokken die niet meer canoniek zijn (`mirror_staging`, ai_sessions policy duplicaten) om drift te stoppen.

- Toevoegingen (nieuwe bestanden/features met korte beschrijving)
  - `supabase/migrations/20260310_mirror_apply_audit_retention.sql`
  - Nieuwe cleanup functie + pg_cron job voor `mirror_apply_audit_events` (bijv. 30/90 dagen retention) om tabelgroei te beheersen.
  - `test/features/mirror/mirror_backend_contract_test.dart`
  - Contracttest die afdwingt dat elke backend (`EdgeFunctionBackend`, `PrivateGrpcBackend`, `CloudFlyBackend`) patchbare apply payload teruggeeft.
  - `test/features/mirror/mirror_templates_provider_test.dart`
  - Unit tests voor DB-row mapping (`template_key`, `icon_name`, tags parsing) en fallbackgedrag.
  - `docs/mirror-contract.md`
  - Canonieke payload-contractspec voor `generate/compile/apply`, inclusief voorbeelden en required velden per laag.
  - `supabase/migrations/20260310_create_ai_sessions_if_missing.sql`
  - Idempotente baseline migratie voor `public.ai_sessions` (alleen als tabel ontbreekt), zodat nieuwe omgevingen consistent kunnen bootstrapen.

- Verwijderingen (wat weg kan en waarom)
  - `lib/core/hive_initializer.dart` (Mirror session methods) of de ongebruikte Mirror-session functies erin
  - Kan weg als deze cache-route nergens wordt aangesproken; vermindert maintenance en verwarring over de echte offline bron.
  - `lib/features/mirror/edge_function_backend.dart` (indien niet gebruikt)
  - Verwijderen of daadwerkelijk opnemen in providerselectie; nu is het feitelijk dead code.
  - `supabase_policies.sql` Mirror-specifieke legacy blokken (`mirror_staging`, oude ai_sessions policy reset)
  - Weg halen als migraties de enige waarheid zijn; voorkomt dat teams per ongeluk oud beleid opnieuw toepassen.
