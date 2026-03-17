## [1.42.1](https://github.com/Steve-Mee/project-management-app/compare/v1.42.0...v1.42.1) (2026-03-17)

### Bug Fixes

* **mirror:** align schema, gateway, editor, and contracts ([add4032](https://github.com/Steve-Mee/project-management-app/commit/add4032a560336ffb44bda74f3775c103042bb5b))

## [1.42.0](https://github.com/Steve-Mee/project-management-app/compare/v1.41.0...v1.42.0) (2026-03-17)

### Features

* **mirror:** harden gateway entitlement, persist draft metadata, and reduce duplicate status channels ([ba60e4f](https://github.com/Steve-Mee/project-management-app/commit/ba60e4f34585378bb3f276284abf102c675a66e9))

## [1.41.0](https://github.com/Steve-Mee/project-management-app/compare/v1.40.0...v1.41.0) (2026-03-17)

### Features

* **mirror:** harden gateway/provider flow and offline editor reliability ([7babb65](https://github.com/Steve-Mee/project-management-app/commit/7babb65e49e4e85aa476a8d8ba4ec172dd389eee))

## [1.40.0](https://github.com/Steve-Mee/project-management-app/compare/v1.39.0...v1.40.0) (2026-03-16)

### Features

* **orchestration:** reduce duplicate compile steps with preview-reuse token (P1) ([9c2b84d](https://github.com/Steve-Mee/project-management-app/commit/9c2b84debd90e823e2dcab16b7adcfbba7ed53a0))

## [1.39.0](https://github.com/Steve-Mee/project-management-app/compare/v1.38.0...v1.39.0) (2026-03-12)

### Features

* **mirror:** add security revocation UX, premium cache tuning, i18n warnings, and template telemetry ([dcb7c2d](https://github.com/Steve-Mee/project-management-app/commit/dcb7c2d504ad146f4c4e2abc14c25f904f1a03c2))

## [1.38.0](https://github.com/Steve-Mee/project-management-app/compare/v1.37.1...v1.38.0) (2026-03-12)

### Features

* **mirror:** add gateway rate limiting, usage metering, and observability ([e229d81](https://github.com/Steve-Mee/project-management-app/commit/e229d81996951c5aa52331984c42d4efa8f147e7))

## [1.37.1](https://github.com/Steve-Mee/project-management-app/compare/v1.37.0...v1.37.1) (2026-03-11)

### Bug Fixes

* **mirror:** clean outbox budget provider integration ([286cd16](https://github.com/Steve-Mee/project-management-app/commit/286cd16c29ee82d17b785e25dc2e42a76b614d43))
* **mirror:** repair budget service provider wiring ([c36a912](https://github.com/Steve-Mee/project-management-app/commit/c36a9124db21bd097554fcf61b9a83a4b039710a))

## [1.37.0](https://github.com/Steve-Mee/project-management-app/compare/v1.36.1...v1.37.0) (2026-03-11)

### Features

* **mirror:** add context payload budget service to prevent large-project overload (P1) ([92e6e0e](https://github.com/Steve-Mee/project-management-app/commit/92e6e0e336043554fac7eaf6c4499130b32b1666))

## [1.36.1](https://github.com/Steve-Mee/project-management-app/compare/v1.36.0...v1.36.1) (2026-03-11)

### Bug Fixes

* **db:** align idempotency status to processing (P0 blocker) ([032c1b2](https://github.com/Steve-Mee/project-management-app/commit/032c1b2c6571355b725e7d985482320bb849562c))

## [1.36.0](https://github.com/Steve-Mee/project-management-app/compare/v1.35.0...v1.36.0) (2026-03-11)

### Features

* **mirror:** add cache freshness + refined template RLS (P3) ([d77dac4](https://github.com/Steve-Mee/project-management-app/commit/d77dac44ed4b481d02f2dd2368ad29c1fceb0662))
* **mirror:** refine template RLS permission to manage_templates (P3) ([9eaf723](https://github.com/Steve-Mee/project-management-app/commit/9eaf723067e41bc369339791ed0611f17ed124af))

## [1.35.0](https://github.com/Steve-Mee/project-management-app/compare/v1.34.0...v1.35.0) (2026-03-11)

### Features

* **i18n:** full localization of apply_dialog.dart (P1) ([0bf2099](https://github.com/Steve-Mee/project-management-app/commit/0bf20998e798d244189e28b35af7cab74bfbc0a1))

## [1.34.0](https://github.com/Steve-Mee/project-management-app/compare/v1.33.0...v1.34.0) (2026-03-11)

### Features

* **mirror:** add screen-level use_mirror permission guard (P1) ([22ac0be](https://github.com/Steve-Mee/project-management-app/commit/22ac0be54efab0602bef80bf5dae2fcd6061e2f7))

## [1.33.0](https://github.com/Steve-Mee/project-management-app/compare/v1.32.0...v1.33.0) (2026-03-11)

### Features

* **mirror:** propagate idempotency-key end-to-end to gateway (P1) ([a795814](https://github.com/Steve-Mee/project-management-app/commit/a7958146957335fbb395cac61b4422d6b5cb7e3b))

## [1.32.0](https://github.com/Steve-Mee/project-management-app/compare/v1.31.0...v1.32.0) (2026-03-11)

### Features

* **db:** add mirror_request_idempotency table for gateway idempotency (P1) ([4763bb4](https://github.com/Steve-Mee/project-management-app/commit/4763bb41d6882ea355fca3ae09de43a580f9a38b))

## [1.31.0](https://github.com/Steve-Mee/project-management-app/compare/v1.30.0...v1.31.0) (2026-03-10)

### Features

* **mirror-editor:** extract realtime and run orchestration into dedicated services ([346c890](https://github.com/Steve-Mee/project-management-app/commit/346c89002c1502b58968da1a572c363c1a1a30a1))

## [1.30.0](https://github.com/Steve-Mee/project-management-app/compare/v1.29.1...v1.30.0) (2026-03-10)

### Features

* **mirror-gateway:** harden idempotency claim and finalize semantics ([dbf0972](https://github.com/Steve-Mee/project-management-app/commit/dbf097265e94f9f02f4c0c831ea509246398dcf0))

## [1.29.1](https://github.com/Steve-Mee/project-management-app/compare/v1.29.0...v1.29.1) (2026-03-10)

### Bug Fixes

* **mirror:** enforce preview/apply context parity and mandatory fingerprint validation for gateway apply ([4305bf1](https://github.com/Steve-Mee/project-management-app/commit/4305bf165d73bd9f90c27bcdd9eea40a02704d6f))

## [1.29.0](https://github.com/Steve-Mee/project-management-app/compare/v1.28.2...v1.29.0) (2026-03-10)

### Features

* **mirror:** add realtime event-id/updated_at dedup set in editor ([c37862e](https://github.com/Steve-Mee/project-management-app/commit/c37862ee549e1292b136a457b820c25df34afb88))

## [1.28.2](https://github.com/Steve-Mee/project-management-app/compare/v1.28.1...v1.28.2) (2026-03-10)

### Bug Fixes

* **mirror:** resolve provider autoDispose type mismatch and backend hardening\n\n- Update MirrorSessionNotifier to AutoDisposeFamilyNotifier for provider bound match\n- Keep mirrorSessionProvider as autoDispose.family\n- Simplify MirrorSessionState.initial construction\n- Make PrivateGrpcBackend channel credentials configurable ([a5cb7d5](https://github.com/Steve-Mee/project-management-app/commit/a5cb7d510301273937e2339b93a9e62c430eca91))

## [1.28.1](https://github.com/Steve-Mee/project-management-app/compare/v1.28.0...v1.28.1) (2026-03-10)

### Bug Fixes

* **mirror:** lokaliseer hardcoded Nederlandse tekst in apply_dialog ([02a312f](https://github.com/Steve-Mee/project-management-app/commit/02a312f070ceeaf664cd22356333985846a091be))

## [1.28.0](https://github.com/Steve-Mee/project-management-app/compare/v1.27.0...v1.28.0) (2026-03-10)

### Features

* **mirror:** harden runtime flow and finalize readiness docs ([a711be5](https://github.com/Steve-Mee/project-management-app/commit/a711be525b50e5537a8115658dcafd3c8c09bc6e))

## [1.27.0](https://github.com/Steve-Mee/project-management-app/compare/v1.26.0...v1.27.0) (2026-03-09)

### Features

* **mirror:** add mirror_runner_mode AB policy and enforce shared gateway quotas (500 files, 50MB, 300s) across cloud/local runners with structured contract errors ([8be21b9](https://github.com/Steve-Mee/project-management-app/commit/8be21b91655204baa6b3c9bb50f056857f4c1c18))

## [1.26.0](https://github.com/Steve-Mee/project-management-app/compare/v1.25.0...v1.26.0) (2026-03-09)

### Features

* **mirror:** add realtime payload guards and debounce memory caps with truncation logging ([6199ab9](https://github.com/Steve-Mee/project-management-app/commit/6199ab9155088adedda205d704f981eab42b1dc7))

## [1.25.0](https://github.com/Steve-Mee/project-management-app/compare/v1.24.0...v1.25.0) (2026-03-09)

### Features

* **i18n:** replace Mirror temp extension with semantic ARB keys ([5be4bdf](https://github.com/Steve-Mee/project-management-app/commit/5be4bdfcbc628669f1023ebef4e549bc180cfa70))

## [1.24.0](https://github.com/Steve-Mee/project-management-app/compare/v1.23.1...v1.24.0) (2026-03-09)

### Features

* **mirror:** persist orchestrator outbox in Hive with idempotency and retry metadata ([8533b50](https://github.com/Steve-Mee/project-management-app/commit/8533b501e5e4c1362baa67a1bf17358f64e78d6d))

## [1.23.1](https://github.com/Steve-Mee/project-management-app/compare/v1.23.0...v1.23.1) (2026-03-09)

### Bug Fixes

* resolve mirror analyzer issues and import lints ([cac5fc0](https://github.com/Steve-Mee/project-management-app/commit/cac5fc0c8007fc6b4dbb5ed3b85a6fd49cb2e4c5))

## [1.23.0](https://github.com/Steve-Mee/project-management-app/compare/v1.22.0...v1.23.0) (2026-03-09)

### Features

* **mirror:** finalize i18n, cleanup legacy policy note, and apply-context contract test ([67d7c58](https://github.com/Steve-Mee/project-management-app/commit/67d7c58d97ccbc16f8215e5c200bfea60a9ac550))

## [1.22.0](https://github.com/Steve-Mee/project-management-app/compare/v1.21.2...v1.22.0) (2026-03-09)

### Features

* **local-runner:** add optional auth guard and env-based secrets ([ca6872f](https://github.com/Steve-Mee/project-management-app/commit/ca6872f1d06a70af2fbb1cb1a4467ab4ac45c92f))

## [1.21.2](https://github.com/Steve-Mee/project-management-app/compare/v1.21.1...v1.21.2) (2026-03-09)

### Bug Fixes

* **mirror:** map template_key/icon_name via templates provider ([f8c10ee](https://github.com/Steve-Mee/project-management-app/commit/f8c10ee54e04bb5b6636f7edb2a6f1180fa6388c))

## [1.21.1](https://github.com/Steve-Mee/project-management-app/compare/v1.21.0...v1.21.1) (2026-03-09)

### Bug Fixes

* **mirror:** apply uses original compile context ([a93739e](https://github.com/Steve-Mee/project-management-app/commit/a93739ed11a19069bf12608df57741533d6f0e9a))

## [1.21.0](https://github.com/Steve-Mee/project-management-app/compare/v1.20.1...v1.21.0) (2026-03-09)

### Features

* add ai_sessions baseline migration and mirror output contract test ([5902d87](https://github.com/Steve-Mee/project-management-app/commit/5902d875cddd5eedd8df0baf64fddb15cb4fa436))

## [1.20.1](https://github.com/Steve-Mee/project-management-app/compare/v1.20.0...v1.20.1) (2026-03-09)

### Bug Fixes

* add explicit Apply RPC to mirror proto services ([e29feb4](https://github.com/Steve-Mee/project-management-app/commit/e29feb456306c3ee05b0c58e0570937073a3e527))

## [1.20.0](https://github.com/Steve-Mee/project-management-app/compare/v1.19.1...v1.20.0) (2026-03-09)

### Features

* wire mirror run flow through orchestrator and use provider templates ([aebbe1f](https://github.com/Steve-Mee/project-management-app/commit/aebbe1f72a167e5e687da3f271c7a3b1dd6af250))

## [1.19.1](https://github.com/Steve-Mee/project-management-app/compare/v1.19.0...v1.19.1) (2026-03-09)

### Bug Fixes

* return output files map and keep signedUrl separate in mirror runners ([b5df6b1](https://github.com/Steve-Mee/project-management-app/commit/b5df6b18755e612e3e17f85248149d4e478a79fd))

## [1.19.0](https://github.com/Steve-Mee/project-management-app/compare/v1.18.0...v1.19.0) (2026-03-09)

### Features

* **mirror:** finalize hardening and mark analysis tasks done ([14c57e5](https://github.com/Steve-Mee/project-management-app/commit/14c57e5ad7065dd3624666b01afb602221b63797))

## [1.18.0](https://github.com/Steve-Mee/project-management-app/compare/v1.17.1...v1.18.0) (2026-03-09)

### Features

* **runners:** add http gateway endpoints for compile/apply parity ([50b5d39](https://github.com/Steve-Mee/project-management-app/commit/50b5d39b87980cc1fee38fca12b4408a082fe1cd))

## [1.17.1](https://github.com/Steve-Mee/project-management-app/compare/v1.17.0...v1.17.1) (2026-03-09)

### Bug Fixes

* **mirror-compute:** enforce action endpoint and use_mirror permission rpc ([e21f511](https://github.com/Steve-Mee/project-management-app/commit/e21f5114eb5529be8ea1f640c3a22eede7e2defd))
* **mirror:** align orchestrator ref types with widget usage ([2809115](https://github.com/Steve-Mee/project-management-app/commit/2809115a79551da96975fc762046041843d7829c))

## [1.17.0](https://github.com/Steve-Mee/project-management-app/compare/v1.16.0...v1.17.0) (2026-03-09)

### Features

* **mirror:** initialize session from project and task context ([1865fb2](https://github.com/Steve-Mee/project-management-app/commit/1865fb2d099f7b7ae4e1d9d458e437898914682f))

## [1.16.0](https://github.com/Steve-Mee/project-management-app/compare/v1.15.0...v1.16.0) (2026-03-09)

### Features

* **mirror:** integrate templates gallery and apply risk dialog ([3b152d1](https://github.com/Steve-Mee/project-management-app/commit/3b152d1aee855621837cd2cec997bb7b125e36ae))

## [1.15.0](https://github.com/Steve-Mee/project-management-app/compare/v1.14.0...v1.15.0) (2026-03-09)

### Features

* **mirror:** wire run button to orchestrator pipeline ([738b69a](https://github.com/Steve-Mee/project-management-app/commit/738b69a80ae87099927d64dda4f3420bc495720e))

## [1.14.0](https://github.com/Steve-Mee/project-management-app/compare/v1.13.0...v1.14.0) (2026-03-09)

### Features

* **mirror:** add orchestrator service and fix windows CMP0175 policy default ([aaae65d](https://github.com/Steve-Mee/project-management-app/commit/aaae65d5a1cb6647be5e701d0ae70bf02defd605))

## [1.13.0](https://github.com/Steve-Mee/project-management-app/compare/v1.12.0...v1.13.0) (2026-03-08)

### Features

* **mirror:** close remaining hardening attention points ([7ccd1b5](https://github.com/Steve-Mee/project-management-app/commit/7ccd1b54b5f331f14b8b554d4944aa7e8e8ebc0c))

## [1.12.0](https://github.com/Steve-Mee/project-management-app/compare/v1.11.0...v1.12.0) (2026-03-08)

### Features

* **mirror:** harden edge config and desktop monaco host ([f28bced](https://github.com/Steve-Mee/project-management-app/commit/f28bced46e8adf613f629276beaf8c3dbc9d8c5f))

### Bug Fixes

* add mirror session provider and refactor mirror editor state ([034afb0](https://github.com/Steve-Mee/project-management-app/commit/034afb01f84b1b8a103ec90e3cd5a21284e71bb9))
* finalize remaining Mirror analysis actions ([e587fbf](https://github.com/Steve-Mee/project-management-app/commit/e587fbf09ab5f612acb435322a4affe84718e505))
* mirror RLS path alignment and edge dispatch idempotency ([97f429d](https://github.com/Steve-Mee/project-management-app/commit/97f429d68936004ae917c89c2327413e478c83d6))
* remove unnecessary import in mirror editor ([3d62128](https://github.com/Steve-Mee/project-management-app/commit/3d62128947b2d182db38f5689a855b973f3c9c32))

## [1.11.0](https://github.com/Steve-Mee/project-management-app/compare/v1.10.0...v1.11.0) (2026-03-08)

### Features

* **comments:** navigate to user details on mention tap ([55b6d3d](https://github.com/Steve-Mee/project-management-app/commit/55b6d3df7439ae0fe34749f0513b4e64854dce16))
* **project:** add configurable project cache TTL and cache logs ([e62095d](https://github.com/Steve-Mee/project-management-app/commit/e62095d6e28701cf8ec225eb58806a92c7e27018))

### Bug Fixes

* **ai-tests:** retain legacy import for legacy state contract suite ([07b8b87](https://github.com/Steve-Mee/project-management-app/commit/07b8b873ae0ec632f583db578fd522b80428d377))
* **features:** add compatibility fallback exports in provider indexes ([bd2bfe9](https://github.com/Steve-Mee/project-management-app/commit/bd2bfe9284dc25259778a4a3f51e259ac74756be))
* **project:** remove obsolete local pagination error field ([530357f](https://github.com/Steve-Mee/project-management-app/commit/530357f8efd7af8ef9b9d27b2ee1c9dbcd33413e))

## [1.10.0](https://github.com/Steve-Mee/project-management-app/compare/v1.9.0...v1.10.0) (2026-03-07)

### Features

* **todo-009:** extend filtered provider condition semantics ([558b3be](https://github.com/Steve-Mee/project-management-app/commit/558b3be1cfdd6df13a1c6892e72a0f3ea63c4085))

## [1.9.0](https://github.com/Steve-Mee/project-management-app/compare/v1.8.0...v1.9.0) (2026-03-07)

### Features

* **todo-008:** apply extended project filter semantics ([bfb2bf4](https://github.com/Steve-Mee/project-management-app/commit/bfb2bf4dbe2d85dbc6f44208cc10655c7f57551b))

## [1.8.0](https://github.com/Steve-Mee/project-management-app/compare/v1.7.0...v1.8.0) (2026-03-07)

### Features

* **todo-006:** wire ttl cache for projectById provider ([7daab06](https://github.com/Steve-Mee/project-management-app/commit/7daab0655d72b1abab5dc50061885cbb5141221c))

## [1.7.0](https://github.com/Steve-Mee/project-management-app/compare/v1.6.0...v1.7.0) (2026-03-07)

### Features

* **todo-005:** add project filter bridge semantics ([d5e4333](https://github.com/Steve-Mee/project-management-app/commit/d5e4333f40eaf8fce9b6f97b878ca19d2db8aa6f))

## [1.6.0](https://github.com/Steve-Mee/project-management-app/compare/v1.5.0...v1.6.0) (2026-03-07)

### Features

* **todo-004:** harden paginated projects provider ([428d870](https://github.com/Steve-Mee/project-management-app/commit/428d870bd7de9adef1554c19d1ba571d8f2d3872))

## [1.5.0](https://github.com/Steve-Mee/project-management-app/compare/v1.4.0...v1.5.0) (2026-03-07)

### Features

* **todo-003:** unify repository filtering semantics ([87c7907](https://github.com/Steve-Mee/project-management-app/commit/87c7907da1a26945512035d13cee93e6c96feb35))

## [1.4.0](https://github.com/Steve-Mee/project-management-app/compare/v1.3.0...v1.4.0) (2026-03-07)

### Features

* **todo-002:** harden project pagination contract ([314064a](https://github.com/Steve-Mee/project-management-app/commit/314064aae2992ef6a2f4c7d932520e88d098717b))

# [1.3.0](https://github.com/Steve-Mee/project-management-app/compare/v1.2.3...v1.3.0) (2026-03-07)


### Features

* **web:** finalize PWA support and CI validation ([#074](https://github.com/Steve-Mee/project-management-app/issues/074)) ([0cff439](https://github.com/Steve-Mee/project-management-app/commit/0cff439d4eb8781201f7579f388a71153b56c8ea))

## [1.2.3](https://github.com/Steve-Mee/project-management-app/compare/v1.2.2...v1.2.3) (2026-03-07)


### Bug Fixes

* **ci:** make analyze non-fatal for warnings and tolerate ubuntu desktop ([aff10b0](https://github.com/Steve-Mee/project-management-app/commit/aff10b0fc6ff5a901e7da45d184727b78274c085))

## [1.2.2](https://github.com/Steve-Mee/project-management-app/compare/v1.2.1...v1.2.2) (2026-03-07)


### Bug Fixes

* **ci:** use env template, skip golden tests, linux deps ([3aa6100](https://github.com/Steve-Mee/project-management-app/commit/3aa6100f4621417972611ef1686da511a9d67692))

## [1.2.1](https://github.com/Steve-Mee/project-management-app/compare/v1.2.0...v1.2.1) (2026-03-07)


### Bug Fixes

* **ci:** stabilize tests and linux desktop build ([de5c489](https://github.com/Steve-Mee/project-management-app/commit/de5c48948488d0f0cd0caaae07cece2753b3c3f7))

# [1.2.0](https://github.com/Steve-Mee/project-management-app/compare/v1.1.2...v1.2.0) (2026-03-07)


### Features

* **analytics:** integrate AnalyticsService with Supabase events and offline queue ([9f40b75](https://github.com/Steve-Mee/project-management-app/commit/9f40b758b3d9956c8c86e036db9a2d71fa2fc107))

## [1.1.2](https://github.com/Steve-Mee/project-management-app/compare/v1.1.1...v1.1.2) (2026-03-07)


### Bug Fixes

* **ci:** create .env placeholder in workflows ([bf03c44](https://github.com/Steve-Mee/project-management-app/commit/bf03c448e25c818c0360ee39b4d498756b5364b8))

## [1.1.1](https://github.com/Steve-Mee/project-management-app/compare/v1.1.0...v1.1.1) (2026-03-07)


### Bug Fixes

* **ci:** retry flutter analyze once on runner flake ([3c1f5dc](https://github.com/Steve-Mee/project-management-app/commit/3c1f5dc601c3d76fb23b15f3fd82f3a4ca25ed6e))

# [1.1.0](https://github.com/Steve-Mee/project-management-app/compare/v1.0.1...v1.1.0) (2026-03-07)


### Bug Fixes

* **logger:** resolve private type in public API ([283a296](https://github.com/Steve-Mee/project-management-app/commit/283a2962c70dd1717e19af55bc28f3f2d387fd56))


### Features

* **error-handling:** add global error boundary, sentry integration, and recovery test hardening ([bc24560](https://github.com/Steve-Mee/project-management-app/commit/bc24560d3898dd5074aae9608c65880213dea831))

## [1.0.1](https://github.com/Steve-Mee/project-management-app/compare/v1.0.0...v1.0.1) (2026-03-07)


### Bug Fixes

* **release:** disable semantic-release issue comments ([f196408](https://github.com/Steve-Mee/project-management-app/commit/f196408aef906d5c77c26ab539452add00886343))

# 1.0.0 (2026-03-07)


### Bug Fixes

* add library directive to analytics_providers.dart to resolve dangling doc comments ([ee18ae0](https://github.com/Steve-Mee/project-management-app/commit/ee18ae0e4e4c93a8ec929ac0a654f9a3447188c6))
* add library directive to i_auth_repository.dart to resolve dangling doc comment ([157d6f3](https://github.com/Steve-Mee/project-management-app/commit/157d6f391fceb0fc28a93bfea9cd7b343d637387))
* add missing _loadDefaultFilter method and fix string interpolation ([6f4830a](https://github.com/Steve-Mee/project-management-app/commit/6f4830ad5f4a84244af3b6debbe6a51d11722d9a))
* add missing [@override](https://github.com/override) annotations in auth_repository.dart ([3b275df](https://github.com/Steve-Mee/project-management-app/commit/3b275dfe2bf30b75372c2e2322135f2b22f0eb54))
* add missing DashboardItem import in customize_dashboard_screen.dart ([7364fcc](https://github.com/Steve-Mee/project-management-app/commit/7364fccaa095c442a867c145465689108096dea3))
* add missing ProjectRequirements import in dashboard_repository.dart ([dd58c3c](https://github.com/Steve-Mee/project-management-app/commit/dd58c3c8f83cdb612da933f525469323ca30926f))
* add missing projectSortCreatedDate and projectSortStatus localization ([68e1946](https://github.com/Steve-Mee/project-management-app/commit/68e19465d75b3c743ab587c0bb41742e13c015be))
* **ci:** stabilize semantic release and PR check triggers ([d731642](https://github.com/Steve-Mee/project-management-app/commit/d731642d1a5f4a06674261a08cfc3ce40d1cbc72))
* complete AuthUser to AppUser migration and remove unused imports ([479f3cc](https://github.com/Steve-Mee/project-management-app/commit/479f3cc80a9b7f75953bef82495642382ce89e11))
* import Timer and use literal search hint in project screen ([4990242](https://github.com/Steve-Mee/project-management-app/commit/4990242f2a8a4ee0ce3e65e370d2c103bcfafa0e))
* remove ignore comment and re-add missing imports to dashboard_screen ([cadbbe1](https://github.com/Steve-Mee/project-management-app/commit/cadbbe123b3eb7ebff60cf728fcec03d4d26b39f))
* Remove unused imports and variables in login rate limiter test ([ca99108](https://github.com/Steve-Mee/project-management-app/commit/ca991081f3e45bfea3e7e90f91e97851422d79b7))
* remove unused local variable 'isDark' in dashboard_screen.dart ([1bf9a0b](https://github.com/Steve-Mee/project-management-app/commit/1bf9a0b35566318efea95277e80d6584d27be8ef))
* remove unused projectMetaRepositoryProvider from task_providers.dart import ([ca5c728](https://github.com/Steve-Mee/project-management-app/commit/ca5c728763893c464234513ae4e5f6b8ceb42629))
* replace AuthUser with AppUser in ai_chat_bottom_sheet.dart ([6ba5ca9](https://github.com/Steve-Mee/project-management-app/commit/6ba5ca9e27eac24672c92b1aee80020d4f920c06))
* replace AuthUser with AppUser in auth_repository.dart ([bbfd29f](https://github.com/Steve-Mee/project-management-app/commit/bbfd29ff9e4491ad2ea7c985c14f3e3d14af2963))
* Resolve linter warnings in dashboard tests ([328e4ff](https://github.com/Steve-Mee/project-management-app/commit/328e4ff33a35d9cc2592a5040d06a9999c14c36a))


### Features

* Add advanced sorting and CSV export to project filters ([b8e65f1](https://github.com/Steve-Mee/project-management-app/commit/b8e65f12bd070386677abf3298e645f4f2d1ce99))
* Add AI-powered smart filtering feature ([4210cf2](https://github.com/Steve-Mee/project-management-app/commit/4210cf285412b36f31dac0582a03ab51db0a0bcb))
* Add biometric authentication support ([b2616da](https://github.com/Steve-Mee/project-management-app/commit/b2616dab507c448419657b022716d29b44b7fb0e))
* add biometrics + async settings + cleanup auth TODOs (step 3/3) ([cc07ada](https://github.com/Steve-Mee/project-management-app/commit/cc07ada54a5e236d565f138cdec82c609c528bac))
* add caching layer for individual projects and paginated lists (improves performance) ([b840077](https://github.com/Steve-Mee/project-management-app/commit/b840077a6e7be15a199fbfc3165bbabaa05a4bf2))
* add combined projectsCombinedProvider for pagination + filtering + sorting (enhances [#003](https://github.com/Steve-Mee/project-management-app/issues/003)) ([7fad0b5](https://github.com/Steve-Mee/project-management-app/commit/7fad0b510d3e98045a8cb18d61baa665b68458f1))
* Add comprehensive AI rate limits UI tests and fix linting issues ([628a796](https://github.com/Steve-Mee/project-management-app/commit/628a7968a34428e70612c24f26d9ffc1e7a403a4))
* Add comprehensive error handling and logging to dashboard providers ([19c32f7](https://github.com/Steve-Mee/project-management-app/commit/19c32f75fcb2a84cdfa65d2a570b9010891544fa)), closes [#025](https://github.com/Steve-Mee/project-management-app/issues/025)
* Add dashboard templates functionality ([8698d10](https://github.com/Steve-Mee/project-management-app/commit/8698d103bd797ec2d917e922b9ea29958a7d8699)), closes [#023](https://github.com/Steve-Mee/project-management-app/issues/023)
* add desktop keyboard shortcuts to projects screen ([f9f0f47](https://github.com/Steve-Mee/project-management-app/commit/f9f0f4733d93f4af65aa7338d2ccd62dad716973))
* Add error handling and logging to dashboard providers ([a182143](https://github.com/Steve-Mee/project-management-app/commit/a182143553e64b2c3bac707fc2f20ac4bb5d964c)), closes [#025](https://github.com/Steve-Mee/project-management-app/issues/025)
* add filteredProjectsProvider family + cleanup filtering TODOs ([65dfb6d](https://github.com/Steve-Mee/project-management-app/commit/65dfb6df6ad448ba5e500c9117c8aea8a3d3f5c8))
* Add full tag/label filtering with AND logic and basic custom fields support ([6b1c501](https://github.com/Steve-Mee/project-management-app/commit/6b1c501c6e72f8466bad957224088b6fc25a4825))
* add getProjectsByStatus and getFilteredProjects to IProjectRepository + ProjectFilter class ([eecb1eb](https://github.com/Steve-Mee/project-management-app/commit/eecb1eb3e9e6323c7fb3111a682f5b5c4b571431))
* Add offline requirements support with Hive storage ([60244ea](https://github.com/Steve-Mee/project-management-app/commit/60244eabde618ef8fdfdedd8478a50ef231572af)), closes [#028](https://github.com/Steve-Mee/project-management-app/issues/028)
* Add professional PDF export for filtered projects ([2054b6c](https://github.com/Steve-Mee/project-management-app/commit/2054b6cd0048b1f32d7274a3cc95c752aa4c6b23))
* add projectsPaginatedProvider family with pagination & filtering ([0add55a](https://github.com/Steve-Mee/project-management-app/commit/0add55a217175a0aaecf29ddb20419a68961fbcd))
* Add rate limiting for login attempts to protect against brute-force attacks ([5148bde](https://github.com/Steve-Mee/project-management-app/commit/5148bde23b3a239c003910a067fd95b269726383))
* add rate limiting to IAuthRepository (step 2/3) ([dc9d851](https://github.com/Steve-Mee/project-management-app/commit/dc9d85175bec6a245f541c863c9d88d359503011))
* add recent filters dropdown menu ([23aff1f](https://github.com/Steve-Mee/project-management-app/commit/23aff1f1f55eb8594f8bdbaf58352e74f2fea3d8))
* Add search and filter capabilities to auth/user providers ([001d200](https://github.com/Steve-Mee/project-management-app/commit/001d2004200eba76a48d535710232ff4464ec0f1)), closes [#019](https://github.com/Steve-Mee/project-management-app/issues/019)
* add sort dropdown to combined pagination + filtering UI (completes [#003](https://github.com/Steve-Mee/project-management-app/issues/003) [#004](https://github.com/Steve-Mee/project-management-app/issues/004)) ([1bb4db5](https://github.com/Steve-Mee/project-management-app/commit/1bb4db56694f2bfc928667b27d53ccf62db6db48))
* add Supabase sync preparation stubs (step 3/3) ([334d178](https://github.com/Steve-Mee/project-management-app/commit/334d178f36a98aeb3883f727f14840cbf63bdff1))
* Add team [@mentions](https://github.com/mentions) in comments and Gantt chart timeline view ([206092c](https://github.com/Steve-Mee/project-management-app/commit/206092c50eb88fc8d67f5921100c97146daae224))
* Add undo/redo functionality to dashboard ([688d8db](https://github.com/Steve-Mee/project-management-app/commit/688d8db3ad2cf3675ffaec76ffaf7f73f632da18)), closes [#022](https://github.com/Steve-Mee/project-management-app/issues/022)
* Add view mode switcher with List/Kanban/Table views ([b6c03d9](https://github.com/Steve-Mee/project-management-app/commit/b6c03d971452e7ab205139bff1f86dcabc5169a2))
* Add widgetType validation for dashboard widgets ([48d2b9d](https://github.com/Steve-Mee/project-management-app/commit/48d2b9d97b218caa251822f018147948ee09f94f))
* combine pagination + filtering with ProjectFilterParams in single UI with infinite scroll (completes issue 005) ([b1503fd](https://github.com/Steve-Mee/project-management-app/commit/b1503fd0c3ac62d744ccda62e23969d8b0d8c7ca))
* combined pagination + filtering + sorting UI with infinite scroll (closes [#003](https://github.com/Steve-Mee/project-management-app/issues/003)) ([e16e8e9](https://github.com/Steve-Mee/project-management-app/commit/e16e8e93574bbfaae891b62528bb29b3cad5ceac))
* combined pagination + filtering + sorting UI with infinite scroll (closes [#003](https://github.com/Steve-Mee/project-management-app/issues/003)) ([3cfe223](https://github.com/Steve-Mee/project-management-app/commit/3cfe223c5555b96b10be9be3213ecd666f91863b))
* Complete auth backend integration with Supabase ([3b1b954](https://github.com/Steve-Mee/project-management-app/commit/3b1b954268ed7fa5544f1a0362c7a950f10edddb))
* complete individual project caching implementation (issue 006) ([01df822](https://github.com/Steve-Mee/project-management-app/commit/01df822b563ee053414b2e6f664667c0186aad57))
* complete TODO audit and issue creation ([602322b](https://github.com/Steve-Mee/project-management-app/commit/602322bb1cf7b9b4f88c4e627d564c9f8b9efb4b))
* create IDashboardRepository interface (step 1/3) ([00d94c7](https://github.com/Steve-Mee/project-management-app/commit/00d94c71dbccf63e26d1dc775e3bfc259c71447a))
* dashboard-specific styling for paginated project list (closes [#002](https://github.com/Steve-Mee/project-management-app/issues/002)) ([a38cc57](https://github.com/Steve-Mee/project-management-app/commit/a38cc574e804d6335c71dcfd551055aa0b478dfa))
* dedicated paginated projects provider added & clean up TODO (resolves [#004](https://github.com/Steve-Mee/project-management-app/issues/004)) ([4ddf28b](https://github.com/Steve-Mee/project-management-app/commit/4ddf28be3456d09f850ef07120e6856911f755d7))
* Extract IProjectRepository to separate interface file (resolves TODO in project_providers.dart) ([64dd470](https://github.com/Steve-Mee/project-management-app/commit/64dd470ec8b7c1a97a6b5299247ea4cb71fd0786))
* Extract IProjectRepository to separate interface file (resolves TODO in project_providers.dart) ([a4d957b](https://github.com/Steve-Mee/project-management-app/commit/a4d957bccc6423ce1c707345ec7e826ed3eb02df))
* **feature-flags:** complete Supabase integration with admin gating and AB phase-out ([8b64d09](https://github.com/Steve-Mee/project-management-app/commit/8b64d09f64dbf02bd77e2a7691edfc7bfc95b767)), closes [#071](https://github.com/Steve-Mee/project-management-app/issues/071)
* **gantt:** modernize gantt chart integration and docs ([#069](https://github.com/Steve-Mee/project-management-app/issues/069)) ([769a955](https://github.com/Steve-Mee/project-management-app/commit/769a9554fc53d15d8392f61cb12b54f7b19b6ee3))
* Implement [@mention](https://github.com/mention) autocomplete in comment sections ([e09c6a7](https://github.com/Steve-Mee/project-management-app/commit/e09c6a75bb6b5529c23d962450702395a9d175f9))
* implement active viewers functionality ([f2e1296](https://github.com/Steve-Mee/project-management-app/commit/f2e12965d38b78ee0668bc919fd9fb6797ec2bf0))
* implement advanced full-text search with fuzzy matching ([a9844f2](https://github.com/Steve-Mee/project-management-app/commit/a9844f2a1cdf0e9830ec1fe4a7b9ce76eccc4796))
* Implement AI parsing extensions system ([db269d5](https://github.com/Steve-Mee/project-management-app/commit/db269d5af146060bb31186eeeeb7949a29d4bfa7))
* implement AI request queue for burst handling ([c258acf](https://github.com/Steve-Mee/project-management-app/commit/c258acf90a77e1d441f8d9729b92be84bd82dcd0)), closes [#033](https://github.com/Steve-Mee/project-management-app/issues/033)
* Implement AI usage analytics improvement ([4559971](https://github.com/Steve-Mee/project-management-app/commit/4559971dcf473a1d352aa5681ca853ce7019ace7))
* implement AI XML parser with safeParseXml ([8ccbc19](https://github.com/Steve-Mee/project-management-app/commit/8ccbc1906f073ade89e318ca70073699961e7049)), closes [#035](https://github.com/Steve-Mee/project-management-app/issues/035)
* Implement application configuration expansions ([98dfa03](https://github.com/Steve-Mee/project-management-app/commit/98dfa0399754d35790567b79255a68db6b6f6de4))
* implement biometric authentication support ([acfcbc0](https://github.com/Steve-Mee/project-management-app/commit/acfcbc0bbb44f52e9c9879ab57280154b9339396))
* implement client-side rate limiting for login attempts ([a321fb5](https://github.com/Steve-Mee/project-management-app/commit/a321fb53fc658c8076b3e42a3f5748a7d323b1e8)), closes [#017](https://github.com/Steve-Mee/project-management-app/issues/017)
* implement collaborative dashboard sharing ([3323796](https://github.com/Steve-Mee/project-management-app/commit/3323796600490c4e075bb3e80fad2808e60c03cd)), closes [#024](https://github.com/Steve-Mee/project-management-app/issues/024)
* implement collaborative dashboard sharing ([c826b8d](https://github.com/Steve-Mee/project-management-app/commit/c826b8d5691dcd05386b2e942b6cd827a66aee83)), closes [#024](https://github.com/Steve-Mee/project-management-app/issues/024)
* Implement configurable AI rate limits ([8630e31](https://github.com/Steve-Mee/project-management-app/commit/8630e316abeac039f6c0f2fd7cb48ddfc7a36a0f)), closes [#030](https://github.com/Steve-Mee/project-management-app/issues/030)
* implement dashboard cache with TTL as per 027-dashboard-cache-requirements.md ([6db28a0](https://github.com/Steve-Mee/project-management-app/commit/6db28a07dfd103f3a441580d4bcd882e3597416d))
* implement dashboard position constraints ([#021](https://github.com/Steve-Mee/project-management-app/issues/021)) ([f6a1c31](https://github.com/Steve-Mee/project-management-app/commit/f6a1c31335bc319b13352d10544020d2b55e01bb))
* implement dashboard templates ([#023](https://github.com/Steve-Mee/project-management-app/issues/023)) ([8d0220a](https://github.com/Steve-Mee/project-management-app/commit/8d0220aa05dbd83c2993239711f7f148047b1555))
* implement efficient project getById (issue 007) ([7112e62](https://github.com/Steve-Mee/project-management-app/commit/7112e622e6cc3249e65004a760790ddd7505b8e7))
* implement exponential backoff with jitter for AI rate limits ([487ff52](https://github.com/Steve-Mee/project-management-app/commit/487ff528e8b191308c1683d3a3c0c19c7275619a))
* implement getProjectsPaginated in Hive ProjectRepository ([4943788](https://github.com/Steve-Mee/project-management-app/commit/4943788f8ebd2bf4ef9b7c3affa638851d004f18))
* implement per-operation rate limits for AI operations ([97417c0](https://github.com/Steve-Mee/project-management-app/commit/97417c0b5ffb0e7ba46c6b8f3b8f3dfb8d41165d)), closes [#034](https://github.com/Steve-Mee/project-management-app/issues/034)
* implement project filtering in Hive ProjectRepository ([ecf85ad](https://github.com/Steve-Mee/project-management-app/commit/ecf85ade3d72f66ee83b6652eefa2f715a59f61f))
* Implement project management features expansion ([b6a7dcc](https://github.com/Steve-Mee/project-management-app/commit/b6a7dcc5c525d70890a98ffd6df377658b991e9b))
* Implement reCAPTCHA integration for authentication security ([07fd81b](https://github.com/Steve-Mee/project-management-app/commit/07fd81bf52b0785e8024ce5791fea34ac7bd04eb))
* implement stricter linting rules from issue 053 ([2a12aab](https://github.com/Steve-Mee/project-management-app/commit/2a12aab8d59eb98246241cd1bfb592f83f815ec4))
* implement undo/redo functionality ([#022](https://github.com/Steve-Mee/project-management-app/issues/022)) ([100cfe3](https://github.com/Steve-Mee/project-management-app/commit/100cfe31d861cb7f4725b53995cbfa230e0543c0))
* implement user search and filter functionality ([938873f](https://github.com/Steve-Mee/project-management-app/commit/938873f5ee80d2c75fa75f04d4b08af7976349f4))
* improve accessibility semantics, contrast, and docs ([4ca2f6e](https://github.com/Steve-Mee/project-management-app/commit/4ca2f6e59eb8b1f4c8c31d77e2862a646f301f55))
* integrate ai service abstraction and fix filter dialog provider scope ([fc8678d](https://github.com/Steve-Mee/project-management-app/commit/fc8678dbae58a4f3ffd5bfe8d8177d3d2e86c39a))
* integrate filteredProjectsProvider with ProjectFilterParams into UI (completes issue 005) ([6c8fb83](https://github.com/Steve-Mee/project-management-app/commit/6c8fb83a481c10cd5318f3e59931ca6ea9c42a97))
* integrate projects pagination with infinite scroll in usage example ([2edc3f2](https://github.com/Steve-Mee/project-management-app/commit/2edc3f2d6995a9b9a5e5920964cd1e2a69b23f63))
* Integrate projectsProvider in dashboard for project requirements ([5f50ba3](https://github.com/Steve-Mee/project-management-app/commit/5f50ba3421c4a41674c9e3b0d9676f4cc866e778)), closes [#029](https://github.com/Steve-Mee/project-management-app/issues/029)
* Introduce IAuthRepository abstract interface ([9502948](https://github.com/Steve-Mee/project-management-app/commit/95029482e86371575085d4352a93b3228ed46339)), closes [#013](https://github.com/Steve-Mee/project-management-app/issues/013)
* Make max requests per window configurable ([#031](https://github.com/Steve-Mee/project-management-app/issues/031)) ([16f0568](https://github.com/Steve-Mee/project-management-app/commit/16f056810643a0b03c96642da6b593c09fc4e55a))
* migrate all UI to projectsPaginatedProvider with infinite scroll (closes [#004](https://github.com/Steve-Mee/project-management-app/issues/004)) ([7553ab3](https://github.com/Steve-Mee/project-management-app/commit/7553ab39a2b2f0410400f71b3a3daf0009a0391e))
* migrate to projectsPaginatedProvider (issue [#004](https://github.com/Steve-Mee/project-management-app/issues/004)) ([7b56913](https://github.com/Steve-Mee/project-management-app/commit/7b569131999482cb4821e053e8db609500ee4c46))
* **onboarding:** add first-launch wizard flow and global bootstrap gate ([66ed2f6](https://github.com/Steve-Mee/project-management-app/commit/66ed2f60d453ffac58079c9ad14abcc213e7b11e))
* **pma-core:** modularize core into reusable package and complete migration ([ab2d0f5](https://github.com/Steve-Mee/project-management-app/commit/ab2d0f5f7bd94d1206f31da158427925375711ae))
* premium Advanced Filters UI with ProjectFilterConditions – Material 3 polish (completes issue 009) ([56d2414](https://github.com/Steve-Mee/project-management-app/commit/56d241486141e6ea7cd5c581193abf4e5ed76aff))
* **security:** enable encrypted Hive boxes for sensitive data ([4c11d83](https://github.com/Steve-Mee/project-management-app/commit/4c11d833dd0bc1e98a4709a67094ee1917efa483))
* Split provider files for better organization ([5778511](https://github.com/Steve-Mee/project-management-app/commit/5778511df4553c1b17e36d1b4ceedae66656c9f3)), closes [#038](https://github.com/Steve-Mee/project-management-app/issues/038)
* **sync:** add global offline indicator with status provider and manual sync ([b25cfc1](https://github.com/Steve-Mee/project-management-app/commit/b25cfc127ee6c50232073b1093fcf5ddbc5c3707))
