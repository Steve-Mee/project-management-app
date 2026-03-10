// ARCHITECTURE LOCK: Mirror Gateway = thin proxy only. Compute always on Fly.io or local runner.
# Mirror Bucket Contract

## Purpose
Mirror uses Supabase Storage for signed input artifacts and backup artifacts.

This document defines canonical bucket names and object-path rules to remove naming drift and eliminate ambiguity with legacy names such as `mirror_staging`.

## Scope
The bucket contract in this document covers:

- Canonical bucket names for Mirror storage
- Allowed object path format
- Deprecated and forbidden names
- Policy and operational validation checks

## Canonical Buckets
Use only these bucket names for Mirror:

- `mirror-signed-inputs`
- `mirror-backups`

### Bucket Responsibilities
- `mirror-signed-inputs`:
- Temporary signed-upload/download artifacts used by compile/apply request flows
- Input payload staging for runner consumption

- `mirror-backups`:
- Backup artifacts created before or during apply flows
- Recovery assets referenced by audit and rollback operations

## Non-Canonical Names
The following names are deprecated for Mirror and must not be used in new code, migrations, runbooks, or dashboards:

- `mirror_staging`
- `mirror-staging`
- `mirror-inputs`
- Any ad-hoc mirror bucket alias not listed in this contract

If historical references exist, treat them as migration debt and map them to canonical names.

## Object Path Contract
All Mirror objects must use owner-prefixed path segments:

- `<auth.uid>/<projectId>/<taskId>/<artifactId>/(input|backup)/<filePath>`

### Required Rules
- First path segment must equal authenticated user id (`auth.uid`)
- `projectId` and `taskId` must match request scope
- `artifactId` must be unique per operation lifecycle
- `input` subfolder is valid only in `mirror-signed-inputs`
- `backup` subfolder is valid only in `mirror-backups`

## Access Policy Contract
- Buckets are private
- RLS policies enforce owner-folder boundary via `storage.foldername(name)[1] = auth.uid()::text`
- Service-role operations are restricted to edge/runner infrastructure only
- Signed URL generation must target one object path and one method per token

## Signing Contract
- Default signed URL TTL target: <= 5 minutes
- Do not store or log full signed URLs
- Signed URL responses must include correlation metadata (`x-request-id`, idempotency context)

## Migration And Cleanup
### Required Migration Actions
1. Replace any `mirror_staging` references in scripts/runbooks/config with canonical names.
2. Move or rehydrate artifacts from deprecated buckets when retention requirements require it.
3. Update monitoring dashboards to canonical bucket labels only.
4. Validate RLS policies after migration using owner and non-owner test identities.

### Verification Queries
- Confirm canonical buckets exist and are private.
- Confirm policy set exists for insert/select/update/delete.
- Confirm no active writes to deprecated bucket names.

## CI/Docs Contract Checks
Documentation and CI checks should fail when:

- New references to deprecated bucket names are introduced
- Canonical names are missing from runbook or setup docs
- Object path examples omit `auth.uid` owner prefix

## Related Documents
- `docs/mirror-architecture.md`
- `docs/mirror-ops-runbook.md`
- `docs/mirror-threat-model.md`
- `docs/mirror-production-readiness-checklist.md`
- `README.md`
