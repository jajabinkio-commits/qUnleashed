# PHANTOM release readiness

**NOT RELEASE READY. No signed IPA or TestFlight build exists.**

M0 source audit and baseline verification are recorded. First M1 read-only adapter/UI slice has simulated tests; M1's physical connect → remote → files → apps gate remains blocked. M2–M7 remain pending.

| Gate | State | Required next evidence |
| --- | --- | --- |
| Pinned recursive source / GPL notices | Source preserved | Full hosted/native dependency notices and source-distribution review |
| Dart/Flutter validation | See final cycle report | Bundle compilation does not verify native iOS plugins |
| iOS native build | BLOCKED on Linux | macOS/Xcode build, CocoaPods/native dependencies, real bundle identity |
| Signing/install | BLOCKED | Appropriate signing/provisioning workflow; Apple Developer membership for TestFlight |
| Physical BLE/manual regressions | BLOCKED | Actual iPhone/Flipper/firmware versions and M1 operator log |
| Provider keys/AI controller | NOT IMPLEMENTED | Keychain, consent, typed schemas, authorization, tool budgets, audit/redaction, STOP tests |
| Default privacy | BLOCKER | Opt-in diagnostics/replay/push and migration; upstream defaults are enabled |
| Partial writes/retry policy | BLOCKER for M3 | Disconnect/read-back/conflict tests before gateway mutations |
| USB host bridge | NOT IMPLEMENTED | Authenticated pairing/replay protections, real CLI, separate approved DFU tests |
| External modules | UNVERIFIED | Exact hardware/firmware/.fap/API evidence; no version-name replacement |
| App branding/identity | PENDING | PHANTOM bundle and build identity; upstream qUnleashed release metadata is retained |

Builds in this workspace use upstream's gitignored Firebase CI placeholder, no real Firebase config, no Sentry DSN and no provider keys. This placeholder supports testing and Dart compilation, not functioning push or a release. Retain root GPL-3.0 LICENSE and all submodule/third-party notices; make corresponding source available when distributing a derivative. No remote push, publishing, flashing, RF operation or signing credentials were used.
