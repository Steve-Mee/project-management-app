# 069-gantt-chart-upgrade

**Priority:** High

**Description:** Upgrade or fork the Gantt chart to modernize it with Material 3 support and better features.

**Acceptance Criteria:**
- [x] DONE: Replace legacy_gantt_chart with gantt_chart or syncfusion_flutter_gantt (or fork + Material 3 update)
- [x] DONE: Ensure dark mode support and touch gestures

**Validation Notes (2026-03-07):**
- Corrected canonical implementation references in `docs/gantt-chart.md` to `packages/pma_core/...` paths.
- Documented drag-to-persistence handoff evidence via existing `ModernGanttChart` commit callback tests.