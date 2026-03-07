# Release Pipeline

Issue reference: `#075-release-pipeline-preparation`

## Acceptance Checklist

- [x] GitHub Releases + changelog (semantic-release) - configured
- [x] Fastlane for iOS/Android + desktop builds - configured
- [x] Internal TestFlight / Play Store internal testing setup - configured

## Pipeline Overview

Release automation is split into two workflows:

- `/.github/workflows/release.yml`: runs semantic-release on pushes to `main`.
- `/.github/workflows/fastlane.yml`: runs Fastlane distribution jobs on published GitHub Releases or manual dispatch.

## End-To-End Release Process

1. Create commits using Conventional Commits (`feat:`, `fix:`, `chore:`).
2. Open PR and merge to `main`.
3. Push to `main` triggers `release.yml`.
4. semantic-release determines version bump from commit history.
5. semantic-release updates `CHANGELOG.md`, bumps Flutter app version in `pubspec.yaml`, creates a GitHub Release.
6. Published GitHub Release triggers `fastlane.yml`.
7. Fastlane jobs run:
   - iOS `beta`: builds IPA and uploads to TestFlight internal testers.
   - Android `beta`: builds AAB and uploads to Google Play internal track.
   - Desktop: builds macOS, Windows, and Linux release artifacts.
8. If all distribution jobs succeed, workflow finishes with a smoke-check summary job.

## Manual Beta Release Trigger

Use this when you want to run internal distribution without waiting for a new push:

1. Go to GitHub -> `Actions` -> `Fastlane Distribution`.
2. Click `Run workflow` (`workflow_dispatch`).
3. Select branch `main` and run.
4. The workflow runs:
   - `ios_testflight` (internal TestFlight)
   - `android_internal` (Play internal track)
   - `desktop_builds` (macOS + Windows + Linux)

Optional local manual run (developer machine with Ruby/Fastlane configured):

```bash
bundle exec fastlane beta
```

## Internal Testers Setup

### TestFlight Internal Groups

1. App Store Connect -> your app -> `TestFlight`.
2. Under `Internal Testing`, create groups (example: `QA`, `Product`).
3. Add users from `Users and Access`.
4. Set GitHub secret `TESTFLIGHT_INTERNAL_GROUPS` as comma-separated names, for example `QA,Product`.

### Google Play Internal Track

1. Play Console -> your app -> `Testing` -> `Internal testing`.
2. Create internal release and assign tester list (emails or Google Group).
3. Fastlane uploads from `android beta` lane target `track: "internal"`.

## Required GitHub Secrets

Configure these in `Settings -> Secrets and variables -> Actions`.

iOS/TestFlight:

- `IOS_APP_IDENTIFIER`
- `APPLE_ID`
- `APPLE_TEAM_ID`
- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_API_ISSUER_ID`
- `APP_STORE_CONNECT_API_KEY_CONTENT`
- `IOS_P12_BASE64`
- `IOS_P12_PASSWORD`
- `IOS_MOBILEPROVISION_BASE64`
- `TESTFLIGHT_INTERNAL_GROUPS`

Android/Play:

- `ANDROID_PACKAGE_NAME`
- `SUPPLY_JSON_KEY_BASE64`
- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

Release:

- `GITHUB_TOKEN` (provided automatically by GitHub Actions)

## GitHub Environments

The distribution jobs in `fastlane.yml` target environment `beta`.

Create this in GitHub: `Settings -> Environments -> New environment -> beta`.
Optionally add required reviewers and protection rules for release governance.

## Verification Notes

Repository setup confirms all issue #075 acceptance criteria are implemented in code/config.
Operational success depends on valid signing credentials, store access, and secrets being present in GitHub.

## Go-Live Validation Checklist

Run these once in GitHub Actions before marking pipeline fully production-verified:

1. Merge a test conventional commit (`fix(release): validate pipeline`) into `main`.
2. Confirm `release.yml` creates a new GitHub Release and updates `CHANGELOG.md`.
3. Confirm `fastlane.yml` release trigger runs all jobs successfully.
4. Verify build appears in TestFlight internal group(s).
5. Verify build appears in Google Play internal track.
6. Download one desktop artifact from workflow artifacts and smoke-test launch.

## Release Evidence Log Template

Use `/.github/RELEASE_EVIDENCE_TEMPLATE.md` as the canonical template after
each live distribution run to keep an auditable trail.

Quick table variant (optional):

| Date | GitHub Release Tag | release.yml Run URL/ID | fastlane.yml Run URL/ID | TestFlight Evidence | Play Internal Evidence | Desktop Artifact Evidence | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| YYYY-MM-DD | vX.Y.Z | <link-or-id> | <link-or-id> | <build number / screenshot ref> | <release name / screenshot ref> | <artifact name + smoke test result> | <optional> |

Recommended attachments:

- Screenshot or export from TestFlight internal group build list.
- Screenshot or export from Google Play internal testing release details.
- Link to downloaded desktop artifact validation notes.

## Rollback Runbook

Use this if a release is incorrect or a distribution step fails:

1. Stop rollout in store consoles:
   - TestFlight: expire the faulty build.
   - Play Console: halt rollout or deactivate internal release.
2. Revert offending commit(s) on `main` with a dedicated fix commit.
3. Push fix commit using Conventional Commit format (`fix(release): ...`).
4. Re-run release flow (automatic via push to `main` or manual dispatch for beta distribution).
5. Document incident and root cause in release notes or internal runbook.
