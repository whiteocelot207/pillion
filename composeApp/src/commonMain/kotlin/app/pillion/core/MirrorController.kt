package app.pillion.core

import kotlinx.coroutines.flow.StateFlow

/**
 * What the UI needs from a mirroring session. Each platform entrypoint supplies the implementation
 * (wiring permissions + the platform ByteChannel/ScreenSource), so the Compose UI stays platform-agnostic.
 */
interface MirrorController {
    val state: StateFlow<MirrorState>
    fun start(settings: MirrorSettings)
    fun stop()
}
