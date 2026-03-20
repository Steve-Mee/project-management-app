// ARCHITECTURE LOCK: Mirror Gateway = thin proxy only. Compute always on Fly.io or local runner.
# Mirror Production SLOs

This document defines the production SLI/SLO/SLA targets for Mirror compile/apply workflows, including alerting thresholds and error-budget policy.

## 1. Service Scope

In scope:
- `POST /functions/v1/mirror-gateway/compile`
- `POST /functions/v1/mirror-gateway/apply`
- End-to-end request path through gateway and runner

Out of scope:
- Local development environments
- Planned maintenance windows announced at least 24 hours in advance
- Third-party incidents where mitigation is impossible and no fallback exists

## 2. SLA And Uptime Targets

External SLA targets:
- Compile API monthly uptime: 99.9%
- Apply API monthly uptime: 99.9%

Internal SLO targets:
- Compile availability: 99.95% (rolling 30 days)
- Apply availability: 99.95% (rolling 30 days)
- End-to-end success rate (non-user-error responses): >= 99.5% (rolling 7 days)

Allowed monthly downtime budget by target (30-day month):
- 99.9%: 43.2 minutes
- 99.95%: 21.6 minutes

## 3. SLI Definitions

### SLI-A: Availability
Definition:
- Ratio of successful requests to total valid requests.

Formula:
- availability = successful_requests / total_valid_requests

Success criteria:
- HTTP 2xx responses from mirror-gateway where upstream work completed.

Excluded from numerator and denominator:
- Requests failing validation due to client input errors (`400`, schema violations).
- Unauthorized/forbidden user entitlement failures (`401`, `403`) when system is healthy.

### SLI-B: Latency
Definition:
- End-to-end request duration measured from gateway ingress to final response.

Targets:
- Compile P95 <= 4.0s, P99 <= 8.0s
- Apply P95 <= 5.0s, P99 <= 10.0s

### SLI-C: Timeout Rate
Definition:
- Percentage of requests ending with timeout-related errors.

Target:
- Timeout ratio < 1.0% over rolling 30 days
- Warning threshold: > 1.0% for 15 minutes
- Critical threshold: > 3.0% for 10 minutes

### SLI-D: Replay Resilience (Internal)
Definition:
- Outbox replay success ratio and breaker stability.

Targets:
- Replay success ratio >= 99.0% per day
- Circuit-breaker open duration < 10 minutes per incident

## 4. Error Budget Policy

Monthly error budget for 99.95% internal availability: 21.6 minutes.

Burn-rate actions:
- Burn >= 10% in 24h:
- Freeze non-critical production changes for Mirror.
- Require SRE + Backend approval for deploys.
- Burn >= 25% in 24h:
- Activate incident mode and mitigation-first policy.
- Pause feature launches impacting compile/apply paths.
- Burn >= 50% in 72h:
- Roll back risky recent changes where feasible.
- Create executive status update and daily recovery review.

## 5. Alerting Requirements

Sev1 (page immediately):
- Availability < 99.0% for 10 minutes
- Timeout ratio > 3.0% for 10 minutes
- Runner unreachable with user-visible errors > 5% for 10 minutes

Sev2 (page within minutes):
- Compile P95 > 6.0s for 20 minutes
- Apply P95 > 8.0s for 20 minutes
- Replay circuit-breaker open state sustained > 10 minutes

Sev3 (ticket):
- Auth denied > 2x baseline for 15 minutes
- Elevated idempotency finalize conflict rate without user-visible failures

## 6. Measurement And Reporting

Data sources:
- Gateway structured logs and metrics
- Runner structured logs and execution metrics
- App observability events with request/trace correlation

Aggregation windows:
- Real-time alerting: 1m and 5m rollups
- Operational review: daily and weekly reports
- SLO compliance report: rolling 30-day dashboard snapshot

Reporting cadence:
- Weekly reliability review for Mirror owners
- Monthly SLA compliance summary for product/engineering leadership

## 7. Incident And Breach Handling

When SLO is breached:
1. Trigger incident process in `docs/mirror-ops-runbook.md`.
2. Declare severity and assign incident commander.
3. Mitigate via rollback, traffic shift, or feature flag as appropriate.
4. Publish customer/internal status updates per severity cadence.
5. Complete postmortem with preventive actions.

When SLA is at risk:
1. Escalate to leadership and support teams.
2. Prioritize customer-impact reduction and communication.
3. Track cumulative downtime against monthly budget.

## 8. Review And Change Control

- Document owner: Mirror Backend Lead
- Reviewers: SRE Lead, Flutter Lead, Security Lead
- Review frequency: monthly or after any Sev1 incident
- Any change to SLO/SLA values requires written approval from Product + Engineering leadership
