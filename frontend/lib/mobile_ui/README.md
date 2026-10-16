# Mobile UI (parked)

Phone layouts for the Android APK and mobile browsers.

**Status:** parked until the web app is complete and demo-ready. The web (desktop) layout is the current priority. Requirements §21 still asks for mobile browser support, so this work is scheduled, not dropped.

## What is here

| File | Purpose |
|---|---|
| `mobile_bottom_nav.dart` | Bottom navigation with a "More" sheet, shown when the window is narrower than 760 px |

Today it only acts as a basic fallback so a narrow window does not break the layout. New phone designs and Android-specific UI go into this folder.

Tests for this folder live in `test/mobile_ui/`.
