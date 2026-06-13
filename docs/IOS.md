# iOS port (work in progress)

The shared Kotlin (`commonMain`) — NaviLite protocol, `MirrorEngine`, and the **entire Compose UI** —
compiles and runs on iOS unchanged. Only the platform glue is new, and it mirrors the Android split:

| Interface (`commonMain`) | Android actual | iOS actual |
|--------------------------|----------------|------------|
| `ByteChannel`            | RFCOMM `BluetoothSocket` | `ExternalAccessoryByteChannel` (bike, MFi) **+** `NetworkByteChannel` (dev loopback, TCP) |
| `ScreenSource`           | MediaProjection | `ReplayKitScreenSource` (RPScreenRecorder → JPEG) |
| `SettingsStore`          | SharedPreferences | `IosSettingsStore` (NSUserDefaults) ✅ |
| `Logger` / `nowMs` / `sleepMs` / `BackHandler` | — | ✅ done in `iosMain` |

All of the above **compiles** for `iosX64` / `iosArm64` / `iosSimulatorArm64`.

## The transport problem (why there are two channels)

The bike's dash is an **MFi accessory**. On iOS that means the production link is **External
Accessory** (`EASession`), and MFi authentication is **hardware-enforced by iOS itself**:

- On connect, the iPhone challenges the accessory; a real **Apple Authentication Coprocessor** must
  sign it (RSA-1024, private key fused into the chip, **not extractable**). Fail it and the iPhone
  never even lists the device — your app sees nothing.
- iOS also exposes **no API for Bluetooth Classic SPP/RFCOMM** (the link Android uses).

So **no PC, Mac, or Raspberry Pi can pose as the iOS dash** — a faithful emulator would need a genuine
auth coprocessor wired in over I²C plus a full iAP2 accessory stack. The iOS **production transport is
therefore only testable on the actual bike.**

But everything *above* the transport — ReplayKit capture → JPEG → NaviLite framing/CRC → echo-auth
handshake → the `MirrorEngine` loop — is **identical bytes** regardless of link. So we exercise that
~95% against the emulator over a plain TCP socket (`NetworkByteChannel`), the one local wire iOS will
give us to a non-MFi box.

## Build configuration (transport gating)

The Swift shell selects the entry point with `#if DEBUG`:

| Build | Bike (`MainViewControllerForBike`, EASession) | Emulator (`MainViewControllerForEmulator`, TCP) |
|-------|:---:|:---:|
| **Release** | ✅ only | ❌ excluded |
| **Debug / dev** | ✅ (test on the real bike) | ✅ (loopback to the Pi emulator) |

A dev build still talks to the bike — it just **also** offers the emulator loopback. Release builds
ship the bike path only.

## How to run against the emulator (no bike)

1. Start the emulator's TCP dash — either locally (`python3 receiver.py`, dash on `127.0.0.1:7220`)
   or on the Pi (the `--bluetooth` service keeps TCP `7220` open too; use the Pi's IP).
2. Launch a **Debug** build and choose the emulator transport, pointing it at that host:port.
3. Watch the screen appear in the viewer at `http://<host>:8080`.

## The `iosApp` Xcode project ✅

`iosApp/` is a SwiftUI shell (generated from `iosApp/project.yml` via [XcodeGen]). A build phase
compiles + copies the Kotlin/Native static framework, and the Swift entry view picks the transport:

- **`RootView`** — release goes straight to `MainViewControllerForBike`; debug shows `DevLauncher`.
- **`DevLauncher`** (`#if DEBUG`) — a form to choose the **emulator** (host/port, with a "test
  pattern" toggle) or the **bike**, then presents the Compose UI.

It builds and links cleanly for the simulator and device. Generate + open:

```bash
brew install xcodegen          # once
cd iosApp && xcodegen generate # writes iosApp.xcodeproj (gitignored)
open iosApp.xcodeproj
```

### Running against the emulator (no bike)

1. Start the emulator's TCP dash — locally (`python3 receiver.py`, `127.0.0.1:7220`) or on the Pi
   (the `--bluetooth` service keeps TCP `7220` open too; use the Pi's IP from a device).
2. In Xcode, set the **Signing team** (Signing & Capabilities → your Apple ID; re-auth in
   Settings ▸ Accounts if needed), pick the **Simulator** or your **iPhone**, and Run.
3. In `DevLauncher`: set host/port (`127.0.0.1` on the Simulator, the Pi's IP on a device), keep
   **Test pattern** on for first light, tap **Connect to emulator**, then **Start** in the app
   (allow the local-network prompt).
4. The frame appears live in the viewer at `http://<host>:8080`. Flip **Test pattern** off on a real
   device to stream the actual screen via `ReplayKitScreenSource`.

## What's left

1. **ReplayKit on a real device:** in-app `RPScreenRecorder` covers the app's own surface; a Broadcast
   Upload Extension (via an App Group) is the path if we later need whole-screen / out-of-app capture.
2. **Bike bring-up:** confirm the dash's EA protocol string on a connected bike via
   `EAAccessory.protocolStrings`, set it in `Config.swift` + `UISupportedExternalAccessoryProtocols`
   (Info.plist), and test `ExternalAccessoryByteChannel` on the bike.

## Build (shared framework only)

```bash
./gradlew :composeApp:compileKotlinIosSimulatorArm64   # compile the shared iOS framework
```

The first run downloads the Kotlin/Native toolchain (large). The Android build is unaffected.

[XcodeGen]: https://github.com/yonaskolb/XcodeGen
