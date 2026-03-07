# Release Hardening Checklist

Purpose: handover overzicht voor issue `#075-release-pipeline-preparation` met onderscheid tussen wat al in code zit en wat nog extern moet gebeuren.

## Done (Implemented In Repository)

- [x] `release.yml` hardened met least-privilege permissions en concurrency.
- [x] `release.yml` draait alleen effectief op `main` via job guard.
- [x] `.releaserc.json` gebruikt conventional commits + changelog + git commit + pubspec version bump script.
- [x] `fastlane.yml` toegevoegd met release/manual trigger.
- [x] `fastlane.yml` hardened met concurrency en least-privilege permissions.
- [x] `fastlane.yml` preflight job valideert vereiste secrets.
- [x] `fastlane.yml` preflight job valideert dat `ANDROID_PACKAGE_NAME` matcht met `applicationId` in `android/app/build.gradle.kts`.
- [x] Redundante semantic-release stap verwijderd uit `fastlane.yml`.
- [x] Distribution smoke-check job toegevoegd.
- [x] Linux desktop build toegevoegd naast macOS/Windows in `fastlane.yml`.
- [x] `fastlane/Fastfile` heeft iOS `beta` lane met `upload_to_testflight` voor interne testers.
- [x] `fastlane/Fastfile` heeft Android `beta` lane met `upload_to_play_store` op internal track.
- [x] App Store Connect API key auth expliciet gemaakt in `fastlane/Fastfile`.
- [x] Android release signing in `android/app/build.gradle.kts` aangepast van debug signing naar release signing via `android/key.properties`.
- [x] `Gemfile.lock` gegenereerd en gecommit voor deterministische Fastlane dependencies.
- [x] Sample changelog-template verwijderd uit `CHANGELOG.md`.
- [x] Release docs toegevoegd en uitgebreid in `docs/release-pipeline.md` (go-live checklist + rollback runbook).

## Pending External (Manual/Platform Setup)

- [ ] GitHub Actions secrets invullen in repository settings.
- [ ] App Store Connect interne TestFlight groepen effectief configureren.
- [ ] Google Play internal testing track + testerlijst effectief configureren.
- [ ] Eerste end-to-end validatie run uitvoeren op GitHub Actions (release + fastlane workflows).
- [ ] Verifiëren dat builds zichtbaar zijn in TestFlight internal groups en Play internal track.
- [ ] Desktop artifact smoke test uitvoeren op gedownloade artifacts.
- [ ] Ruby/Bundler lokaal of in CI-image beschikbaar maken waar nodig voor lokale fastlane runs.

## Required Secrets Checklist

iOS/TestFlight:

- [ ] `IOS_APP_IDENTIFIER`
- [ ] `APPLE_ID`
- [ ] `APPLE_TEAM_ID`
- [ ] `APP_STORE_CONNECT_API_KEY_ID`
- [ ] `APP_STORE_CONNECT_API_ISSUER_ID`
- [ ] `APP_STORE_CONNECT_API_KEY_CONTENT`
- [ ] `IOS_P12_BASE64`
- [ ] `IOS_P12_PASSWORD`
- [ ] `IOS_MOBILEPROVISION_BASE64`
- [ ] `TESTFLIGHT_INTERNAL_GROUPS`

Android/Play:

- [ ] `ANDROID_PACKAGE_NAME`
- [ ] `SUPPLY_JSON_KEY_BASE64`
- [ ] `ANDROID_KEYSTORE_BASE64`
- [ ] `ANDROID_KEYSTORE_PASSWORD`
- [ ] `ANDROID_KEY_ALIAS`
- [ ] `ANDROID_KEY_PASSWORD`

Release:

- [ ] `GITHUB_TOKEN` (automatisch beschikbaar in GitHub Actions)

## Sign-off

- [ ] Product owner akkoord
- [ ] Technische validatie akkoord
- [ ] Go-live akkoord
