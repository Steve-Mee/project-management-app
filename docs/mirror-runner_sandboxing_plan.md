// ARCHITECTURE LOCK: Mirror Gateway = thin proxy only. Compute always on Fly.io or local runner.
# Mirror Runner Sandboxing Plan

## Purpose
This roadmap defines production hardening for Mirror runners with a defense-in-depth sandbox model.

Goals:
- Reduce blast radius if runner code execution is abused.
- Enforce least privilege for process, filesystem, network, and secrets.
- Make hardening measurable and auditable per release.

Non-goal:
- Move compute into the gateway. The gateway remains a request/auth proxy only.

## Current Baseline
Current runner architecture:
- Gateway remains a thin authenticated proxy.
- Compute executes only in runner services.
- Request correlation and idempotency controls are already in place.

Baseline gaps this plan addresses:
- Runtime privilege reduction must be explicit and enforced.
- System call and filesystem attack surface must be constrained.
- Outbound network traffic must be strictly allowlisted.
- Resource exhaustion protections must be standardized.
- Key rotation cadence and break-glass procedures must be formalized.

## Threat Model Summary
Primary threats:
- Remote code execution inside runner process.
- Container escape attempts via privileged syscalls/capabilities.
- Data exfiltration via unrestricted egress.
- Lateral movement using stolen credentials.
- Denial-of-service through CPU/memory/file-descriptor exhaustion.

Security principles:
- Fail closed by default.
- Explicit allowlists over implicit deny assumptions.
- Immutable runtime configuration where possible.
- Fast revocation/rotation paths for credentials.

## Production Hardening Roadmap

### Phase 1: Runtime Privilege Controls (P1)
Owner: Security + Platform
Target: Immediate rollout

Controls:
- Run all runner containers as non-root user and non-root group.
- Set no-new-privileges at runtime.
- Drop all Linux capabilities except explicitly required minimum set.
- Prohibit privileged container mode in all environments.

Acceptance criteria:
- Container effective UID is not 0.
- Capability set is empty or documented minimal set.
- CI policy check fails if privileged mode is requested.

Verification:
- Runtime inspect output recorded in deployment artifact.
- Admission/policy checks enforced in deployment pipeline.

### Phase 2: Syscall And MAC Policy Confinement (P1)
Owner: Security Engineering
Target: Next release window

Controls:
- Apply seccomp profile with default-deny posture and explicit syscall allowlist.
- Apply AppArmor profile with filesystem/process/network constraints.
- Block dangerous syscall families not required by runner workload.

Acceptance criteria:
- Runner starts successfully with hardened seccomp profile.
- AppArmor profile is in enforce mode in production.
- Attempted prohibited syscall is denied and logged.

Verification:
- Security integration test validates seccomp/AppArmor deny behavior.
- Incident telemetry includes policy denial counters.

### Phase 3: Filesystem Immutability (P1)
Owner: Platform
Target: Next release window

Controls:
- Use readonly root filesystem for runner containers.
- Mount writable paths only as explicit tmpfs volumes.
- Isolate workspace and temp paths with strict quotas.
- Disable hostPath mounts in production runner specs.

Acceptance criteria:
- Root filesystem mounted read-only.
- Only approved writable mount points exist.
- Write attempts outside allowed paths fail.

Verification:
- Runtime mount table check is part of post-deploy checklist.
- Security smoke test attempts unauthorized write and confirms denial.

### Phase 4: Network Egress Allowlist (P1)
Owner: SRE + Security
Target: Next release window

Controls:
- Enforce egress allowlist at network policy/firewall layer.
- Permit only required destinations:
	- Supabase project endpoints.
	- Required storage hostnames.
	- Explicit internal observability sinks.
- Deny public internet egress by default.

Acceptance criteria:
- Default egress deny policy active.
- Required destinations function without broad exceptions.
- Unauthorized outbound requests are blocked and observable.

Verification:
- Synthetic probe validates blocked egress to non-allowlisted targets.
- Policy-as-code checks validate allowlist drift.

### Phase 5: CPU/Memory/FD Quotas (P1)
Owner: Platform
Target: Immediate and ongoing

Controls:
- Set hard memory limits and conservative CPU quotas for runner containers.
- Configure per-request execution timeouts and concurrency caps.
- Enforce ulimit controls for file descriptors and process counts.
- Add autoscaling guardrails to prevent noisy-neighbor impact.

Acceptance criteria:
- OOM and throttle behavior is deterministic under load tests.
- FD usage remains below threshold under sustained traffic.
- Concurrency limits prevent saturation cascade.

Verification:
- Load and soak tests capture quota breach behavior.
- Alerts exist for memory pressure, FD exhaustion risk, and CPU throttling.

### Phase 6: Key Rotation And Secret Hygiene (P1)
Owner: Security + Backend
Target: Immediate policy; monthly execution

Controls:
- Rotate runner JWT signing/verification keys on fixed cadence.
- Support overlapping keys by key ID for zero-downtime rotation.
- Store secrets only in managed secret store; no plaintext in image/env files.
- Enforce short-lived service tokens where architecture permits.

Acceptance criteria:
- Rotation can be executed without service outage.
- Old keys are revoked after stabilization window.
- Secret access is least-privilege and audited.

Verification:
- Staging rotation drill completed at least monthly.
- Production key age and rotation audit is reviewed in security report.

## Execution Plan And Milestones

### Milestone A (Week 1)
- Non-root runtime and capability drop.
- CPU/memory baseline limits and alerts.
- Initial rotation runbook sign-off.

### Milestone B (Week 2)
- Readonly rootfs and writable mount restrictions.
- Egress allowlist in staging with synthetic validation.

### Milestone C (Week 3)
- Seccomp and AppArmor enforce-mode rollout.
- Production canary and rollback rehearsal.

### Milestone D (Week 4)
- Full production rollout completion.
- Post-implementation security validation and residual risk review.

## CI/CD Policy Gates
Required release blockers:
- Runner image fails if Dockerfile sets root runtime user.
- Deployment manifest fails if privileged mode or broad capabilities are present.
- Release fails if readonly rootfs is disabled in production target.
- Release fails if egress policy is not default-deny.
- Release fails if secret age exceeds rotation policy threshold.

Recommended automation:
- Policy-as-code checks in pull requests.
- Runtime conformance checks during canary.
- Signed attestation artifact attached to release ticket.

## Monitoring And Alerting Requirements
Security telemetry:
- Seccomp/AppArmor deny event rate.
- Egress deny event rate.
- Non-root enforcement violations.
- Secret rotation compliance status.

Reliability telemetry linked to sandboxing:
- Runner OOM kills.
- CPU throttling duration.
- FD usage percentiles.
- Timeout ratio and queue depth.

Alert severities:
- Sev1: sandbox disabled in production, privileged mode detected, key compromise suspected.
- Sev2: repeated policy denials with user impact, rotation overdue beyond policy limit.
- Sev3: drift warnings without active impact.

## Rollback And Break-Glass
Normal rollback:
1. Revert runner to last-known-good hardened image.
2. Keep gateway thin-proxy architecture unchanged.
3. Re-run compile/apply smoke checks and telemetry verification.

Break-glass policy:
- Temporary policy relaxation requires incident commander approval.
- Time-boxed exception with explicit expiry and owner.
- Mandatory post-incident review and re-hardening deadline.

## Ownership And Governance
Primary owners:
- Security Engineering: policy design and validation.
- Platform/SRE: runtime enforcement and operations.
- Mirror Backend: application compatibility and rollout coordination.

Review cadence:
- Weekly during rollout.
- Monthly once steady state is achieved.
- Immediate review after any Sev1/Sev2 sandbox-related incident.

## Definition Of Done
This roadmap is complete when all conditions are met:
- Non-root, seccomp/AppArmor, readonly rootfs, egress allowlist, quotas, and key rotation are enforced in production.
- CI/CD policy gates prevent regression of any required control.
- Runbook and on-call playbooks include sandbox-specific diagnostics.
- Two consecutive monthly reviews show policy compliance and no unresolved high-risk drift.
