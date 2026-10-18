# PHANTOM capabilities — implementation status

Definitions: EXISTING = function in qUnleashed source/README, not retested here;
ADAPTER = implemented in PHANTOM source but runtime tests not executed;
PLANNED = not implemented; BRIDGE = optional verified host required.

| Feature | Platform | Status | Gate |
|---|---|---|---|
| BLE discovery/pairing/multiple device | iOS | EXISTING | iPhone hardware |
| Status read-only snapshot | iOS | ADAPTER | Flutter unit tests |
| Status change watcher | iOS | ADAPTER | Flutter unit tests |
| Refresh info request | iOS | ADAPTER | Connected device |
| AI action allowlist (status, refresh) | iOS | ADAPTER | Flutter unit tests |
| Screen mirroring/buttons | iOS | EXISTING | Physical session |
| Screenshot/GIF export | iOS | EXISTING | Physical session |
| Local/device files, edits and transfers | iOS | EXISTING | Read/write cases |
| Archive and saved-signal actions | iOS | EXISTING | Permission and device |
| App catalogue/install/update/remove | iOS | EXISTING | FAP compatibility |
| Firmware BLE update | iOS | EXISTING | Controlled hardware |
| NFC/RFID/iButton saved operations | iOS | EXISTING | Per-format test |
| Infrared/Sub-GHz saved operations | iOS | EXISTING | Authorised radio test |
| Pixel Draw/IR library/Pulse Plotter/maps | iOS | EXISTING | Per-tool regression |
| OpenRouter provider/model selector | iOS | PLANNED | M4 |
| Keychain credential protection | iOS | PLANNED | M4 |
| AI chat/structured tool proposal | iOS | PLANNED | M4 |
| AI multimodal/vision consent | iOS | PLANNED | M5 |
| Voice STT/TTS | iOS | PLANNED | M5 |
| Tool execution policy/audit/STOP | iOS | PLANNED | M4/M5 |
| Macros, dry-run, routines | iOS | PLANNED | M5 |
| Apple Shortcuts/App Intents | iOS | PLANNED | M5 |
| USB CLI terminal | USB bridge | BRIDGE | M6 |
| USB DFU full repair | USB bridge | BRIDGE | M6 |
| GhostESP/Feberis Pro module adapters | Supported hardware | PLANNED | verified SDK only |
| Signed TestFlight install | iOS | PLANNED | M7 |

