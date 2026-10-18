# PHANTOM decisions

**ADR-P01 — Extend the existing fork.** Rationale: tested cross-platform
Flutter app; avoid duplicate protocol work and regression risk.

**ADR-P02 — Controller injection.** The PHANTOM gateway accepts the existing
DeviceController rather than instantiating FlipperOneClient or touching the
BLE transport. A new active Flipper must not silently retarget a long action.

**ADR-P03 — Read-only first.** Agent action gate initially supports only
`device.status` and `device.refresh`; refresh means request, not confirmed
completion. Unsupported operation names/arguments reject without side effects.

**ADR-P04 — Capability truthfulness.** Existing qUnleashed UI functionality is
not proof that a physical device supports the operation today. Unprobed
capabilities remain `unverified`.

**ADR-P05 — iPhone hardware boundary.** Direct BLE on iPhone; raw USB serial
CLI and full DFU in optional authenticated desktop bridge.

**ADR-P06 — Security, licensing and distribution.** No AI arbitrary shell,
no unconfirmed signal transmissions, no embedded API keys; honor GPL-3.0 and
do not claim a signed IPA until Apple signing and on-device verification.

