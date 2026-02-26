# 071-feature-flags-supabase

**Priority:** Low

**Description:** Implement feature flags system using Supabase for dynamic feature control.

**Acceptance Criteria:**
- [ ] Create FeatureFlagProvider that reads supabase.from('feature_flags').select() + cache
- [ ] Use in AI, Gantt, onboarding etc.