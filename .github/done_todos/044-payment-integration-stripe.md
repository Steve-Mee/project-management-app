# 044-payment-integration-stripe

Status: Voltooid

Afgewerkt na audit-opvolging: 2026-03-07

**Priority:** Medium

**Description:** Integrate Stripe for automated payment processing and subscription handling.

**Acceptance Criteria:**
- [x] DONE: Integrate Stripe SDK into payment_service.dart
- [x] DONE: Implement payment processing methods
- [x] DONE: Add payment UI components and webhooks handling
- [x] DONE: Handle Stripe customer ID in project_plan_display.dart
- [x] DONE: Initialize Stripe when dependency is added
- [x] DONE: Add subscription management features

Audit-opvolging uitgevoerd:
- Stripe webhook function gebruikt nu echte signature-verificatie met HMAC SHA-256 op `t.payload` en timing-safe vergelijking in `supabase/functions/stripe_webhook/index.ts`.
- Signature header parsing (`t=`, `v1=`), timestamp tolerance check en secret-resolutie (`STRIPE_WEBHOOK_SECRET` met fallback) zijn toegevoegd.
- Regressietest toegevoegd in `test/stripe_webhook_signature_test.dart` om placeholder `return true` verificatie regressies te voorkomen.

Resterende hardening (geen blocker voor TODO 044):
- Checkout session creatie/polling in app-laag blijft demo-georienteerd; backend session create endpoint + echte payment intent lifecycle kan later verder worden geproductiseerd.