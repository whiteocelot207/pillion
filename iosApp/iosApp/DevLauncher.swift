#if DEBUG
import SwiftUI
import ComposeApp

/// Debug-only launcher: choose the dev transport.
///
/// - **Emulator** (loopback): point at `receiver.py`'s TCP dash (`127.0.0.1:7220` on this Mac, or the
///   Pi's IP). "Test pattern" feeds a synthetic moving frame so the Simulator works without ReplayKit.
/// - **Bike**: the real MFi/External Accessory dash — only resolves on a physical iPhone paired to it.
struct DevLauncher: View {
    @State private var host = "127.0.0.1"
    @State private var port = "7220"
    @State private var useTestPattern = true
    @State private var make: (() -> UIViewController)?

    var body: some View {
        if let make {
            ComposeScreen(make: make).ignoresSafeArea()
        } else {
            NavigationView {
                Form {
                    Section(header: Text("Emulator (dev loopback)")) {
                        TextField("Host", text: $host)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        TextField("Port", text: $port)
                            .keyboardType(.numberPad)
                        Toggle("Test pattern (Simulator)", isOn: $useTestPattern)
                        Button("Connect to emulator") {
                            let h = host
                            let p = Int32(port) ?? 7220
                            let tp = useTestPattern
                            make = {
                                tp
                                ? MainViewControllerKt.MainViewControllerForEmulatorTestPattern(host: h, port: p)
                                : MainViewControllerKt.MainViewControllerForEmulator(host: h, port: p)
                            }
                        }
                    }
                    Section(header: Text("Bike (real MFi dash)")) {
                        Text("Run on a physical iPhone paired to the bike.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Button("Connect to bike") {
                            make = {
                                MainViewControllerKt.MainViewControllerForBike(protocolString: bikeProtocolString)
                            }
                        }
                    }
                    Section(header: Text("Whole-screen broadcast (→ dash)")) {
                        Text("Mirrors the entire screen — start it, then open Waze/Maps. Streams to the bike if connected, else the dev emulator. The two options above only mirror Pillion's own screen.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        BroadcastPickerButton(preferredExtension: "app.pillion.dev.broadcast")
                            .frame(height: 64)
                    }
                }
                .navigationTitle("Pillion dev")
            }
        }
    }
}
#endif
