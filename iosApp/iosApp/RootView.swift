import SwiftUI

/// The iOS app: the shared Pillion Compose UI, with "Start mirroring" wired to the system screen
/// broadcast (the upload extension does the capture + streaming). A hidden picker host sits off-screen
/// so the Compose button can trigger it.
struct RootView: View {
    @StateObject private var bridge = BroadcastBridge()

    var body: some View {
        ZStack {
            ComposeScreen { bridge.makeViewController() }
                .ignoresSafeArea()
            BroadcastPickerHost(bridge: bridge)
                .frame(width: 44, height: 44)
                .position(x: -200, y: -200)   // kept in the hierarchy but off-screen
                .allowsHitTesting(false)
        }
    }
}
