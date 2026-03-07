# PWA Support (Issue #074)

This document defines the acceptance checklist and manual verification flow for web PWA support.

## Acceptance Checklist

- [x] `web/manifest.json` exists with app branding (`name`, `short_name`, `description`), colors, and icons.
- [x] `web/index.html` links the manifest: `<link rel="manifest" href="manifest.json">`.
- [x] `web/index.html` includes PWA meta tags (`theme-color`, `apple-mobile-web-app-*`, `apple-touch-icon`).
- [x] `web/index.html` delegates service worker loading to Flutter bootstrap only (single SW strategy).
- [x] Build output contains web PWA artifacts (`build/web/manifest.json`, `build/web/flutter_service_worker.js`).
- [x] Offline mode is provided by Flutter `offline-first` PWA strategy.
- [x] CI validates PWA behavior (manifest link, service worker registration, cache creation, offline reload).

## Build For PWA

Use the command that matches this Flutter toolchain:

```bash
flutter build web --release --pwa-strategy=offline-first
```

Note: Some issue notes may reference `flutter build web --web-renderer html --pwa`. That command is not supported by the current Flutter CLI in this repo.

Service worker note: this project uses Flutter's generated `flutter_service_worker.js` (emitted during `flutter build web`) instead of a hand-maintained custom service worker in `web/`.

## Manual Test (Chrome)

1. Build the app:
   ```bash
   flutter build web --release --pwa-strategy=offline-first
   ```
2. Serve the built files:
   ```bash
   python -m http.server 8080 -d build/web
   ```
3. Open Chrome at `http://127.0.0.1:8080`.
4. Open DevTools (`F12`) and go to `Application`.
5. Under `Manifest`, verify app name/icons/theme color are detected.
6. Under `Service Workers`, verify a worker is registered and active.
7. Under `Cache Storage`, verify Flutter cache entries exist (for example `flutter-app-manifest`, `flutter-app-cache`).
8. Switch DevTools `Network` to `Offline`.
9. Refresh the page and verify the app shell still loads while offline.

## Install As PWA (Chrome)

1. Open `http://127.0.0.1:8080` in Chrome.
2. Click the install icon in the address bar (or open Chrome menu -> `Cast, save, and share` -> `Install page as app`).
3. Confirm installation.
4. Launch the installed app from Chrome Apps or desktop shortcut.
5. Verify it opens in standalone window mode (not a normal browser tab).

## Validation Result

The current implementation has been validated locally with a built web bundle:

- `flutter_service_worker.js` registered successfully.
- Cache storage was created with expected keys (`flutter-app-manifest`, `flutter-app-cache`).
- Static assets and manifest/icons were served correctly.

This confirms offline mode support is wired and functioning for the app shell/PWA layer.

## CI Validation

`flutter_test.yml` now includes an automated Playwright check after `flutter build web --release` that validates:

- Manifest link is present in the rendered page.
- `flutter_service_worker.js` is registered.
- Flutter cache entries are created.
- The app still reloads in offline mode.
