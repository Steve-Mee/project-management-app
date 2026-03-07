# 058-firebase-fcm-only

**Priority:** Low

**Description:** Keep Firebase only for FCM and document the setup properly.

**Acceptance Criteria:**
- [x] DONE: Create supabase_fcm_setup.md with exact Edge Function + Supabase → FCM flow
- [x] DONE: Remove unnecessary Firebase deps if possible (or keep if push notifications work)

**Completion Notes:**
- Added `docs/supabase_fcm_setup.md` with payload contract, Edge Function deployment flow, token-table setup, retry handling, and production secrets checklist.