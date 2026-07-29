# UV Index Watch Face

A minimal, battery-efficient Garmin Connect IQ watch face designed for **Garmin Venu 4** and **Venu 4S** that displays the current UV index for your location.

## Screenshots

| Real Device |
| :---: |
| ![Real Device Screenshot](resources/screenshot3.png) |

## Features

- **Zero-Configuration Weather Data**: Automatically retrieves local UV index values via Garmin's built-in `Toybox.Weather` API fed from your paired smartphone. No API keys or extra companion apps required.
- **Data Staleness Indicator**: Displays `"updated N min ago"` based on `observationTime` so you know exactly how recently weather data was synced from your phone.
- **WHO UV Scale Color Coding**: Color-coded numbers based on official World Health Organization standards:
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

## Project Structure

```
├── manifest.xml                          # Connect IQ manifest (Target: Venu 4, Venu 4S, Min API 3.2.0)
├── monkey.jungle                         # Project jungle configuration
├── source/
│   ├── UvFaceApp.mc                      # Application entry point
│   └── UvFaceView.mc                     # Watch face view and rendering logic
└── resources/
    ├── strings/strings.xml               # String resources
    ├── drawables/                        # App icons and graphics
    └── screenshot3.png                   # Real device screenshot (<150KB)
```

## Requirements & Building

### Prerequisites

- [Garmin Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) (v3.2.0 or higher)
- Visual Studio Code with the **Monkey C** extension installed
- A valid Garmin Developer Key (`developer_key`) for compilation and signing

### How to Build

1. Clone this repository:
   ```bash
   git clone https://github.com/zhendawgfr/uvface.git
   cd uvface
   ```
2. Open the project folder in VS Code.
3. Open the Command Palette (`Cmd+Shift+P` on macOS / `Ctrl+Shift+P` on Windows/Linux) and select:
   - **Monkey C: Build for Device** → Select `venu4` or `venu4s`.

### Running in Simulator

Press `F5` in VS Code to launch the Connect IQ Simulator. You can simulate different UV conditions and test power modes via:
- **Simulation → Weather** (set custom UV index values or test `null` states).
- **Simulation → Toggle Low Power Mode** (test AMOLED burn-in protection shift and dimming).

## Deployment

### Option A: Connect IQ Store (Wireless)
1. In VS Code, open the Command Palette and run **Monkey C: Export Project**.
2. Upload the exported `.iq` file to your developer account on the [Garmin Connect IQ Store](https://apps.garmin.com).
3. Upload the screen image from `resources/` (`screenshot3.png`).
4. Once approved (~24-48 hrs), download and install directly to your watch via the Garmin Connect phone app.

### Option B: USB Side-Loading
1. Build the `.prg` file using **Monkey C: Build for Device**.
2. Connect your watch via USB and copy the output `.prg` file to `/GARMIN/Apps/` on the watch storage.

## License

Personal project / Open Source.
