# Supabase FCM Setup

Issue: `#058-firebase-fcm-only`

This document describes the exact Supabase -> FCM flow used by this app.
The Flutter app remains FCM-only on the client side (`firebase_core` +
`firebase_messaging`). Notification fan-out is handled by a Supabase Edge
Function.

## Current Runtime Flow

1. App startup initializes Firebase Core + Messaging in `lib/main.dart`.
2. Comment mentions trigger push delivery in
   `packages/pma_core/lib/providers/comment/comment_providers.dart`.
3. The provider invokes Supabase Edge Function `send-push-on-mention`.
4. Edge Function resolves mentioned user IDs to FCM tokens and sends payloads.

Current invoke payload from app code:

```json
{
  "commentId": "<uuid>",
  "mentionedUsers": ["<user_id>", "<user_id>"],
  "commentText": "<comment text>",
  "projectId": "<uuid|null>",
  "taskId": "<uuid|null>"
}
```

## Required Supabase Objects

### 1. Device token table

Create a table to map users to FCM tokens.

```sql
create table if not exists public.user_push_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  fcm_token text not null,
  platform text,
  updated_at timestamptz not null default now(),
  unique(user_id, fcm_token)
);

alter table public.user_push_tokens enable row level security;

create policy if not exists "user_push_tokens_select_own"
on public.user_push_tokens
for select
using (auth.uid() = user_id);

create policy if not exists "user_push_tokens_upsert_own"
on public.user_push_tokens
for insert
with check (auth.uid() = user_id);

create policy if not exists "user_push_tokens_update_own"
on public.user_push_tokens
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);
```

### 2. Edge Function: `send-push-on-mention`

Create function folder:

`supabase/functions/send-push-on-mention/index.ts`

Expected responsibilities:

- Validate authenticated caller.
- Validate body keys: `commentId`, `mentionedUsers`, `commentText`.
- Read matching tokens from `user_push_tokens`.
- Send HTTP requests to FCM HTTP v1 API.
- Return summary (`sent`, `failed`, `invalidTokens`).

## FCM Credentials for Edge Function

Store these secrets in Supabase project secrets:

- `FCM_PROJECT_ID`
- `FCM_CLIENT_EMAIL`
- `FCM_PRIVATE_KEY`

Set with CLI:

```bash
supabase secrets set FCM_PROJECT_ID="<project-id>"
supabase secrets set FCM_CLIENT_EMAIL="<service-account-email>"
supabase secrets set FCM_PRIVATE_KEY="<private-key-with-newlines>"
```

## Deploy Function

```bash
supabase functions deploy send-push-on-mention
```

## Retry And Failure Handling

- Client behavior:
  - Notification failures do not block comment creation.
  - Errors are logged via `AppLogger` in `CommentNotifier._sendMentionNotifications`.
- Function behavior recommendation:
  - Retry transient `429/5xx` with exponential backoff (max 3 attempts).
  - Remove or mark invalid tokens on `UNREGISTERED` / `INVALID_ARGUMENT`.
  - Return partial success rather than failing whole batch.

## Verification Checklist

- `flutter analyze` passes.
- `test/firebase_fcm_only_test.dart` passes.
- Mentioning a user triggers `send-push-on-mention` in Supabase logs.
- At least one device receives a mention notification in staging.
- Invalid token cleanup path confirmed in function logs.

## Notes

- The repository currently contains `invite-user` and `stripe_webhook` Edge
  Functions; `send-push-on-mention` should be added as part of notification
  infrastructure rollout if not already deployed in Supabase.
- Keep Firebase dependencies scoped to messaging use-cases only.
