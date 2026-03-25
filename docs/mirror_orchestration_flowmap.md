# Mirror Orchestration Flowmap

Doel: voor iedere primaire Mirror businessflow exact één owner-service vastleggen.

## Owner Matrix

| Flow | Primaire owner | Helpers / adapters |
|---|---|---|
| Launch | `MirrorLaunchCoordinator` | `mirrorBackendProvider`, `mirrorLaunchFailureMessage(...)` |
| Generate | `MirrorApplyFlowCoordinator` | `MirrorOrchestratorService`, `MirrorBackendWorkflows` |
| Compile | `MirrorApplyFlowCoordinator` | `MirrorOrchestratorService`, backend adapters |
| Preview | `MirrorApplyFlowCoordinator` | `MirrorBackendWorkflows` |
| Apply | `MirrorApplyFlowCoordinator` | `MirrorApplyPostHooksService`, backend adapters |
| Replay | `MirrorOrchestratorService` | outbox services + retry/backoff policy |

## End-To-End Flow

1. Entry: launch request vanuit UI gaat naar `MirrorLaunchCoordinator`.
2. Session bootstrap en editorstate worden via session providers/services gehydrateerd.
3. Interactieve generate/compile/preview/apply pipeline wordt beheerd door `MirrorApplyFlowCoordinator`.
4. Transport/retry/replay-resilience loopt via `MirrorOrchestratorService`.
5. Pure patch/transformatie-opbouw blijft in `MirrorBackendWorkflows`.
6. Post-apply side effects blijven in `MirrorApplyPostHooksService`.

## Ownership Regels

- `MirrorApplyFlowCoordinator` is de enige owner van interactieve apply-sequencing.
- `MirrorOrchestratorService` is owner van resilience/replay, niet van UX-sequencing.
- Helpers mogen geen verborgen branching introduceren die owner-beslissingen overschrijft.
- Nieuwe flowstappen moeten eerst aan deze flowmap worden toegevoegd vóór implementatie.

## Open Verfijning

- `MirrorOrchestratorService` verder reduceren naar strikt resiliency/replay waar mogelijk.
- Service-boundary contracttests uitbreiden zodat owner-grenzen regressievast zijn.
