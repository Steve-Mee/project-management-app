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
- `supabase/functions/mirror_compute/index.ts`: corrigeer `resolveForwardEndpoint` zodat action-consistentie wordt afgedwongen. Als endpoint op `/compile` eindigt en action `apply` is, rewrite naar `/apply` (en omgekeerd). Voeg ook expliciete deny toe bij unsupported action-path combinaties.
- `supabase/functions/mirror_compute/index.ts`: voeg server-side permissiecheck toe voor `use_mirror` (bijv. via RPC/claim/role map) voordat forwarding gebeurt.
- `lib/core/providers/mirror_provider.dart`: verwijder onbereikbaar pad `decision.effectiveMode == 'cloud' && !isPremium` of herstructureer policy + backendselectie in een enkele centrale beslisfunctie.
- `lib/features/mirror/cloud_fly_backend.dart`: vervang `_defaultPremiumResolver` door injectie van `MirrorPremiumService` of hergebruik exact dezelfde entitlementbron als providerlaag.
- `lib/features/mirror/mirror_editor_screen.dart`: vervang `_runCurrentFileInTerminal` stub door echte flow die `mirrorBackendProvider` aanroept (generate/compile/apply), status terugkoppelt naar `mirrorSessionProvider`, en fouten zichtbaar maakt in UI.
- `lib/features/mirror/mirror_editor_screen.dart`: koppel `ApplyDialog` aan daadwerkelijke apply-actie en gebruik branche-advies + risk-ack als verplichte pre-apply stap.
- `lib/core/providers/mirror_session_provider.dart`: initialiseer sessiebestanden vanuit project/task context (repository of staging source) in plaats van hardcoded demo files.
- `server/mirror-cloud-runner/lib/main.dart`: maak de HTTP ingest expliciet (of documenteer en implementeer gateway) zodat edge forwarding naar `/compile` en `/apply` contractueel klopt.
- `server/mirror-local-runner/lib/main.dart`: idem als cloud runner voor lokale parity, inclusief e2e testbare `/apply` route.
- `lib/features/mirror/mirror_compute_backend.dart`: maak encryptie-fallback configureerbaar (`failClosedOnEncryptionError`) en standaard fail-closed in production builds.
- `lib/features/mirror/mirror_compute_backend.dart`: sla geen volledige signed URLs op in lokale history/audit; bewaar alleen hash/identifier.
- `README.md`: actualiseer claims over Mirror deep links en editor capabilities zodat documentatie overeenkomt met werkelijke implementatie.

- Toevoegingen (nieuwe bestanden/features met korte beschrijving)
- `lib/features/mirror/providers/mirror_templates_provider.dart`: Riverpod provider die `mirror_templates` uit Supabase laadt, cachet en mapt naar UI-model.
- `lib/features/mirror/services/mirror_orchestrator_service.dart`: centrale orchestrator voor generate/compile/apply, inclusief retries, telemetry, idempotency en mapping naar session state.
- `test/features/mirror/mirror_editor_integration_test.dart`: widget/integration test die end-to-end editoractie naar backendmock valideert (generate, realtime updates, apply).
- `test/features/mirror/mirror_security_flow_test.dart`: test voor permission- en premium-gates (no access, downgraded mode, cloud authorized).
- `test/supabase/mirror_rls_contract.sql` of equivalent migration test: valideer RLS-cases voor `mirror_templates`, `mirror_apply_audit_events`, storage buckets en realtime topics.
- `server/mirror-cloud-runner/lib/http_gateway.dart`: expliciete HTTP endpointlaag voor `/compile` en `/apply` die request-contract met edge function borgt.
- `docs/mirror-production-readiness-checklist.md`: production checklist met security controls, secrets policy, runner hardening, rollout/rollback en observability KPI's.

- Verwijderingen (wat weg kan en waarom)
- `server/mirror-cloud-runner/lib/apply_service.dart`: verwijderen als ongebruikt blijft, of daadwerkelijk integreren; huidige losse aanwezigheid verhoogt complexiteit zonder runtimewaarde.
- `server/mirror-local-runner/lib/apply_service.dart`:zelfde keuze als cloud runner om dode code en contractverwarring te vermijden.
- `lib/features/mirror/providers/` lege map (indien geen lokale providers blijven): verwijderen om structuurruis te beperken.
- Duplicatieve entitlementlogica in `lib/features/mirror/cloud_fly_backend.dart` (`_defaultPremiumResolver`) na centralisatie via provider/service: verwijderen om inconsistent gedrag te voorkomen.
