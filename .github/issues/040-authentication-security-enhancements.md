# 040-authentication-security-enhancements

**Priority:** High

**Description:** Enhance authentication security with captcha, rate limiting, and biometric support.

**Acceptance Criteria:**
- [ ] Integrate reCAPTCHA or similar captcha to login screen after 3 failed attempts
- [ ] Implement sliding-window rate limiting (5 attempts per minute) for login
- [ ] Add biometric authentication support using device biometrics
- [ ] Implement proper async checking with settings repository
- [ ] Access settings repository properly for auth configurations
- [ ] Replace placeholder auth in auth_repository.dart with real backend integration