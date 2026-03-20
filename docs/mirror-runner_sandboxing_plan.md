// ARCHITECTURE LOCK: Mirror Gateway = thin proxy only. Compute always on Fly.io or local runner.
# Mirror Runner Sandboxing Plan

## Purpose
Deliver production-grade isolation for Mirror runner execution while preserving the locked thin-gateway architecture.

Non-goal:
- Move compute into the gateway. The gateway remains a request/auth proxy only.

## Security Objectives

1. Contain untrusted generated code per job boundary.
2. Prevent cross-job data leakage.
3. Enforce least privilege for process, filesystem, and network access.
4. Ensure deterministic cleanup and forensic visibility.

## Baseline And Gaps

Current strengths:
- Path and payload guardrails exist in runner and gateway flows.
- Artifact buckets are separated (`mirror-signed-inputs`, `mirror-backups`).
- Retry and outbox resilience controls are in place.

Current gaps:
- Isolation is not fully boundary-enforced per job.
- Syscall restrictions are not yet codified as versioned security profiles.
- Ephemeral filesystem attestations are not yet mandatory release gates.

## Hardening Roadmap

### Phase P0: Immediate Controls (0-2 sprints)

Scope:
- Enforce production-only transport/runtime guardrails for runner entrypoints.
- Require per-job workspace creation and explicit cleanup verification.
- Mount staged inputs read-only and restrict writable paths to job output/temp only.
- Add telemetry for policy denials, timeout kills, cleanup failures, and process-tree anomalies.

Acceptance criteria:
- 100% of jobs have unique workspace IDs.
- Cleanup verification metric is emitted for 100% of completed jobs.
- No production run path allows insecure dev transport toggles.

### Phase P1: Container Isolation (2-4 sprints)

Scope:
- Execute each job in isolated container/microVM boundary.
- Enforce `runAsNonRoot`, `no-new-privileges`, read-only rootfs, dropped capabilities.
- Apply strict CPU/memory/PID/runtime limits.
- Kill and cleanup on quota/runtime breach with deterministic status codes.

Acceptance criteria:
- 100% production jobs run inside isolated runtime boundary.
- Host process cannot observe or reuse job workspace after completion.
- Stress tests validate quota enforcement and termination correctness.

### Phase P2: Syscall And Process Restrictions (3-5 sprints)

Scope:
- Enforce hardened seccomp profile per runner image.
- Block dangerous primitives: `mount`, `ptrace`, raw sockets, namespace tampering, kernel module interaction.
- Enforce process-tree limits and terminate fork-bomb behavior.
- Prohibit nested runtime/container launches from job payloads.

Acceptance criteria:
- Security regression suite validates blocked syscall families.
- Repeated syscall denial events trigger alerting and incident workflow.
- Process anomaly detection catches and terminates runaway trees.

### Phase P3: Ephemeral Filesystem Guarantees (4-6 sprints)

Scope:
- Use per-job ephemeral volumes with zero cross-job reuse.
- Separate mounts for inputs, outputs, and temp directories.
- Record cleanup attestation (pre/post file inventory hash + deletion confirmation).
- Add artifact integrity checks (input hash verification and output fingerprinting).

Acceptance criteria:
- Residual workspace check passes for 99.99% of jobs.
- Cross-job file reads are impossible by policy and verified by tests.
- All apply-relevant outputs have integrity metadata.

### Phase P4: Identity And Network Isolation (5-7 sprints)

Scope:
- Replace shared runner credentials with short-lived per-job workload identity.
- Enforce bucket/API scope per job principal.
- Default deny network egress; allowlist control-plane endpoints only.
- Route approved egress through policy-aware proxy with audit logs.

Acceptance criteria:
- 0 shared long-lived credentials in job runtime.
- Egress deny-by-default validated in integration tests.
- Network policy exceptions are versioned and reviewable.

### Phase P5: Continuous Assurance (ongoing)

Scope:
- Sign runner images and verify signatures at deploy/boot.
- Enforce CVE scanning gates for base image and dependencies.
- Schedule sandbox escape exercises and policy tightening reviews.
- Maintain security runbook with incident learnings.

Acceptance criteria:
- High/critical CVEs fail release gate unless exception is approved.
- Quarterly sandbox tabletop/red-team exercises completed.
- Drift detection alerts on profile/image mismatch.

## Implementation Tracks

### Track A: Container Isolation Controls
- Runtime profile definitions (dev/staging/prod).
- Resource policy templates and enforcement tests.
- Isolation conformance checks in CI and pre-deploy.

### Track B: Syscall Restriction Program
- Baseline seccomp profile per supported toolchain.
- Denylist for high-risk syscalls and privilege primitives.
- Automated tests for expected deny outcomes.

### Track C: Ephemeral Filesystem Program
- Workspace lifecycle manager with explicit create/teardown contract.
- Read-only input mounts and output-only write surfaces.
- Cleanup attestation persisted with request/trace IDs.

## Operational Metrics And Alerts

Mandatory metrics:
- `mirror_sandbox_policy_denied_total`
- `mirror_sandbox_cleanup_failure_total`
- `mirror_runner_process_tree_killed_total`
- `mirror_runner_ephemeral_workspace_attested_total`
- `mirror_runner_syscall_denied_total`

Alert thresholds:
- Cleanup failures > 0.1% in 15m.
- Syscall denials burst > 50 in 5m per runner instance.
- Workspace attestation missing for any completed production job.

## Test Matrix

- Unit: workspace lifecycle, read-only mounts, identity scoping guards.
- Integration: per-job isolation, egress deny, scoped credentials.
- Security: blocked syscall families, privilege-escalation attempts, process-tree abuse.
- Chaos: forced runner crash, timeout kill, partial cleanup failure.
- Adversarial: cross-job access attempts and artifact tampering.

## Release Gates

Before enabling production-by-default sandbox mode:

- [ ] P1 container isolation controls complete and verified.
- [ ] P2 syscall restriction suite passing in staging.
- [ ] P3 ephemeral FS attestation enabled and dashboarded.
- [ ] Incident runbook updated and exercised.
- [ ] Security sign-off recorded with rollback plan.

## Ownership

- Security owner: Mirror Security Lead
- Platform owner: Runner Platform Lead
- SRE owner: Reliability Lead
- Review cadence: bi-weekly until P4 completion, monthly thereafter
