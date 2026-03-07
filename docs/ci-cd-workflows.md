# CI/CD Workflows

Issue: `#061-github-actions-ci-cd`

This matrix documents which GitHub Actions workflows run, when they run, and
what each workflow validates.

## Workflow Matrix

| Workflow | File | Trigger | Purpose |
|---|---|---|---|
| Flutter Test | `.github/workflows/flutter_test.yml` | `pull_request`, `push` on `main` | Analyze, unit/widget tests, coverage upload, web build, PWA checks |
| Flutter Desktop Build | `.github/workflows/flutter_desktop.yml` | `pull_request`, `push` on `main` | Desktop release builds for Windows/macOS/Linux |
| Semantic PR | `.github/workflows/semantic_pr.yml` | `pull_request` lifecycle events | Enforce conventional PR title semantics |
| Release | `.github/workflows/release.yml` | `push` on `main`, `workflow_dispatch` | Run semantic-release and publish release metadata |

## Notes

- `semantic_pr.yml` and `release.yml` intentionally split responsibilities:
  - PR title quality gate on pull requests.
  - Release automation only on `main` updates/manual dispatch.
- Coverage artifacts are uploaded in `flutter_test.yml` and validated through
  Codecov integration.
- Desktop matrix allows Linux build failures without blocking (`allow_failure`)
  while Windows and macOS remain required.
