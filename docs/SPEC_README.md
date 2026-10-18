# PHANTOM — Codex starter pack

This package is an engineering SPECIFICATION and task starter, not an app or an IPA.

1. Clone/fork https://github.com/DarkFlippers/qUnleashed (including git submodules) in your Codex workspace.
2. Copy `AGENTS.md` to repository root. Copy `MASTER_PLAN.md` and `ACCEPTANCE_TESTS.md` into `docs/`. Copy `FEATURE_MATRIX.csv` into `docs/` (Codex should maintain a Markdown mirror).
3. Paste `CODEX_START_PROMPT.txt` as the initial Codex message.
4. Allow Codex to audit current source code, implement feature slices and test them. Do not assume a signed iPhone app exists until macOS/Xcode and Apple signing steps pass.
5. To verify physical Bluetooth, use an actual iPhone paired to Flipper Zero. To support Flipper USB CLI/full DFU repair, use the documented optional host bridge.

One-line project target: **qUnleashed-quality iPhone control + typed AI actions + Apple Shortcuts + optional authenticated USB bridge.**

Important: qUnleashed is GPL-3.0; preserve notices and comply with its terms before distribution. Never replace a working firmware/`.fap` component based on an unverified version-number assumption.
