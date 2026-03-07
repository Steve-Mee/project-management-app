# Release Evidence Template

Gebruik dit template na elke live release-run als audit trail.

## Release Metadata

- Datum:
- Release tag (bijv. `v1.2.3`):
- Commit SHA:
- Operator:

## Workflow Evidence

- `release.yml` run URL/ID:
- `fastlane.yml` run URL/ID:
- `CHANGELOG.md` geverifieerd: [ ]
- Semantic-release versie bump geverifieerd: [ ]

## Distribution Evidence

- TestFlight internal bewijs (buildnummer/screenshot/link):
- Google Play internal bewijs (releasenaam/screenshot/link):
- Desktop artifacts bewijs (artifactnaam + smoke test resultaat):

## Quality Gates

- `flutter analyze` geslaagd: [ ]
- Tests geslaagd: [ ]
- Coverage geupload (Codecov): [ ]
- Kritieke regressies afwezig: [ ]

## Security & Compliance

- Signing/verificatie uitgevoerd: [ ]
- Secrets/env geldig voor run: [ ]
- Incidenten of uitzonderingen:

## Rollback Readiness

- Rollback-pad getest/beschikbaar: [ ]
- Verantwoordelijke on-call:

## Notes

- 
