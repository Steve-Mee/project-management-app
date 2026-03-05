# App Size Analysis

Issue: `#065-app-size-analysis`
Date: `YYYY-MM-DD`
Branch/Commit: `branch-name @ commit-hash`
Analyst: `name`

---

## 1. Build Command (Exact)

Run this exact command from project root:

```bash
flutter build apk --analyze-size --split-per-abi
```

This generates one APK per ABI and a size analysis report from the same build.

---

## 2. Where to Find Output

### APK files (split per ABI)

Expected output location:

```text
build/app/outputs/flutter-apk/
```

Typical files:

```text
app-armeabi-v7a-release.apk
app-arm64-v8a-release.apk
app-x86_64-release.apk
```

### Analyze-size output

Flutter prints the exact paths in terminal output when build completes.
Paste that section below:

```text
[paste terminal output that includes analyze-size report paths]
```

---

## 3. How to Read the Size Breakdown

Use the generated size report to focus on these areas:

### Dart code
- Look at total Dart AOT snapshot/code size.
- Compare largest packages/libraries before vs after changes.
- Confirm removed/unused packages reduced contribution.

### Assets
- Check image/audio/json and any bundled files.
- Identify oversized files and folders.
- Confirm only required assets are bundled.

### Fonts
- Verify Material/Cupertino/custom fonts included.
- Check whether unused icon/font packages still contribute bytes.
- Confirm custom fonts are expected and actually used.

Paste relevant breakdown snippets:

```text
[DART BREAKDOWN SNIPPET]
```

```text
[ASSETS BREAKDOWN SNIPPET]
```

```text
[FONTS BREAKDOWN SNIPPET]
```

---

## 4. APK Size Results (Per ABI)

Fill in actual sizes from `build/app/outputs/flutter-apk/`.

| ABI | APK File | Size (Bytes) | Size (MB) | Notes |
|---|---|---:|---:|---|
| armeabi-v7a | app-armeabi-v7a-release.apk | `-` | `-` | |
| arm64-v8a | app-arm64-v8a-release.apk | `-` | `-` | |
| x86_64 | app-x86_64-release.apk | `-` | `-` | |

---

## 5. Before/After Comparison Template

Use this table to compare baseline and optimized builds.

| Metric | Before | After | Delta | Delta % | Notes |
|---|---:|---:|---:|---:|---|
| armeabi-v7a APK (MB) | `-` | `-` | `-` | `-` | |
| arm64-v8a APK (MB) | `-` | `-` | `-` | `-` | |
| x86_64 APK (MB) | `-` | `-` | `-` | `-` | |
| Dart code total (KB/MB) | `-` | `-` | `-` | `-` | |
| Assets total (KB/MB) | `-` | `-` | `-` | `-` | |
| Fonts total (KB/MB) | `-` | `-` | `-` | `-` | |

---

## 6. Candidate Contributors and Actions

Track what changed and expected effect.

| Contributor | Status (Used/Unused) | Action Taken | Expected Size Impact | Verified? |
|---|---|---|---|---|
| `cupertino_icons` | `-` | `-` | `-` | `-` |
| `flutter_local_notifications` | `-` | `-` | `-` | `-` |
| `langchain` | `-` | `-` | `-` | `-` |
| `langchain_openai` | `-` | `-` | `-` | `-` |
| `dart_openai` | `-` | `-` | `-` | `-` |
| `flutter_ai_agent_tool` | `-` | `-` | `-` | `-` |
| `legacy_gantt_chart` | `-` | `-` | `-` | `-` |
| `timezone` | `-` | `-` | `-` | `-` |
| `riverpod` (if redundant with `flutter_riverpod`) | `-` | `-` | `-` | `-` |

---

## 7. Paste Raw Evidence

### Full terminal output (build + analyze-size)

```text
[paste full output]
```

### Notes / assumptions

```text
[paste notes]
```

### Final conclusion

```text
[paste summary of what drove size and what was reduced]
```

---

## 8. Acceptance Criteria Checklist (Issue #065)

Mark each item when validated.

- [ ] Build command executed: `flutter build apk --analyze-size --split-per-abi`
- [ ] Before/after table completed with real values
- [ ] Final APK sizes per ABI captured (`armeabi-v7a`, `arm64-v8a`, `x86_64`)
- [ ] Dart code breakdown reviewed and top contributors identified
- [ ] Asset breakdown reviewed and unnecessary assets removed
- [ ] Font/icon breakdown reviewed and unnecessary icon/font packages removed
- [ ] `pubspec.yaml` cleaned (dependencies/assets/fonts aligned with usage)
- [ ] `README.md` updated with app-size analysis summary and rerun command
- [ ] Evidence attached (terminal output + report snippets)

### Verification Snapshot (Current)

- [x] `pubspec.yaml` cleaned for #065 candidate removals
- [x] No custom font files found (`*.ttf`, `*.otf`, `*.woff`, `*.woff2`)
- [x] No `assets/` directory bundle found; only `.env` remains declared
- [x] `README.md` includes `## App Size Analysis (Issue #065)` section

---

## 9. Extra Flutter App Size Tips

- Keep `--split-per-abi` for Android release builds to avoid shipping all native binaries in one APK.
- Keep `--analyze-size` in periodic checks to track regressions by package and asset class.
- Prefer code generation/tree-shakable patterns over broad reflection-like usage where possible.
- Avoid adding large UI/icon packages if Material `Icons.*` already covers requirements.
- Remove unused dependencies and run `flutter pub get` to drop transitive packages from resolution.
- Keep `uses-material-design: true` only if Material icons are actually used.
- Minimize asset bundles: declare only files/folders actually loaded at runtime.
- Compress and resize images before bundling (especially splash/marketing images).
- Audit localization growth: many locales increase code/data size; include only required locales if constraints are strict.
- Re-check release profile after major feature merges to catch size creep early.

---

## 10. Optional CI Automation

You can automate size checks in CI and archive output artifacts.

### Example GitHub Actions step

```yaml
- name: Build APK with size analysis
  run: flutter build apk --analyze-size --split-per-abi

- name: Upload APK artifacts
  uses: actions/upload-artifact@v4
  with:
    name: apk-split-per-abi
    path: build/app/outputs/flutter-apk/*.apk
```

### Optional policy checks

- Fail PR if any ABI APK grows more than `X MB` vs baseline.
- Post a PR comment with before/after ABI sizes and top 5 Dart contributors.
- Keep a rolling baseline artifact from `main` for automatic diffing.
