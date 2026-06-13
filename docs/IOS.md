# iOS port (work in progress)

The shared Kotlin (`commonMain`) — NaviLite protocol, `MirrorEngine`, and the **entire Compose UI** —
compiles and runs on iOS unchanged. Only the platform glue is new, and it mirrors the Android split:

| Interface (`commonMain`) | Android actual | iOS plan |
|--------------------------|----------------|----------|
| `ByteChannel`            | RFCOMM `BluetoothSocket` | **External Accessory** (`EASession`, protocol `com.garmin.navilite.data`) |
| `ScreenSource`           | MediaProjection | **ReplayKit** broadcast upload extension |
| `SettingsStore`          | SharedPreferences | `NSUserDefaults` ✅ (`IosSettingsStore`) |
| `Logger` / `nowMs` / `sleepMs` / `BackHandler` | — | ✅ done in `iosMain` |

## What's in this branch

- iOS targets (`iosX64`, `iosArm64`, `iosSimulatorArm64`) + a static `ComposeApp` framework.
- `iosMain` actuals: `Platform.ios`, `Logger.ios`, `BackHandler.ios`.
- `IosSettingsStore` (NSUserDefaults), `IosMirrorController` (wraps the shared `MirrorEngine`).
- Entry points in `MainViewController.kt`:
  - `MainViewControllerPreview()` — boots the **UI only** (no transport), to validate Compose on iOS.
  - `MainViewController(channel, screen)` — the real entry; Swift injects the platform glue.

## What's left (device work — needs a Mac + Xcode + the bike)

The transport and screen capture are implemented in **Swift** (conforming to the Kotlin `ByteChannel`
and `ScreenSource` interfaces exposed by the framework), porting the proven `rickdash-ios` PoC:

1. **`EAByteChannel` (Swift):** find the bonded accessory advertising `com.garmin.navilite.data`,
   open an `EASession`, and bridge its input/output streams to `open()/read()/write()/close()`.
   Requires in `Info.plist`: `UISupportedExternalAccessoryProtocols = [com.garmin.navilite.data]`,
   plus the MFi/External Accessory capability.
2. **`ReplayKitScreenSource` (Swift):** a **Broadcast Upload Extension** captures the whole screen;
   it hands 480×240 JPEG frames to the main app via an App Group (shared memory / local socket).
   `latestFrame()` returns the most recent one. (Whole-screen capture can't be done in-process.)
3. **`iosApp` Xcode project:** a SwiftUI/UIKit shell that builds the Gradle framework
   (`./gradlew :composeApp:embedAndSignAppleFrameworkForXcode`), constructs the two Swift glue
   classes, and presents `MainViewController(channel:screen:)`. Plus signing (free personal team
   works for sideload; App Store/TestFlight later).

The orientation handling (ReplayKit gives a portrait buffer + an orientation attachment; apply the
**inverted** landscape pair) is already solved in `rickdash-ios` — reuse it.

## Build

```bash
./gradlew :composeApp:compileKotlinIosSimulatorArm64   # compile the shared iOS framework
```

The first run downloads the Kotlin/Native toolchain (large). The Android build is unaffected.
