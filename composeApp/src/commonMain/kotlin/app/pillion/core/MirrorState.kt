package app.pillion.core

/** The single source of truth the UI renders. */
sealed interface MirrorState {
    data object Idle : MirrorState
    data object Connecting : MirrorState
    data class Streaming(val fps: Double, val kbPerFrame: Int) : MirrorState
    data class Error(val message: String) : MirrorState
}
