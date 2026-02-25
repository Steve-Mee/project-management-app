# 053-analysis-options-stricter

**Priority:** Low

**Description:** Make analysis_options.yaml stricter to improve code quality and catch more issues.

**Acceptance Criteria:**
- [ ] Add include: package:flutter_lints/flutter.yaml or package:very_good_analysis
- [ ] Enable rules: prefer_const_constructors, prefer_const_declarations, avoid_print: false, use_key_in_widget_constructors: false
- [ ] Run flutter analyze --no-fatal-infos and fix all new warnings