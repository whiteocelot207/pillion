package app.pillion.ios

import app.pillion.core.ScreenSource
import kotlinx.cinterop.ExperimentalForeignApi
import kotlinx.cinterop.addressOf
import kotlinx.cinterop.convert
import kotlinx.cinterop.usePinned
import platform.CoreGraphics.CGRectMake
import platform.CoreGraphics.CGSizeMake
import platform.Foundation.NSData
import platform.UIKit.UIColor
import platform.UIKit.UIGraphicsBeginImageContextWithOptions
import platform.UIKit.UIGraphicsEndImageContext
import platform.UIKit.UIGraphicsGetImageFromCurrentImageContext
import platform.UIKit.UIImageJPEGRepresentation
import platform.UIKit.UIRectFill
import platform.posix.memcpy
import kotlin.concurrent.Volatile

/**
 * A synthetic [ScreenSource] that renders a moving test pattern instead of capturing the screen.
 *
 * ReplayKit's in-app capture is unreliable on the iOS Simulator, so this lets us prove the rest of
 * the pipe end-to-end on the Simulator — JPEG encode → NaviLite framing → handshake → stream into the
 * emulator viewer — without a device. On a real device, swap in [ReplayKitScreenSource].
 */
@OptIn(ExperimentalForeignApi::class)
class TestPatternScreenSource(
    private val width: Int = 480,
    private val height: Int = 240,
) : ScreenSource {
    @Volatile private var running = false
    @Volatile private var frame = 0

    override fun start() { running = true }
    override fun stop() { running = false }

    override fun latestFrame(): ByteArray? {
        if (!running) return null
        return render(frame++)
    }

    private fun render(i: Int): ByteArray? {
        val w = width.toDouble()
        val h = height.toDouble()
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(w, h), true, 1.0)
        // Background cycles through hues so it's obvious the stream is live and updating.
        val hue = (i % 120) / 120.0
        UIColor.colorWithHue(hue, saturation = 0.5, brightness = 0.9, alpha = 1.0).setFill()
        UIRectFill(CGRectMake(0.0, 0.0, w, h))
        // A white box sweeping left-to-right makes motion/latency visible at a glance.
        val box = 60.0
        val x = (i * 8 % (width - 60)).toDouble()
        UIColor.whiteColor().setFill()
        UIRectFill(CGRectMake(x, (h - box) / 2, box, box))
        val image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image?.let { UIImageJPEGRepresentation(it, 0.7) }?.toByteArray()
    }
}

@OptIn(ExperimentalForeignApi::class)
private fun NSData.toByteArray(): ByteArray {
    val len = length.toInt()
    if (len == 0) return ByteArray(0)
    val out = ByteArray(len)
    out.usePinned { memcpy(it.addressOf(0), bytes, len.convert()) }
    return out
}
