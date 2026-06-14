package app.pillion.android

import android.util.Log
import app.pillion.core.ScreenSource
import java.io.DataInputStream
import java.io.InputStream

/**
 * A [ScreenSource] that reads JPEG frames from the [app.pillion.server.DashServer] helper over the
 * stream it was spawned on (the ADB `exec:` stdout). Frames are `[4-byte length][bytes]`; the most
 * recent one is kept for the engine to pull at its own Bluetooth send rate.
 *
 * We read off the ADB exec stream rather than a direct socket because SELinux forbids an
 * untrusted_app from connecting to a shell-owned socket; the exec stream crosses domains cleanly.
 */
class DashStreamScreenSource(input: InputStream) : ScreenSource {
    private val data = DataInputStream(input.buffered())
    private val thread = Thread(::readLoop).apply { isDaemon = true }
    @Volatile private var running = false
    @Volatile private var latest: ByteArray? = null

    override fun start() {
        if (running) return
        running = true
        thread.start()
    }

    private fun readLoop() {
        try {
            while (running) {
                val len = data.readInt()
                if (len <= 0 || len > MAX_FRAME) throw IllegalStateException("bad frame length $len")
                val frame = ByteArray(len)
                data.readFully(frame)
                latest = frame
            }
        } catch (t: Throwable) {
            if (running) Log.d(TAG, "dash stream ended: ${t.message}")
        }
    }

    override fun latestFrame(): ByteArray? = latest

    override fun stop() {
        running = false
        runCatching { data.close() }
        latest = null
    }

    private companion object {
        const val TAG = "Pillion"
        const val MAX_FRAME = 4 * 1024 * 1024
    }
}
