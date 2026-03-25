# Mirror Session State Transitions

Doel: expliciet maken welke events in de Mirror session-layer welke state-overgangen veroorzaken.

## Bootstrap Fase-Overgangen

| Event | Van | Naar | Owner |
|---|---|---|---|
| Notifier build start | `initial` | `repositoryLoading` | `MirrorSessionNotifier` |
| Draft/repository data resolved | `repositoryLoading` | `merging` | `MirrorSessionNotifier` |
| Bootstrap assembly success | `merging` | `ready` | `MirrorSessionBootstrapOrchestrationService` + notifier apply |
| Repository timeout/error fallback | `repositoryLoading` / `merging` | `degraded` | `MirrorSessionBootstrapOrchestrationService` + notifier apply |

## In-Session Mutaties

| Event | State impact | Owner |
|---|---|---|
| `selectFile(path)` | `selectedFile` update wanneer path bestaat | `MirrorSessionStateMutationService` |
| `updateSelectedFileContent(content)` | file content + `contextFingerprint` + `contextVersion` | `MirrorSessionStateMutationService` |
| `upsertFileContent(path, content)` | file map + `contextFingerprint` + `contextVersion` | `MirrorSessionStateMutationService` |
| `appendLiveOutput(lines)` | capped `liveOutput` update | `MirrorSessionStateMutationService` |
| `appendTerminalLine(line)` | capped `terminalLog` update | `MirrorSessionStateMutationService` |
| `setCompileValidationArtifacts(...)` | compile fingerprint/token update | `MirrorSessionNotifier` |

## Persistence Lifecycle

| Event | Gedrag | Owner |
|---|---|---|
| Debounced local edit | schedule persist | `MirrorSessionNotifier` |
| `persistOnRunStart()` | immediate flush | `MirrorSessionNotifier` |
| `persistOnApply()` | immediate flush | `MirrorSessionNotifier` |
| `persistOnRouteExit()` | immediate flush | `MirrorSessionNotifier` |
| Persist snapshot compose | files/selected/mode/offline/fingerprint/version | `MirrorSessionPersistenceService` |
| In-flight stale generation | replay decision | `MirrorSessionPersistenceService` |

## Guardrails

- Bootstrap generation guard voorkomt dat oude async resultaten nieuwe state overschrijven.
- Persist target guard voorkomt writes voor verouderde session/generation combinaties.
- `mirror_session_provider.dart` blijft owner van lifecycle/guards; services bevatten pure beslislogica.
