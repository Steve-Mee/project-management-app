# 050-auth-backend-integration

**Priority:** Low

**Description:** Integrate proper backend authentication system (Firebase or similar).

**Acceptance Criteria:**
- [x] DONE: Replace placeholder auth with real backend integration
- [x] DONE: Implement user management methods in i_auth_repository.dart
- [x] DONE: Add sync capabilities for authentication data
- [x] DONE: Update auth_repository.dart with actual backend calls
- [x] DONE: Implement invite user and reset password methods

**Verification Notes:**
- Added `inviteUser(...)` and `resetPassword(...)` to `IAuthRepository` and implemented them in Supabase-backed auth flow.
- `AuthNotifier` now exposes dedicated `inviteUser` and `resetPassword` methods.
- Removed deprecated `authSignInPlaceholder` and `authSignOutPlaceholder` wrappers from `CloudSyncService`.