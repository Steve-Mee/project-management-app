# 075-release-pipeline-preparation

**Priority:** High

**Description:** Prepare complete release pipeline for automated deployments and distribution.

**Acceptance Criteria:**
- [x] DONE: GitHub Releases + changelog (semantic-release)
- [x] DONE: Fastlane for iOS/Android + desktop builds
- [x] DONE: Internal TestFlight / Play Store internal testing setup

**Validation Notes (2026-03-07):**
- Added an auditable release evidence log template to `docs/release-pipeline.md` (release tag, workflow run links/IDs, store evidence, desktop smoke-test evidence).
- Keeps repo-side release preparation verifiable while external store setup remains platform-dependent.