# 051-pubspec-metadata-dependencies

**Priority:** Medium

**Description:** Update pubspec.yaml metadata and dependencies for better project presentation and maintenance.

**Acceptance Criteria:**
- [x] DONE: Change name: my_project_management_app → project_management_app
- [x] DONE: Replace placeholder description: "A new Flutter project." with full description from README.md
- [x] DONE: Change intl: any → intl: ^0.19.0 (or exact version from l10n.yaml)
- [x] DONE: Add homepage: https://github.com/Steve-Mee/project-management-app
- [x] DONE: Add repository: "https://github.com/Steve-Mee/project-management-app"
- [x] DONE: Remove unused deps if present (check with flutter pub deps --style=compact)
- [x] DONE: Run flutter pub get + commit