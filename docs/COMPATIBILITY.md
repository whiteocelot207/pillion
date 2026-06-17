# Bike compatibility

Pillion works with any Yamaha that uses the **Garmin "Communication Control Unit" (CCU)** — i.e.
any bike that works with the Garmin StreetCross app. The NaviLite protocol is shared across these
models, and the auth is universal: there is **no per-bike key or pairing secret** to extract (see
[PROTOCOL.md](PROTOCOL.md)).

## Confirmed working

Reported working by the community so far:

| Model | Phone / OS | Streams? | fps | Reported by |
|-------|------------|:-------:|-----|-------------|
| **MT-07 (2025)** | — | ✅ | ~14–15 | maintainer |
| **R9 (2026)** | Galaxy S25 Ultra / Android 16 | ✅ | ~15, smooth | @rf7719. |
| **MT-09 (2025)** | Galaxy S23 / Android 16 | ✅ | ~11–12 | @mobiusixi6246 |
| **MT-09 (2024)** | Galaxy A52 / Android 14 | ✅ | ~12 | @mxtt |
| **MT-09 SP (2026)** | Android | ✅ | — | @raccoon_builds |
| **XSR900 (2025)** | Pixel 9 Pro / Android 16 | ✅ | ~11–12 | @Turbobrallan |

## Very likely compatible

Other models on the same CCU platform almost certainly work, since the protocol is shared — for
example:

- XSR900 GP
- Tracer 9 GT+
- Niken GT
- TMAX
- XMAX

**More reports welcome.** If you've tried Pillion on your bike — working or not — please open an
[issue](../../issues) or post in the [Discord](https://discord.gg/mxNV97QUnB) with your model, phone
/ OS, and result (and fps if it streams). It helps everyone.
