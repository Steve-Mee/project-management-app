# Mirror Runner Sandboxing Plan

## Purpose
Strengthen Mirror runner job isolation while preserving the locked thin-gateway architecture: the Mirror Gateway remains a thin proxy and all compute continues to run only on the local or cloud runners.

## Threat Model Focus
- Untrusted or partially trusted generated code executing inside the runner.
- Cross-job data leakage through filesystem reuse, process reuse, or shared credentials.
- Sandbox escape attempts via syscall abuse, privilege escalation, or unexpected network egress.
- Post-job residue that can be replayed, exfiltrated, or influence later executions.

## Current Baseline
- Runner logic already enforces path constraints, quotas, and cleanup attempts.
- Artifact staging is separated into `mirror-signed-inputs` and `mirror-backups`.
- The gateway is not a compute surface and should stay out of the sandbox boundary.
- Production hardening is still incomplete because runner isolation is primarily policy-driven, not boundary-driven.

## Non-Negotiable Target State
- Every production job runs in an isolated runtime boundary.
- Every job gets an ephemeral filesystem and short-lived identity.
- Network egress is denied by default and explicitly allowlisted.
- Privilege escalation primitives and dangerous syscalls are blocked at the runtime boundary.
- Cleanup is verified, not assumed.

## Roadmap

### Phase 0: Immediate Safety Guardrails (0-2 sprints)
Objective: reduce obvious production exposure before deeper sandboxing lands.

- Enforce production guardrails in client and runner entrypoints so insecure development transport or host-style execution paths cannot silently remain enabled.
- Run every job in a unique ephemeral workspace directory with post-run cleanup verification and audit logging on failure.
- Make source inputs read-only wherever possible; only designated output directories remain writable.
- Deny outbound network access by default for job processes and explicitly allow only required control-plane destinations.
- Emit structured security telemetry for sandbox policy denials, cleanup failures, timeout kills, and unexpected process trees.

Deliverables:
- Production guard for insecure gRPC/TLS configuration.
- Verified ephemeral workspace lifecycle with cleanup attestation.
- Baseline security telemetry events for denied operations.

### Phase 1: Container Hardening (2-4 sprints)
Objective: stop treating runner isolation as a convention and move it into runtime boundaries.

- Execute each job in a dedicated container or microVM instead of directly on the host runner process.
- Run as non-root with `no-new-privileges`, dropped Linux capabilities, and read-only root filesystem by default.
- Apply hardened seccomp and AppArmor/SELinux profiles tailored to the allowed compiler/runtime surface.
- Enforce hard CPU, memory, PID, and wall-clock limits with guaranteed kill-and-cleanup behavior on breach.

Deliverables:
- Per-job isolated runtime boundary.
- Hardened container baseline image.
- Resource enforcement documented and tested under stress.

### Phase 2: Syscall and Process Isolation (3-5 sprints)
Objective: make sandbox escapes materially harder even after container breakout attempts.

- Restrict syscalls to the minimum set needed for supported toolchains; explicitly block mount, namespace tampering, raw socket creation, kernel module access, ptrace, and privilege-escalation primitives.
- Forbid nested container runtimes, package manager elevation flows, and background daemon spawning from inside job execution.
- Monitor and terminate anomalous process trees, fork bombs, or suspicious syscall bursts.

Deliverables:
- Maintained syscall allowlist/denylist per supported runner image.
- Sandbox escape detection hooks.
- Security regression suite for blocked syscalls and forbidden process behavior.

### Phase 3: Ephemeral Filesystem and Artifact Integrity (4-6 sprints)
Objective: guarantee that filesystem state is isolated per job and artifacts are trustworthy.

- Move to per-job ephemeral volumes with zero cross-job reuse.
- Mount output and temp paths separately from staged inputs to simplify policy and cleanup validation.
- Add cryptographic integrity verification for staged inputs and produced outputs before apply/backup flows continue.
- Verify and record zero residual data after job completion through automated post-run attestation.

Deliverables:
- Per-job ephemeral storage boundary.
- Artifact integrity checks for staged inputs and outputs.
- Cleanup attestation records linked to runner telemetry.

### Phase 4: Identity and Network Isolation (5-7 sprints)
Objective: prevent compromised jobs from laterally moving through credentials or network reachability.

- Issue short-lived workload identity per job instead of shared runner credentials.
- Scope every credential to the minimum buckets, queues, and APIs required for that job only.
- Segment runner network plane from storage/control-plane services.
- Route any allowed egress through a policy-enforcing proxy with request logging and anomaly detection.

Deliverables:
- Per-job scoped identity.
- Default-deny egress posture with audited exceptions.
- Network segmentation diagram and enforcement tests.

### Phase 5: Supply Chain and Runtime Assurance (ongoing)
Objective: keep the sandbox trustworthy over time, not just at launch.

- Sign runner images and enforce signature verification before deployment.
- Continuously scan base images and dependencies for CVEs.
- Add runtime anomaly detection for process tree drift, syscall spikes, suspicious egress, and repeated sandbox denials.
- Run scheduled sandbox escape exercises and feed results back into profile tightening.

Deliverables:
- Signed runner images.
- Continuous vulnerability monitoring.
- Operational playbook for sandbox incidents.

## Verification Matrix
- Unit tests for path enforcement, workspace lifecycle, and artifact integrity guards.
- Integration tests for per-job isolation, cleanup attestation, and credential scoping.
- Security tests validating blocked syscalls, blocked egress, denied privilege escalation, and forbidden process creation.
- Chaos tests for timeout handling, cleanup failures, crashed workers, and leaked temp directory simulation.
- Red-team scenarios for attempted escape, cross-job read access, and artifact tampering.

## Production Exit Criteria
- No production job executes directly on a shared host context without an isolated runtime boundary.
- Insecure development transport and host-style execution paths are blocked in production.
- Every production job uses ephemeral filesystem state, short-lived identity, and verified cleanup.
- Security telemetry and audit trails exist for all runner executions and denial events.
- Incident response runbook is tested against sandbox policy violation scenarios.
