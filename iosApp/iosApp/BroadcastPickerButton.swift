import SwiftUI
import ReplayKit

/// Wraps the system broadcast picker, preselected to our upload extension. Tapping it shows the
/// "Start Broadcast" sheet; the extension then captures the whole screen and streams to the dash.
struct BroadcastPickerButton: UIViewRepresentable {
    let preferredExtension: String

    func makeUIView(context: Context) -> RPSystemBroadcastPickerView {
        let view = RPSystemBroadcastPickerView(frame: CGRect(x: 0, y: 0, width: 220, height: 64))
        view.preferredExtension = preferredExtension
        view.showsMicrophoneButton = false
        return view
    }

    func updateUIView(_ uiView: RPSystemBroadcastPickerView, context: Context) {}
}
