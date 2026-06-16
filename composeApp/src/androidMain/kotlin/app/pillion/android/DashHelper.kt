package app.pillion.android

import android.content.Context
import android.util.Log
import app.pillion.core.DashResolution
import app.pillion.server.DashServer
import java.net.InetSocketAddress
import java.net.Socket

/**
 * Owns the shell-side dash helper lifecycle. Starting the helper needs Wireless Debugging because
 * it runs as shell, but once started it serves frames over loopback and survives Wi-Fi loss.
 */
object DashHelper {
    const val DEFAULT_QUALITY = 40

    private const val TAG = "Pillion"
    private const val DPI = 160
    private const val DASH_PROTOCOL_WIDTH = 480
    private const val DASH_PROTOCOL_HEIGHT = 240
    private const val CONNECT_TIMEOUT_MS = 250
    private const val START_TIMEOUT_MS = 5_000L

    fun ensureRunning(
        context: Context,
        quality: Int,
        dashResolution: DashResolution,
        preferExisting: Boolean = false,
    ) {
        if (preferExisting && isRunning()) {
            Log.d(TAG, "dash: using existing helper")
            return
        }

        val appContext = context.applicationContext
        val adb = PillionAdb.getInstance(appContext)
        val connected = runCatching { adb.autoConnectDevice(appContext, timeoutMs = 15_000) }
            .onSuccess { Log.d(TAG, "dash: adb auto-connect=$it") }
            .onFailure { Log.w(TAG, "dash: adb auto-connect failed", it) }
            .getOrDefault(false)

        if (!connected) {
            if (isRunning()) {
                Log.d(TAG, "dash: using existing helper; Wireless debugging unavailable")
                return
            }
            throw IllegalStateException(
                "Wireless debugging is not connected. Connect to Wi-Fi once and re-run dash setup " +
                    "before starting without Wi-Fi.",
            )
        }

        runCatching { adb.prepareDashPrivileges(appContext) }
            .onSuccess { Log.d(TAG, "dash: granted usage-stats appop through shell") }
            .onFailure { Log.w(TAG, "dash: could not grant usage-stats appop", it) }

        // Clear any stale helper so resolution/quality changes apply whenever ADB is reachable.
        runCatching { adb.runShell("pkill -f app.pillion.server.DashServer") }
        waitUntilStopped()
        spawn(adb, appContext, quality, dashResolution)
        check(waitUntilRunning()) { "Dash helper did not start" }
    }

    fun isRunning(): Boolean =
        runCatching {
            Socket().use { socket ->
                socket.connect(InetSocketAddress("127.0.0.1", DashServer.PORT), CONNECT_TIMEOUT_MS)
            }
        }.isSuccess

    private fun spawn(adb: PillionAdb, context: Context, quality: Int, dashResolution: DashResolution) {
        Log.d(
            TAG,
            "dash: spawning helper virtual=${dashResolution.width}x${dashResolution.height} " +
                "output=${DASH_PROTOCOL_WIDTH}x$DASH_PROTOCOL_HEIGHT",
        )
        // Detach the helper so it survives ADB disconnect AND Wi-Fi loss:
        // 1. setsid gives it a new session/process group, outside adbd's teardown group.
        // 2. the shell backgrounds app_process and exits, so the helper reparents to init.
        //
        // Include SYSTEMSERVERCLASSPATH so the helper can load com.android.server.display.DisplayControl
        // on its main classloader for physical-panel power control.
        val inner = "CLASSPATH=\$(pm path ${context.packageName} | grep base.apk | cut -d: -f2):\$SYSTEMSERVERCLASSPATH " +
            "app_process / app.pillion.server.DashServer " +
            "${dashResolution.width} ${dashResolution.height} $DPI $quality " +
            "$DASH_PROTOCOL_WIDTH $DASH_PROTOCOL_HEIGHT " +
            "</dev/null >/dev/null 2>&1 &"
        val stream = adb.openShellStream("setsid sh -c '$inner'")
        runCatching { stream.openInputStream().readBytes() }
            .onFailure { t ->
                if (t.message?.contains("Stream closed", ignoreCase = true) != true) throw t
            }
        runCatching { stream.close() }
        Log.d(TAG, "dash: helper spawned (detached to init)")
    }

    private fun waitUntilRunning(): Boolean {
        val deadline = System.currentTimeMillis() + START_TIMEOUT_MS
        while (System.currentTimeMillis() < deadline) {
            if (isRunning()) return true
            Thread.sleep(100)
        }
        return isRunning()
    }

    private fun waitUntilStopped() {
        val deadline = System.currentTimeMillis() + START_TIMEOUT_MS
        while (System.currentTimeMillis() < deadline && isRunning()) {
            Thread.sleep(100)
        }
    }
}
