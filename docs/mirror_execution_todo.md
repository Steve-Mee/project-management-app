# Mirror Uitvoerings To-Do

Statusdatum: 2026-03-28

## Prioriteit P1/P2

- [x] 1. Orchestration ownership expliciteren
  - Opgeleverd: end-to-end flowmap + owner-matrix in `docs/mirror_orchestration_flowmap.md`.
  - Statusupdate (2026-03-28): `MirrorOrchestratorService` is verder opgeschoond; replay-cache refresh gebeurt niet meer dubbel vanuit orchestrator-callbacks en blijft gecentraliseerd in `MirrorOutboxReplayService`.
  - Resultaat: per flow is nu een primaire owner-service vastgelegd.

- [x] 2. Session provider afronden
  - Doel: resterende provider-transitions expliciet documenteren.
  - Statusupdate: compile-artifact mutatie is ook geëxtraheerd naar `MirrorSessionStateMutationService` en expliciete persist-checkpoints delen nu één helperpad.
  - DoD: provider bevat alleen lifecycle/guards/transitions; services bevatten beslislogica.

- [x] 3. Stale template UX first-class afronden
  - Doel: stale/fresh status nog zichtbaarder en consistenter maken in editor/templates UX.
  - Statusupdate: stale fallback notice toont nu warning + expliciete fallback details (reason/source/age), inclusief cache-age formattering en contracttests.
  - DoD: duidelijke bron/freshness-communicatie + retry-flow + testdekking.

- [x] 4. Editor-shell verder modulariseren
  - Doel: grote schermlogica verder splitsen in panel-owners.
  - Statusupdate: permission-revoked toestand is geëxtraheerd naar `lib/features/mirror/widgets/mirror_permission_revoked_view.dart`, retry-feedback UI naar `lib/features/mirror/widgets/mirror_retry_feedback_card.dart`, file/language/statusline-helperlogica naar `lib/features/mirror/services/mirror_editor_file_presentation_service.dart`, retry-snackbar side effects naar `lib/features/mirror/services/mirror_run_retry_feedback_service.dart`, post-run terminal-analyse (error/completed) naar `lib/features/mirror/services/mirror_run_post_execution_analysis_service.dart`, terminal line mapping/parsing naar `lib/features/mirror/services/mirror_terminal_line_processing_service.dart`, run-start preflight/baseline orchestration naar `lib/features/mirror/services/mirror_run_start_service.dart`, async run-uitvoering + terminal-delta outcome naar `lib/features/mirror/services/mirror_run_execution_service.dart`, run-outcome state-resolutie naar `lib/features/mirror/services/mirror_run_outcome_resolution_service.dart`, run-UI state-transitions naar `lib/features/mirror/services/mirror_run_ui_state_transition_service.dart`, run-completion orchestration naar `lib/features/mirror/services/mirror_run_completion_service.dart`, en run-attempt dispatch/complete keten naar `lib/features/mirror/services/mirror_run_attempt_service.dart`, elk met gerichte testdekking.
  - DoD: gehaald voor huidige scope (screenbestand aantoonbaar gereduceerd; paneel/service-domeinen afzonderlijk testbaar).

## Datalaag Uitvoering

- [x] 5. UUID-hardening verificatie in staging draaien
  - Doel: `tool/run_uuid_hardening_staging.ps1` uitvoeren met echte staging DB connectie.
  - Statusupdate (2026-03-28): op verzoek overgeslagen voor deze uitvoeringsronde.
  - Noot: de daadwerkelijke staging-run blijft vereist voor formele release-GO en moet later alsnog uitgevoerd worden.
  - Unblock command (PowerShell): `$env:STAGING_DATABASE_URL = '<staging-db-url>'; powershell -NoProfile -ExecutionPolicy Bypass -File tool/run_uuid_hardening_staging.ps1`
  - DoD: evidence files gegenereerd en opgeslagen volgens runbook/checklist.

- [ ] 6. UUID-evidence en readiness gates afronden
  - Doel: `docs/mirror_uuid_hardening_execution_log.md` volledig invullen en checklist aftekenen.
  - Statusupdate (2026-03-28): actieve volgende stap; werkartifacts staan in `docs/mirror_go_no_go_snapshot.md`, `docs/mirror_release_signoff_template.md`, `docs/mirror_release_run_order.md` en `docs/mirror_operator_command_pack.md`; uitvoering wacht nog op echte staging/prod SQL evidence en formele approver-signoff.
  - DoD: geen open evidence-gaten voor release-go/no-go.

## Volgorde

1. Taak 6
