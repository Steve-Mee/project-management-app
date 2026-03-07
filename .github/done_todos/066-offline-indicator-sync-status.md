# 066-offline-indicator-sync-status

**Priority:** Medium

**Description:** Add global offline indicator and sync status badge for better user awareness.

**Acceptance Criteria:**
- [x] DONE: Global widget above AppBar (Connectivity + SyncService status)
- [x] DONE: Colors: green (synced), orange (syncing), red (offline)
- [x] DONE: Tap → show last sync time + manual sync button

**Completion Notes:**
- Added `test/offline_indicator_app_bar_test.dart` to validate color mapping and sync sheet interaction flow.