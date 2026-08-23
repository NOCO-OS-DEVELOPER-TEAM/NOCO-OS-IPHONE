# NOCO OS for iPhone

NOCO OS is a native SwiftUI iOS app that feels like a personal mobile operating system inside one app. NOCO AI is integrated as the system brain.

## Two apps

| App | Repo | Purpose |
|-----|------|---------|
| **NOCO AI** | `NOCO-AI-IPHONE-3` | Standalone AI companion app |
| **NOCO OS** | this repo | OS shell with homescreen, apps, Spotlight, integrated NOCO AI |

## Features (v0.1)

- NOCO Homescreen with liquid-glass style icons and clock widget
- App launcher with spring animations and haptics
- **NOCO AI** — chat, intents (open apps, notes), voice commands
- **NOCO Spotlight** — apps, notes, natural-language actions
- **NOCO Notizen** — local CRUD, search, tags, AI text actions
- **NOCO Kamera** — capture, save, AI analysis via companion
- **Einstellungen** — server pairing, system toggles, developer logs
- Companion connection to Windows NOCO AI Server (port 4747)

## Architecture

```
NOCOOS UI
  → AIService / IntentService / SearchService
  → ConnectionStore → CompanionAPI
  → Local Network → NOCO AI Server → local model
```

Services: `AIService`, `ConnectionStore`, `IntentService`, `AppLauncherService`, `SearchService`, `NotesService`, `SettingsStore`, `SpeechCommandService`

## Bundle

- **Bundle ID:** `de.noco.nocoos`
- **URL scheme:** `nocoos://`

## Build IPA (GitHub Actions)

Push to `main` or run workflow **Build NOCO OS IPA**. Artifact: `NOCO-OS.ipa`

## Pairing

1. Start NOCO AI on Windows (Companion port 4747)
2. Open **Einstellungen** in NOCO OS
3. Enter server host + PIN
4. Test connection

## Requirements

- iOS 17+
- iPhone (primary target: iPhone 15 Pro)
- NOCO AI Windows companion on same LAN or Tailscale

## License

Private — NOCO OS Developer Team
