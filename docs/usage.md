# Usage

## Purpose

This guide explains how users work with projects, tasks, and Mirror.

## Project And Task Workflow

1. Create or open a project.
2. Add tasks and assign status/owners.
3. Use dashboard and timeline views for planning.
4. Use AI and Mirror features where enabled by role and feature flags.

## Mirror User Flow

1. Open Mirror from a task or project context.
2. Select available mode (`cloud` or `private`) based on entitlement.
3. Generate or edit content in the workspace.
4. Review compile feedback and diagnostics.
5. Apply changes when output is accepted.

## Access And Premium Behavior

- If premium or permission requirements are not met, cloud mode is restricted.
- The app may downgrade to safe mode automatically.
- Admin-only actions (such as feature flag writes) require elevated role claims.

## Offline Behavior

- Drafts are kept locally to avoid data loss.
- Operations may queue for replay when network is unavailable.
- The app resumes synchronization when connectivity returns.

## Practical Tips

- Prefer small, incremental apply operations.
- Resolve compile diagnostics before apply.
- Keep an eye on mode indicators and warning banners.
- If behavior differs from expectation, check [troubleshooting.md](troubleshooting.md).
