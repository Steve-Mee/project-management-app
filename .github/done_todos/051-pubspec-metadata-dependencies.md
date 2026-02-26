# 051-pubspec-metadata-dependencies

**Priority:** Medium

**Description:** Update pubspec.yaml metadata and dependencies for better project presentation and maintenance.

**Acceptance Criteria:**
- [ ] Change name: my_project_management_app → project_management_app
- [ ] Replace placeholder description: "A new Flutter project." with full description from README.md
- [ ] Change intl: any → intl: ^0.19.0 (or exact version from l10n.yaml)
- [ ] Add homepage: https://github.com/Steve-Mee/project-management-app
- [ ] Add repository: "https://github.com/Steve-Mee/project-management-app"
- [ ] Remove unused deps if present (check with flutter pub deps --style=compact)
- [ ] Run flutter pub get + commit