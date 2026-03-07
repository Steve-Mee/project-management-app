# 061-github-actions-ci-cd

**Priority:** High

**Description:** Set up complete GitHub Actions CI/CD workflows for testing, building and releasing.

**Acceptance Criteria:**
- [x] DONE: .github/workflows/flutter_test.yml (analyze, test, coverage, web build)
- [x] DONE: .github/workflows/flutter_desktop.yml (Windows/macOS/Linux build)
- [x] DONE: .github/workflows/semantic_pr.yml + release.yml (conventional commits)
- [x] DONE: Trigger on pull_request and push main

**Completion Notes:**
- Added `docs/ci-cd-workflows.md` workflow matrix documenting trigger and purpose per CI/CD workflow.