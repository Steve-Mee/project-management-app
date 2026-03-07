# 074-pwa-support-web

**Priority:** Medium

**Description:** Add Progressive Web App support for better web experience.

**Acceptance Criteria:**
- [x] DONE: Add web/manifest.json + service worker
- [x] DONE: Test offline mode in Chrome

**Validation Notes (2026-03-07):**
- Clarified that the service worker is Flutter-generated (`flutter_service_worker.js`) during web build, not a hand-authored source file in `web/`.
- Added README discoverability note linking to CI-validated offline support in `docs/pwa-support.md`.