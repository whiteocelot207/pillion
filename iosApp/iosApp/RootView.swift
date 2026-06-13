import SwiftUI
import ComposeApp

/// Entry view. Release builds go straight to the bike; debug builds show the dev launcher so you can
/// pick the emulator loopback or the bike (see DevLauncher).
struct RootView: View {
    var body: some View {
        #if DEBUG
        DevLauncher()
        #else
        ComposeScreen { MainViewControllerKt.MainViewControllerForBike(protocolString: bikeProtocolString) }
            .ignoresSafeArea()
        #endif
    }
}
