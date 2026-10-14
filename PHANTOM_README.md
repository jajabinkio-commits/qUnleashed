# Project PHANTOM

An in-progress derivative of qUnleashed, built on its pinned existing BLE/RPC stack. This checkout contains the supplied engineering specification, an audited/tested upstream baseline, and the first executable M1 read-only gateway and manual inspection screen. **It is not the completed application or a signed iPhone build.**

Start with [cycle 01 results](docs/IMPLEMENTATION_CYCLE_01.md), [source audit](docs/UPSTREAM_AUDIT.md), [31-capability matrix](docs/FEATURE_MATRIX.md), and [50-test acceptance status](docs/ACCEPTANCE_STATUS.md). The full contract is [MASTER_PLAN.md](docs/MASTER_PLAN.md), with [AGENTS.md](AGENTS.md) in the project root.

## Current component

Use the retained Device tab to connect a Flipper, then open **PHANTOM inspection**. Read device, power, protocol and `/ext` capacity without an AI account. Failed readings remain explicit. Stop inspection or background the app to discard late readings and stop subsequent inspection requests. The in-flight read drains or times out; STOP here is not a global stop for unrelated existing manual operations.

`lib/phantom/device/flipper_gateway.dart` also exposes canonical, read-only `/ext` and `/int` directory listing. Existing remote, files/archive, catalog/updater and toolbox screens remain in place. USB terminal and complete DFU recovery require the future authenticated host bridge. AI, provider credentials, voice, automations, Shortcuts and module adapters are not implemented in this cycle.

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

## Before AI or release

The next focused slice is opt-in diagnostics/replay/push and consent migration: upstream defaults differ from PHANTOM's privacy contract. Then complete the M1 physical gate and implement Keychain + read-only provider/tool integration. No provider key should be added until the privacy/redaction path is tested. Existing upload reconnect/retry behavior must be validated before enabling write-capable AI tools.

GPL-3.0 source and all original notices are retained. Original upstream README is [README.md](README.md). PHANTOM release branding/bundle identity and distribution review remain pending.
