# PHANTOM release readiness

**NOT RELEASE READY. No signed IPA or TestFlight build exists.**

M0 source audit and baseline verification are recorded. M1 read-only adapter/UI and first M2 read-only chat slices have simulated tests. M1 physical connect → remote → files → apps gate and full M2 acceptance remain blocked; M3–M7 remain pending.

| Gate | State | Required next evidence |
| --- | --- | --- |
| Pinned recursive source / GPL notices | Source preserved | Full hosted/native dependency notices and source-distribution review |
| Dart/Flutter validation | See final cycle report | Bundle compilation does not verify native iOS plugins |
| iOS native build | PASS (unsigned compile only) | Mac run 38938290988 built Runner.app at b099da8 PR merge snapshot; native Keychain runtime and physical operation remain unverified |
| Signing/install | BLOCKED | Appropriate signing/provisioning workflow; Apple Developer membership for TestFlight |
| Physical BLE/manual regressions | BLOCKED | Actual iPhone/Flipper/firmware versions and M1 operator log |
| Provider keys/read-only AI | PARTIAL | Keychain source/channel tests, model catalog and read-only loop implemented; native Keychain and live private provider verification pending; writes excluded |
| Default privacy | IMPLEMENTED / NATIVE UNVERIFIED | New explicit consent keys/defaults and revocation tested with mocks; native token migration/replay behavior needs physical validation |
| Partial writes/retry policy | BLOCKER for M3 | Disconnect/read-back/conflict tests before gateway mutations |
| USB host bridge | NOT IMPLEMENTED | Authenticated pairing/replay protections, real CLI, separate approved DFU tests |
| External modules | UNVERIFIED | Exact hardware/firmware/.fap/API evidence; no version-name replacement |
| App branding/identity | PENDING | PHANTOM bundle and build identity; upstream qUnleashed release metadata is retained |

Builds in this workspace use upstream's gitignored Firebase CI placeholder, no real Firebase config, no Sentry DSN and no provider keys. This placeholder supports testing and Dart compilation, not functioning push or a release. Retain root GPL-3.0 LICENSE and all submodule/third-party notices; make corresponding source available when distributing a derivative. No remote push, publishing, flashing, RF operation or signing credentials were used.

Cycle 02: Apple Developer membership is not established (user unsure/not yet). No Apple/GitHub login or signing identities were requested or used. Cloud workflow prepares compilation only, not installation or TestFlight. Public OpenRouter model/schema endpoints were checked without a key; no private/paid model request was made. See IMPLEMENTATION_CYCLE_02.md for precise current evidence.

Cycle 03: local controller readings are now separated from AI explanation, with missing-value, cancellation/erase and failed-provider tests. 1,914 tests passed and five were skipped; analyzer, format and Linux-target Dart bundle checks passed. The supplied `jajabinkio-commits/qUnleashed` fork exists, but connected account `jssanderson93-svg` has read-only access (push=false). Reconnecting the owning account with repository access is required before upload. No online macOS build has run.

Cycle 04 supersedes the account-mismatch blocker: owning account now connected and metadata push=true, but actual git push and connector create-branch both fail HTTP 403 (integration authorization). No remote changes or Mac job. PR trigger prepared and actionlint passes; see IMPLEMENTATION_CYCLE_04.md. Effective write authorization must be fixed before remote delivery.

Cycle 04 access resolved: user completed installation; actual upload and draft PR #1 succeeded. Mac unsigned compile and CI are running. Repository authorization is no longer the blocker. Signing/install/hardware remain pending.

Cycle 05 supersedes pending build status: Mac unsigned compile 38938290988 passed and uploaded artifact 12062890468 (expires 2026-10-23); cloud CI 38938290983 passed, 1,928 tests / five skipped and 51 quiet tests. Native compilation verified; runtime/hardware/signing/distribution remain unverified. Test Firebase configuration and upstream bundle identity make this artifact unsuitable for release.
