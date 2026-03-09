### 1. Algemene beoordeling
- Sterke punten
- Mirror heeft een duidelijke laagindeling met goede scheiding tussen contract (`lib/features/mirror/mirror_compute_backend.dart`), transport/backends (`lib/features/mirror/edge_function_backend.dart`, `lib/features/mirror/private_grpc_backend.dart`, `lib/features/mirror/cloud_fly_backend.dart`), state-orchestratie (`lib/core/providers/mirror_provider.dart`) en UI (`lib/features/mirror/mirror_editor_screen.dart`).
- De Supabase security-basis is sterk voor een first rollout: owner-scoped RLS voor storage, audittrail voor apply-events, scoped realtime topics en idempotency/request-tracing in de Edge Function (`supabase/migrations/20260308_mirror_storage_hardening.sql`, `supabase/migrations/20260308_mirror_audit_and_ai_sessions_retention.sql`, `supabase/migrations/20260309_mirror_ai_sessions_broadcast_topics.sql`, `supabase/functions/mirror_compute/index.ts`).
- Offline-first intentie is aanwezig en relatief volwassen: cache-hydratatie, TTL, auth/premium invalidatie, AB fallback (`lib/core/providers/mirror_provider.dart`).
- Integratie met bestaande appflow is reeel aanwezig via project- en taakschermen (`lib/features/project/project_detail_screen.dart`, `lib/features/project/expandable_task_card.dart`, `lib/core/providers/ai_chat_provider.dart`).
- Zwakke punten
- Mirror UI is functioneel nog niet end-to-end gekoppeld aan de compute-laag: de editor draait vooral op sessiestate, en de Run-actie is een stub zonder echte compile/apply pipeline (`lib/features/mirror/mirror_editor_screen.dart`).
- Template- en apply-componenten zijn grotendeels losgekoppeld van de editorflow: `TemplatesGallery` en `ApplyDialog` bestaan, maar worden niet door de Mirror editor gebruikt (`lib/features/mirror/templates_gallery.dart`, `lib/features/mirror/apply_dialog.dart`).
- Protocol/contract tussen Edge Function en runners is fragiel: edge verwacht HTTP `/compile` en `/apply`, terwijl runners primair gRPC-methods exposen; dedicated HTTP gateway/adapter is niet zichtbaar in de actieve path (`supabase/functions/mirror_compute/index.ts`, `server/mirror-cloud-runner/lib/main.dart`, `server/mirror-local-runner/lib/main.dart`).
- Er zit duplicatie/tegenstrijdigheid in entitlement- en backendkeuze, inclusief dode codepad (`lib/core/providers/mirror_provider.dart`, `lib/core/services/mirror_premium_service.dart`, `lib/features/mirror/cloud_fly_backend.dart`).
- Verschillende security-fallbacks degraderen naar minder veilige defaults (unencrypted Hive fallback, local dev secret defaults) zonder strikte fail-closed policy (`lib/core/providers/mirror_provider.dart`, `lib/features/mirror/mirror_compute_backend.dart`, `server/mirror-local-runner/docker-compose.yml`).
- Overall score (1-10)
- 7.3/10

### 2. Laag-voor-laag analyse
- Supabase / Database laag
- Positief: RLS op `ai_sessions` en storage-objecten is aanwezig, met owner-folder policies voor mirror buckets (`supabase_policies.sql`, `supabase/migrations/20260308_mirror_storage_hardening.sql`).
- Positief: apply audittable is degelijk opgezet met eventtype-checks, fingerprints, artifact ids, indexed querypaden en RLS per eigenaar (`supabase/migrations/20260308_mirror_audit_and_ai_sessions_retention.sql`).
- Positief: realtime is opgeschaald van broad table luisterpatroon naar topic-scope per user/project/task (`supabase/migrations/20260309_mirror_ai_sessions_broadcast_topics.sql`).
- Risico: `project_id` en `task_id` in mirror audit en ai_sessions-gerelateerde flow zijn tekstvelden zonder FK naar domeintabellen; dat verlaagt data-integriteit en maakt cleanup/joins kwetsbaarder bij refactors (`supabase/migrations/20260308_mirror_audit_and_ai_sessions_retention.sql`).
- Risico: `mirror_templates` RLS vertrouwt op JWT `app_metadata.role = admin`; als rolbeheer in deze app primair via permissies/tables loopt, kan policygedrag afwijken van app-auth model (`supabase/migrations/20260309_mirror_templates_rls_and_sync.sql`, `packages/pma_core/lib/auth/permissions.dart`).
- Risico: schema governance zit verspreid over `supabase_policies.sql` en migrations; canonical source of truth is daardoor niet scherp genoeg voor team/CI deployment.

- Edge Functions & gRPC backend laag
- Positief: `mirror_compute` hanteert auth-check, payloadlimiet, route-validatie, timeout-beheer, structurele errorcodes en audit logging rondom apply (`supabase/functions/mirror_compute/index.ts`).
- Positief: cloud runner heeft expliciete auth guard (service token of JWT-validatie met issuer/audience), plus metrics (`server/mirror-cloud-runner/lib/auth_guard.dart`, `server/mirror-cloud-runner/lib/auth_metrics.dart`).
- Kritiek: endpoint-resolutie in edge kan verkeer naar verkeerde action sturen als env al op `/compile` of `/apply` eindigt; de huidige logic returned het bestaande suffix zonder action-consistentiecheck (`supabase/functions/mirror_compute/index.ts`).
- Kritiek: `main.dart` van cloud/local runners registreert gRPC methods, maar een expliciete HTTP API voor edge forwarding is niet aantoonbaar in de actieve implementatie; `apply_service.dart` bestaat maar is niet aangesloten in de main pipeline (`server/mirror-cloud-runner/lib/main.dart`, `server/mirror-cloud-runner/lib/apply_service.dart`, `server/mirror-local-runner/lib/main.dart`).
- Risico: edge valideert user-auth maar forceert geen server-side check op `use_mirror` permissie; toegangsgating zit nu vooral client-side, wat direct edge-aanroepen onvoldoende begrenst.

- Dart/Flutter core & providers laag
- Positief: Mirror state management is logisch opgebouwd met mode, premiumstatus, team variant en offline warning (`lib/core/providers/mirror_provider.dart`).
- Positief: mode-resolutie via `MirrorAccessPolicy` voorkomt directe cloudtoegang voor non-premium (`packages/pma_core/lib/services/mirror_access_policy.dart`).
- Kritiek: in `mirrorBackendProvider` zit een onbereikbaar pad (`effectiveMode == 'cloud' && !isPremium`) omdat policy cloud naar private degradeert voor non-premium; dit is onderhoudsruis en suggereert onduidelijke intended behavior (`lib/core/providers/mirror_provider.dart`).
- Kritiek: `CloudFlyBackend` gebruikt eigen premiumresolver op metadata (`plan/subscription`) i.p.v. centrale `MirrorPremiumService`; dit kan inconsistent entitlementgedrag veroorzaken tussen providerlaag en backendlaag (`lib/features/mirror/cloud_fly_backend.dart`, `lib/core/services/mirror_premium_service.dart`).
- Risico: lokale audit/history fallback naar onge-encrypte Hive als encryptie-open mislukt; dit botst met security-by-default (`lib/core/providers/mirror_provider.dart`, `lib/features/mirror/mirror_compute_backend.dart`).

- UI & UX laag (editor, dialogs, realtime)
- Positief: editorlayout is responsive en bevat relevante toolingblokken (explorer, editor, terminal, live output, voice) (`lib/features/mirror/mirror_editor_screen.dart`).
- Positief: realtime output heeft debounce + capping, wat memory/jank-risico beperkt (`lib/features/mirror/mirror_editor_screen.dart`).
- Kritiek: compute-integratie ontbreekt in de editorflow; er is geen zichtbare actie die `mirrorBackendProvider`/`generate`/`compile`/`apply` aanroept. Run is momenteel alleen terminaltekst (`lib/features/mirror/mirror_editor_screen.dart`).
- Kritiek: `TemplatesGallery` en `ApplyDialog` zijn losstaande widgets zonder aantoonbare koppeling aan MirrorEditorScreen, waardoor de geclaimde template/apply UX in productiepad incompleet is (`lib/features/mirror/templates_gallery.dart`, `lib/features/mirror/apply_dialog.dart`).
- Risico: MirrorSession start met hardcoded demo files i.p.v. project/task context files; dat wijkt af van “coding studio op echte context” verwachting (`lib/core/providers/mirror_session_provider.dart`).

- Security, permissions & premium checks
- Positief: appniveau toegang tot Mirror is afgevangen via `use_mirror` permissie op meerdere entrypoints (`lib/core/providers/ai_chat_provider.dart`, `lib/core/projects_initializer.dart`, `packages/pma_core/lib/auth/permissions.dart`).
- Positief: cloud runner auth guard gebruikt constant-time vergelijking en JWT-validatie met exp/nbf/iss/aud, wat sterk is voor service hardening (`server/mirror-cloud-runner/lib/auth_guard.dart`).
- Kritiek: security enforcement is niet volledig server-authoritative voor feature permission; edge vertrouwt op “authenticated user” en niet op expliciete permission-claims.
- Kritiek: local runner draait standaard met `SIGNED_URL_SECRET=local-dev-secret`; acceptabel voor lokaal, maar te risicovol als dit per ongeluk in gedeelde omgevingen terechtkomt (`server/mirror-local-runner/docker-compose.yml`).
- Risico: signed artifact links en backup links worden lokaal opgeslagen in apply history; dat vergroot impact bij device compromise (`lib/features/mirror/mirror_compute_backend.dart`).

- Offline / Hive / caching laag
- Positief: mode/team variant cache heeft schema-versioning en TTL; invalidatie op auth/premium changes is netjes (`lib/core/providers/mirror_provider.dart`).
- Positief: apply flow bewaart beperkte history en audit lokaal, nuttig voor debug/recovery (`lib/features/mirror/mirror_compute_backend.dart`).
- Kritiek: encryptie-fallback naar plain Hive is functioneel handig maar security-technisch een downgrade zonder telemetry of hard fail opt-in.
- Risico: updated file snapshots in history kunnen nog steeds fors worden; truncatie bestaat maar geen compressie/scope-level retention per project-user combinatie.

- Integratie met bestaande app
- Positief: openMirrorFromTask is correct geïntegreerd vanuit project details en task cards (`lib/features/project/project_detail_screen.dart`, `lib/features/project/expandable_task_card.dart`, `lib/core/providers/ai_chat_provider.dart`).
- Positief: README bevat Mirror-sectie en benoemt mode/premium/offline intentie (`README.md`).
- Kritiek: in praktijk loopt integratie niet door tot volledige compute/apply in editor; daardoor is de feature technisch gekoppeld maar functioneel nog gedeeltelijk.
- Kritiek: deep link handling in `main.dart` verwerkt alleen invite-token; een expliciete Mirror deep-link routehandler is niet zichtbaar (`lib/main.dart`).

### 3. Concrete aanbevelingen
- Wijzigingen (met exacte bestandsnamen en wat te veranderen)
- [DONE] `supabase/functions/mirror_compute/index.ts`: `resolveForwardEndpoint` action-consistent gemaakt inclusief expliciete deny bij unsupported action-path combinaties.
- [DONE] `supabase/functions/mirror_compute/index.ts`: server-side permissiecheck voor `use_mirror` toegevoegd.
- [DONE] `lib/core/providers/mirror_provider.dart`: onbereikbaar pad `decision.effectiveMode == 'cloud' && !isPremium` verwijderd.
- [DONE] `lib/features/mirror/cloud_fly_backend.dart`: duplicate premiumresolver verwijderd; entitlement via `MirrorPremiumService`.
- [DONE] `lib/features/mirror/mirror_editor_screen.dart`: Run-stub vervangen door echte generate/compile/apply flow met statusfeedback.
- [DONE] `lib/features/mirror/mirror_editor_screen.dart`: `ApplyDialog` gekoppeld met verplichte risk-ack pre-apply.
- [DONE] `lib/core/providers/mirror_session_provider.dart`: sessiebestanden initialiseren vanuit echte project/task context.
- [DONE] `server/mirror-cloud-runner/lib/main.dart`: HTTP ingest/gateway expliciet toegevoegd voor `/compile` en `/apply`.
- [DONE] `server/mirror-local-runner/lib/main.dart`: lokale HTTP parity/gateway toegevoegd voor `/compile` en `/apply`.
- [DONE] `lib/features/mirror/mirror_compute_backend.dart`: encryptie-fallback configureerbaar gemaakt en standaard fail-closed in productie.
- [DONE] `lib/features/mirror/mirror_compute_backend.dart`: signed URLs niet meer raw opgeslagen; fingerprints/identifiers gebruikt.
- [DONE] `README.md`: claims over Mirror entry points/deeplinks en capabilities geactualiseerd.

- Toevoegingen (nieuwe bestanden/features met korte beschrijving)
- [DONE] `lib/features/mirror/providers/mirror_templates_provider.dart`: Riverpod provider toegevoegd voor `mirror_templates`.
- [DONE] `lib/features/mirror/services/mirror_orchestrator_service.dart`: centrale orchestrator toegevoegd.
- [DONE] `test/features/mirror/mirror_editor_integration_test.dart`: integratiegerichte editor test toegevoegd.
- [DONE] `test/features/mirror/mirror_security_flow_test.dart`: security/premium gate test toegevoegd.
- [DONE] `test/supabase/mirror_rls_contract.sql`: RLS-contracttest toegevoegd.
- [DONE] `server/mirror-cloud-runner/lib/http_gateway.dart`: expliciete HTTP endpointlaag toegevoegd.
- [DONE] `docs/mirror-production-readiness-checklist.md`: production readiness checklist aanwezig.

- Verwijderingen (wat weg kan en waarom)
- [DONE] `server/mirror-cloud-runner/lib/apply_service.dart`: verwijderd (dode code opgeruimd).
- [DONE] `server/mirror-local-runner/lib/apply_service.dart`: verwijderd (dode code opgeruimd).
- [NVT] `lib/features/mirror/providers/` lege map verwijderen: map is niet meer leeg na toevoegen `mirror_templates_provider.dart`.
- [DONE] duplicatieve entitlementlogica in `lib/features/mirror/cloud_fly_backend.dart` (`_defaultPremiumResolver`) verwijderd.
