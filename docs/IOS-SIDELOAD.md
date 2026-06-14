# Installing Pillion on iOS (no App Store)

Pillion for iOS isn't on the App Store. You install it by **sideloading** — putting the app on your
iPhone yourself with a **free Apple ID**. No paid Apple Developer account needed.

> **Read this first — the 7-day catch.** Apps sideloaded with a *free* Apple ID **stop working after
> 7 days** and must be re-signed. **AltStore / SideStore do this automatically** over WiFi, so that's
> the recommended route. The only way to avoid re-signing entirely is **TrollStore**, which only works
> on older iOS versions.

Grab **`Pillion.ipa`** from the [latest release](../../releases), then pick a method:

## Option A — AltStore / SideStore (recommended)

Auto-refreshes the app so it doesn't die every 7 days.

1. Install **[AltStore](https://altstore.io)** (needs a PC/Mac running AltServer) or **[SideStore](https://sidestore.io)**
   (refreshes on-device, no computer needed after setup).
2. Open the app → **+** → choose **`Pillion.ipa`** → sign in with your **free Apple ID**.
3. It installs Pillion **and** its broadcast extension. Leave AltStore/SideStore set to auto-refresh.

## Option B — Sideloadly (one-time, manual refresh)

1. Install **[Sideloadly](https://sideloadly.io)** on a PC/Mac.
2. Plug in the iPhone, drag in **`Pillion.ipa`**, enter your **free Apple ID**, click **Start**.
3. Re-run every ~7 days to keep it alive.

## Option C — TrollStore (permanent, older devices only)

If your iPhone runs an **iOS version TrollStore supports** (roughly iOS 14–16 and some early 17), you
can install **`Pillion.ipa`** with **[TrollStore](https://github.com/opa334/TrollStore)** — **permanent,
no Apple ID, no 7-day expiry.** Newer devices/iOS (e.g. iPhone 15+ on current iOS) aren't supported.

## After installing

1. First launch: **Settings ▸ General ▸ VPN & Device Management** → trust your Apple ID's developer profile.
2. In Pillion, tap **Start mirroring** → **Pillion Mirror** → **Start Broadcast**.
3. **Allow** the Local Network prompt (needed to reach the dash / the emulator).
4. Open Waze/Maps — it's on the dash.

## Build the IPA yourself

```bash
cd iosApp && ./build-ipa.sh        # produces an unsigned Pillion.ipa (Release)
```

It's built **unsigned on purpose** — AltStore/Sideloadly/TrollStore re-sign it with *your* Apple ID
on install. See [IOS.md](IOS.md) for the architecture.

## Why not the App Store?

Pillion is a non-commercial hobby project that talks to a Yamaha/Garmin accessory; App Store
distribution would need the paid program and raises trademark/MFi questions. Sideloading keeps it free
and open. **EU users:** alternative marketplaces (AltStore PAL) exist under the DMA, but they still
require Apple notarization + developer fees, so plain sideloading stays the simplest path.
