package app.pillion

import androidx.compose.ui.window.ComposeUIViewController
import app.pillion.core.MirrorController
import app.pillion.core.PreviewController
import app.pillion.ios.IosSettingsStore
import app.pillion.ui.App
import platform.UIKit.UIViewController

/**
 * iOS entry point. The Swift shell builds the [MirrorController] — a
 * [app.pillion.ios.BroadcastMirrorController] wired to the ReplayKit broadcast picker — and hands it
 * in. The shared Compose UI is byte-for-byte the same as Android; only the controller differs.
 */
fun MainViewController(controller: MirrorController): UIViewController =
    ComposeUIViewController {
        App(controller = controller, updateChecker = null, settingsStore = IosSettingsStore())
    }

/** UI-only preview entry (no controller wiring) — boots the shared UI to validate it on iOS. */
fun MainViewControllerPreview(): UIViewController =
    ComposeUIViewController {
        App(controller = PreviewController(), updateChecker = null, settingsStore = IosSettingsStore())
    }
