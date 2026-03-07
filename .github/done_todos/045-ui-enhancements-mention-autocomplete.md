# 045-ui-enhancements-mention-autocomplete

Status: Voltooid

Afgewerkt na audit-opvolging: 2026-03-07

**Priority:** Medium

**Description:** Implement @mention autocomplete functionality in comment sections.

**Acceptance Criteria:**
- [x] DONE: Add autocomplete functionality to comment input in comment_section.dart
- [x] DONE: Integrate with user database for mention suggestions
- [x] DONE: Handle @mention parsing and display in comments
- [x] DONE: Update comment_section.dart with mention support

Audit-opvolging uitgevoerd:
- Submitflow in `lib/features/project/widgets/comment_section.dart` parseert mentions, mapt usernames naar userIds en slaat die op via `commentNotifierProvider`.
- Mention rendering en click/highlight gedrag blijft aanwezig in comment display (`_buildRichTextWithMentions`).
- Testdekking uitgebreid met submit/reload mapping test in `test/comment_section_test.dart` (username -> userId opslag, daarna displaymapping op reload).

Resterende hardening (geen blocker voor TODO 045):
- Mention tap blijft placeholder dialog tot profielnavigatie-route beschikbaar is.