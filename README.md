# UV Index Watch Face

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Connect IQ](https://img.shields.io/badge/Connect%20IQ-%E2%89%A5%203.2.0-blue.svg)](https://developer.garmin.com/connect-iq/)

A minimal, battery-efficient Garmin Connect IQ watch face for round-AMOLED Garmin watches (Venu 4, Vivoactive 5/6, Fenix 8 AMOLED, Fenix E) built around one number: the current UV index at your location — plus the time and a compact hourly UV forecast.

![Real Device Screenshot](resources/screenshot3.png)

## Installation

### Garmin Connect IQ Store — coming soon

The watch face is currently in **beta review** on the Connect IQ Store. Once published, you will be able to install it wirelessly:

1. Open the **Garmin Connect IQ** app on your iOS or Android device.
2. Search for **"UV Index Watch Face"**.
3. Tap **Install** to sync it to your watch over Bluetooth.

*This section will be updated with a direct store link once the listing is public.*

### Sideloading (available now)

If you have a USB cable and the Connect IQ SDK, you can build and install it yourself today — see [Development & Building from Source](#development--building-from-source) below.

---

## Features

- **Zero-Configuration Weather Data**: Automatically retrieves local UV index values via Garmin's built-in `Toybox.Weather` API fed from your paired smartphone. No API keys, no companion app, no network code.
- **Data Provenance Line**: Shows where and when the reading was observed (e.g. `Paris · 23 min ago`, rolling over to hours/days when data is old), falling back to `updated N min ago` when the location name is unavailable.
- **Clock**: Current time at the top of the face, honoring your 12/24-hour system setting — visible in both active and always-on modes.
- **Hourly UV Forecast**: Six bars along the bottom show the UV index for the next six hours, each colored on the WHO scale with the hour beneath (active mode only).
- **WHO UV Scale Color Coding**: The displayed number is rounded first and then classified, so the digit on screen always matches its color and label:
  - 🟢 **0 – 2 (Low)**: Green
  - 🟡 **3 – 5 (Moderate)**: Yellow
  - 🟠 **6 – 7 (High)**: Orange
  - 🔴 **8 – 10 (Very High)**: Red
  - 🟣 **11+ (Extreme)**: Purple (`#AA55FF`)
- **AMOLED & Burn-In Protection**:
  - Pure black background optimized for AMOLED displays.
  - Active pixel shifting in low-power / Always-On Display (AOD) mode.
  - Reduced brightness and minimal elements during sleep state to preserve screen life and battery.
- **Offline / Sync Indicator**: Displays `--` when weather data has not yet synced from the phone or is unavailable.

## Supported Devices

| Device | SDK ID | Resolution |
| :--- | :--- | :--- |
| Garmin Venu 4 (45 mm) | `venu445mm` | 454 × 454 |
| Garmin Venu 4 (41 mm) | `venu441mm` | 390 × 390 |
| Garmin Vivoactive 5 | `vivoactive5` | 390 × 390 |
| Garmin Vivoactive 6 | `vivoactive6` | 390 × 390 |
| Garmin Fenix 8 (43 mm) | `fenix843mm` | 416 × 416 |
| Garmin Fenix 8 (47 mm, AMOLED) | `fenix847mm` | 454 × 454 |
| Garmin Fenix 8 Pro (47 mm) | `fenix8pro47mm` | 454 × 454 |
| Garmin Fenix E | `fenixe` | 416 × 416 |

The layout is tuned on the 454 px screen and scaled proportionally on smaller resolutions. Only round AMOLED devices are targeted — the always-on mode relies on a dim, mostly-black design that doesn't suit transflective MIP displays.

## Roadmap

- [ ] Public Connect IQ Store listing (currently in beta review)
- [ ] Additional languages (currently English only)
- [x] Broader device support beyond the Venu 4 family (round AMOLED devices; more planned, e.g. Venu 2/3, Epix 2, Forerunner 165/265/965)
- [ ] Optional colored arc gauge around the UV number

Suggestions and contributions welcome — open an issue or PR.

---

## Development & Building from Source

If you want to modify or contribute to this watch face, you can build and run it locally using the Connect IQ SDK.

### Prerequisites

- [Garmin Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) (v3.2.0 or higher)
- Visual Studio Code with the **Monkey C** extension installed
- A Garmin Developer Key for compilation and signing (the extension can generate one; it is **not** included in this repository)

### Building & Running in Simulator

1. Clone this repository:
   ```bash
   git clone https://github.com/zhendawgfr/uvface.git
   cd uvface
   ```
2. Open the project folder in VS Code.
3. Press `F5` to launch the Connect IQ Simulator.
   - Test weather states via **Simulation → Weather** (including the no-data `null` case).
   - Test AMOLED burn-in protection shift & dimming via **Simulation → Toggle Low Power Mode**.
4. To build for a physical device:
   - Open Command Palette (`Cmd+Shift+P` / `Ctrl+Shift+P`) → **Monkey C: Build for Device** → select your device (e.g. `venu445mm`; see the table above for all SDK IDs).

### Manual Sideloading (USB)

1. Build the `.prg` file using **Monkey C: Build for Device**.
2. Connect your watch via USB and copy the output `.prg` file into the `/GARMIN/Apps/` folder on your watch storage.

---

## Project Structure

```
├── manifest.xml                          # Connect IQ manifest (8 round-AMOLED targets, Min API 3.2.0)
├── monkey.jungle                         # Project jungle configuration
├── source/
│   ├── UvFaceApp.mc                      # Application entry point
│   └── UvFaceView.mc                     # Watch face view and rendering logic
├── resources/
│   ├── strings/strings.xml               # String resources
│   ├── drawables/                        # App icons and graphics
│   └── screenshot3.png                   # Real device screenshot
└── LICENSE                               # MIT
```

## Contributing

Issues and pull requests are welcome. Keep in mind the design philosophy: **UV first**, black background, no network code, no configuration screens. Feature ideas that fit that scope (see the roadmap) are the most likely to be merged.

## License

This project is open source and available under the [MIT License](LICENSE).
