# Mirror Runner Sandboxing Plan

## Purpose
Strengthen isolation for mirror runner execution while preserving the locked thin-gateway architecture.

## Security Goals
- Enforce tenant isolation across filesystem, process, network, and runtime state.
- Reduce impact radius of runner compromise to a single short-lived job.
- Make isolation controls observable and auditable.

## Current Baseline
- Path and write policy checks exist in runner logic.
- Quotas and cleanup exist, but isolation is primarily policy-driven.
- Strong host-level sandbox boundaries are not yet guaranteed per execution.

## Roadmap

### Phase 0: Immediate Hardening (1-2 sprints)
- Run each job in a dedicated ephemeral workspace with strict cleanup verification.
- Enforce read-only mounts for source inputs where possible.
- Deny all outbound network access by default at runtime.
- Add explicit allowlist for required local services only.
- Add audit events for sandbox violations and denied operations.

### Phase 1: Process Isolation (2-4 sprints)
- Execute jobs in isolated containers/microVMs instead of host process execution.
- Use non-root user, dropped Linux capabilities, and seccomp/AppArmor profiles.
- Enforce CPU, memory, and wall-clock limits with hard kill on overrun.
- Restrict syscalls and block privilege-escalation primitives.

### Phase 2: Filesystem and Artifact Isolation (3-5 sprints)
- Move to per-job ephemeral volumes with no cross-job reuse.
- Separate artifact buckets by function:
  - mirror-signed-inputs for signed input payload staging.
  - mirror-backups for apply backup payloads.
- Add cryptographic integrity checks for staged inputs and produced artifacts.
- Verify zero residual data after job completion (automated post-run attestation).

### Phase 3: Network and Identity Isolation (4-6 sprints)
- Adopt workload identity per job with short-lived credentials.
- Scope credentials to minimum required resources and duration.
- Segment runner network plane from control plane and data plane.
- Add egress proxy policy enforcement with full request logging.

### Phase 4: Supply-Chain and Runtime Assurance (ongoing)
- Sign runner images and enforce signature verification at deploy time.
- Continuously scan dependencies and base images for CVEs.
- Add runtime anomaly detection (unexpected process tree, syscall bursts, egress patterns).
- Run regular red-team style sandbox escape exercises.

## Verification Matrix
- Unit tests for policy enforcement and path traversal rejection.
- Integration tests for per-job isolation and credential scoping.
- Chaos tests for timeout, cleanup failures, and crash recovery.
- Security tests validating blocked syscalls, blocked egress, and denied privilege escalation.

## Exit Criteria
- Insecure host-level execution path disabled in production.
- All production jobs run in isolated runtime boundaries with attested cleanup.
- Security telemetry and audit trails available for every runner execution.
- Incident response playbook validated for sandbox policy violations.
