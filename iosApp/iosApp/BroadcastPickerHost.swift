import SwiftUI
import ReplayKit

/// Hosts the (hidden, off-screen) system broadcast picker. The Compose "Start mirroring" button
/// triggers it via `BroadcastBridge`, so the user never sees this control directly.
struct BroadcastPickerHost: UIViewRepresentable {
    let bridge: BroadcastBridge

    func makeUIView(context: Context) -> RPSystemBroadcastPickerView {
        let view = RPSystemBroadcastPickerView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        // Derive the extension id from the app's *own* bundle id at runtime instead of hardcoding it.
        // Sideloaders (AltStore/SideStore/Sideloadly) re-sign the IPA with a rewritten bundle id, and
        // iOS requires an app-extension id to be prefixed by its container app's id — so the extension
        // is always "<app id>.broadcast". A hardcoded "app.pillion.dev.broadcast" no longer matches the
        // installed extension after re-signing, so the picker can't pre-select it and instead shows the
        // full "choose an app to share to" list. Deriving it keeps the picker pointed at our extension.
        let appId = Bundle.main.bundleIdentifier ?? "app.pillion.dev"
        view.preferredExtension = "\(appId).broadcast"
        view.showsMicrophoneButton = false
        bridge.register(view)
        return view
    }

    func updateUIView(_ uiView: RPSystemBroadcastPickerView, context: Context) {}
}
