# Offline-First

## Objectives

The offline-first design preserves user progress during degraded or disconnected network conditions while preserving security and consistency.

## Core Mechanisms

- Draft cache: local persistence of in-progress Mirror and task content
- Outbox: queued operations pending network recovery
- Replay engine: retry with bounded backoff and circuit-breaker controls
- Encrypted local storage: Hive-based persistence for sensitive state

## Draft Cache

Drafts are persisted locally to avoid data loss during app restarts, connectivity interruption, or backend timeout windows.

Expected behavior:

- Cache-first hydration on startup
- Background refresh from remote data when available
- Explicit state markers for stale or degraded sessions

## Outbox And Replay

Outbox responsibilities:

- Store deferred operations with metadata and retry schedule
- Prevent duplicate replay using request identity and idempotency metadata
- Track replay success/failure and escalate on repeated failure

Replay behavior:

- Retries use bounded exponential backoff with jitter
- Timeout and repeated failure transition to circuit-breaker open state
- Recovery resumes once dependencies are healthy

## Encryption And Failure Policy

- Sensitive local data is stored in encrypted Hive boxes when encryption initialization succeeds
- Production policy should fail closed on encryption initialization failure for critical data paths
- Non-production environments may allow reduced-security fallback for debugging

## Operational Controls

- Monitor replay queue depth and replay failure ratio
- Alert when breaker-open duration exceeds threshold
- Verify that offline warning state is surfaced in UI for user awareness

## Validation Checklist

- Simulate network loss during compile/apply
- Confirm draft recovery after restart
- Confirm outbox drain after reconnection
- Confirm no duplicate apply effects after replay
