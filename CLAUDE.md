# CLAUDE.md — UV Index Watch Face (Garmin Venu 4)

## What this project is

A minimal Garmin Connect IQ **watch face** for the **Venu 4 / Venu 4S** that displays
only the current UV index for the user's current location. Written in **Monkey C**.
No network code, no API keys: it reads `Toybox.Weather.getCurrentConditions().uvIndex`,
which Garmin Connect feeds to the watch via the paired phone.

## Current state

Working first version, written but **not yet compiled or tested on hardware**.
Expect possible minor compile fixes depending on installed SDK version.

## Project structure

```
manifest.xml                          # app id, type=watchface, products: venu4, venu4s, minApiLevel 3.2.0
monkey.jungle                         # standard jungle file, nothing custom
source/UvFaceApp.mc                   # Application.AppBase entry, returns UvFaceView
source/UvFaceView.mc                  # ALL logic lives here
resources/strings/strings.xml         # AppName = "UV Index"
resources/drawables/drawables.xml     # LauncherIcon
resources/drawables/launcher_icon.png # placeholder sun icon (60x60)
```

## Key implementation facts (do not rediscover these)

- `conditions.uvIndex` is `Float or null`. It is **null** right after install/sync
  or when the phone hasn't pushed weather yet. The face shows `--` in that case.
  Never call `.format()` on it without a null check.
- Weather data refreshes on Garmin's schedule (~every 20–60 min via the phone).
  A watch face **cannot force a refresh**. `conditions.observationTime` (Moment)
  gives the measurement time if we want a staleness indicator.
- Venu 4 is AMOLED. In always-on mode (`onEnterSleep` → low power), the face must
  be dim, mostly black, and shift pixels periodically for burn-in protection.
  Current implementation: dim gray `FONT_NUMBER_MILD` number, vertical offset
  cycling ±12px based on `System.getClockTime().min % 3`. Keep this behavior
  in any redesign.
- Colors follow the WHO UV scale: <3 green, <6 yellow, <8 orange, <11 red,
  ≥11 violet (0xAA55FF). Labels: low / moderate / high / very high / extreme.
- `getInitialView()` uses the modern SDK 7+ return type
  `[Views] or [Views, InputDelegates]`. If compiling against an older SDK
  fails here, switch to the legacy `Array<Views or InputDelegates>` signature.
- `Toybox.Weather` requires **no** manifest permission and needs CIQ >= 3.2.0.

## Build / test / deploy

- Toolchain: VS Code + Monkey C extension + Connect IQ SDK + developer key.
- Build: command palette → "Monkey C: Build for Device" → `venu4`.
- Simulator: F5; set fake UV via Simulation → Weather. Test both power modes
  (simulator has a low-power toggle) and the null-UV case.
- Deploy options:
  - USB: copy `.prg` to `/GARMIN/Apps` (requires Garmin's proprietary cable).
  - Wireless (owner currently has NO cable): export `.iq` via
    "Monkey C: Export Project", upload to the Connect IQ Store with a free
    developer account (apps.garmin.com), install via the Connect IQ phone app
    after review (~1 day). Prefer this path unless told otherwise.

## Backlog / ideas discussed with the owner (not yet built)

1. Staleness line under the number: "updated N min ago" from `observationTime`.
2. Optional colored arc gauge around the number instead of / in addition to text.
3. Optional small clock in a corner (owner asked for UV-only; confirm before adding).

## Conventions

- Keep everything in `UvFaceView.mc` unless it grows past ~200 lines.
- No background services, no `Communications` — stay on `Toybox.Weather` only.
- Black background always (AMOLED battery + burn-in).
- Target devices stay venu4 + venu4s only unless the owner asks to broaden.