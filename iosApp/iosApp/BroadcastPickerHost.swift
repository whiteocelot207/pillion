import SwiftUI
import ReplayKit

/// Hosts the (hidden, off-screen) system broadcast picker. The Compose "Start mirroring" button
/// triggers it via `BroadcastBridge`, so the user never sees this control directly.
struct BroadcastPickerHost: UIViewRepresentable {
    let bridge: BroadcastBridge

    func makeUIView(context: Context) -> RPSystemBroadcastPickerView {
        let view = RPSystemBroadcastPickerView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        view.preferredExtension = "app.pillion.dev.broadcast"
        view.showsMicrophoneButton = false
        bridge.register(view)
        return view
    }

    func updateUIView(_ uiView: RPSystemBroadcastPickerView, context: Context) {}
}
