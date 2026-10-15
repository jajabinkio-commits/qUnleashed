# Project PHANTOM

An in-progress derivative of qUnleashed, built on its pinned existing BLE/RPC stack. This checkout contains the supplied engineering specification, an audited/tested upstream baseline, the M1 read-only gateway/manual inspection screen, opt-in privacy controls, and an initial read-only AI chat slice. **It is not the completed application or a signed iPhone build.**

Start with [cycle 02 results](docs/IMPLEMENTATION_CYCLE_02.md), [source audit](docs/UPSTREAM_AUDIT.md), [31-capability matrix](docs/FEATURE_MATRIX.md), and [50-test acceptance status](docs/ACCEPTANCE_STATUS.md). The full contract is [MASTER_PLAN.md](docs/MASTER_PLAN.md), with [AGENTS.md](AGENTS.md) in the project root.

## Current component

Use the retained Device tab to connect a Flipper, then open **PHANTOM inspection**. Read device, power, protocol and `/ext` capacity without an AI account. Failed readings remain explicit. Stop inspection or background the app to discard late readings and stop subsequent inspection requests. The in-flight read drains or times out; STOP here is not a global stop for unrelated existing manual operations.

`lib/phantom/device/flipper_gateway.dart` also exposes canonical, read-only `/ext` and `/int` directory listing. Existing remote, files/archive, catalog/updater and toolbox screens remain in place. USB terminal and complete DFU recovery require the future authenticated host bridge. Open **PHANTOM AI** from the Device tab. On iPhone the API key uses the native Keychain; load the public model list, select a model and send a message. Basic status sharing requires a switch for each Send and offers only status/capabilities reads. Files, screenshots, voice, actions, automations, Shortcuts and module adapters remain pending. Native Keychain, live private provider calls and physical device flow have not yet been validated.

## Reproduce host checks

Install Flutter **3.47.1 / Dart 3.13.1** and recursively initialize submodules. Preserve `pubspec.lock`. Then:

```bash
flutter pub get --enforce-lockfile
.github/scripts/stub_firebase_config.sh
.github/scripts/check_format.sh
flutter analyze --no-pub
flutter test --no-pub --test-randomize-ordering-seed=20261014
```

The Firebase script creates a gitignored CI placeholder, not production push configuration. On a restricted host, use writable locations for `PUB_CACHE`, `XDG_CONFIG_HOME`, and `ANALYZER_STATE_LOCATION_OVERRIDE`; local Flutter test servers require socket access. Local Linux evidence used `/workspace/toolchains/` caches and SDK.

Run pinned transport-library tests separately:

```bash
cd lib/modules/flipperlib
flutter pub get
flutter test --no-pub
```

Physical iPhone testing needs compatible macOS/Xcode tooling and signing. Follow [hardware instructions](docs/HARDWARE_TEST_LOG.md) and [release readiness](docs/RELEASE_READINESS.md). A mock, Dart bundle or unsigned compile never proves physical BLE or a signed install.

## Privacy and release status

Diagnostics and replay now default off, require separate opt-in, and ignore legacy qUnleashed choices. Push categories default off; Firebase initialization and permission requests wait for explicit opt-in. Native auto-init flags are off. Opting out disables token auto-init and removes registrations after initialization, with native behavior still requiring device testing.

AI keys have no plaintext fallback and are never inserted into prompts; matching echoed keys are redacted. Device status is minimized, not retained as chat context, and only sent with per-request consent. No AI file writes, firmware operations, RF tools or shell are exposed. Requests, output tokens, response bytes and tool counts are bounded, but there is no hard dollar cost cap yet. Normal chat history is memory-only, bounded and erasable. Screen/file/voice features remain pending.

`.github/workflows/phantom-ios.yml` is a manual cloud-macOS **unsigned compile check**, syntax-checked here but not launched. Its output cannot be installed on an iPhone. Actual signing/distribution requires your Apple account and an authorized PHANTOM app identity; see [iPhone installation](docs/IPHONE_INSTALLATION.md).

Existing upload reconnect/retry behavior still needs verification before any write-capable AI is added. GPL-3.0 source and original notices are retained; original upstream README is [README.md](README.md). Full distribution review and PHANTOM app identity remain pending.
