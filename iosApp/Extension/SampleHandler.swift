import Foundation
import ReplayKit
import CoreImage
import CoreMedia
import ImageIO
import ExternalAccessory

/// Darwin notification names the app observes to reflect broadcast state (no App Group needed).
enum BroadcastSignal {
    static let started = "app.pillion.broadcast.started"
    static let stopped = "app.pillion.broadcast.stopped"
    static func post(_ name: String) {
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(name as CFString), nil, nil, true)
    }
}

/// Broadcast Upload Extension: captures the whole screen system-wide and streams it to the dash as
/// NaviLite. Because it runs as a broadcast it keeps going while the phone is in Waze/Maps. Ported
/// from rickdash-ios; picks the bike (External Accessory) when present, else the dev emulator (TCP).
class SampleHandler: RPBroadcastSampleHandler {
    private var conn: DashConn!
    private let ci = CIContext(options: [.cacheIntermediates: false])
    private let lock = NSLock()
    private var latest: [UInt8]?
    private var lastEncode = Date(timeIntervalSince1970: 0)
    private var running = false
    private var seq = 1
    private let sendInterval = 1.0 / Double(BroadcastConfig.maxFps)

    override func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
        running = true
        BroadcastSignal.post(BroadcastSignal.started)
        let hasBike = EAAccessoryManager.shared().connectedAccessories
            .contains { $0.protocolStrings.contains(BroadcastConfig.dashProtocol) }
        let c: DashConn = hasBike ? EAConn()
                                  : TCPConn(host: BroadcastConfig.emulatorHost, port: BroadcastConfig.emulatorPort)
        c.logger = { s in NSLog("PillionExt: %@", s) }
        conn = c
        NSLog("PillionExt: transport = %@", hasBike ? "bike (External Accessory)" : "emulator (TCP)")
        Thread.detachNewThread { [weak self] in
            guard let self = self else { return }
            do { try self.conn.connect(); try self.handshake(); self.pushLoop() }
            catch { NSLog("PillionExt connect err: %@", (error as NSError).localizedDescription) }
        }
    }

    private func handshake() throws {
        var f = try conn.readFrame(timeout: 12); while f.svc != 66 { f = try conn.readFrame(timeout: 12) }
        conn.write(NaviLite.frame(6, 81, 0, [1, 0]))
        conn.write(NaviLite.frame(6, 33, 1, NaviLite.hexB("1c07000100000000")))
        f = try conn.readFrame(timeout: 12); while f.svc != 83 { f = try conn.readFrame(timeout: 12) }
        conn.write(NaviLite.frame(6, 84, 1, NaviLite.secDataAckPayload(f.payload)))
        let setup: [(UInt8, UInt8, [UInt8])] = [
            (2, 0, [0, 0]), (31, 0, [1, 0]), (10, 0, [0, 0]), (11, 0, [0, 0]), (13, 0, [1, 0]), (12, 0, [0, 0]),
            (14, 1, NaviLite.hexB("07190600302e32206d69")), (3, 1, []), (17, 1, NaviLite.hexB("00000000036d7068")),
            (13, 0, [1, 0]), (12, 0, [1, 0])]
        for (s, p, pl) in setup { conn.write(NaviLite.frame(6, s, p, pl)) }
        NSLog("PillionExt: auth + setup done")
    }

    private func pushLoop() {
        var frames = 0; var t0 = Date()
        var lastSend = Date(timeIntervalSince1970: 0)
        while running {
            // Pace to the target fps and always send the freshest frame. Without this we send as fast
            // as the link ACKs (~77 fps on WiFi), flooding the dash/viewer so latency builds up.
            let wait = sendInterval - Date().timeIntervalSince(lastSend)
            if wait > 0 { usleep(UInt32(wait * 1_000_000)) }
            lock.lock(); let j = latest; lock.unlock()
            guard let jpg = j else { usleep(15000); continue }
            lastSend = Date()
            var pl: [UInt8] = [3, UInt8(seq & 0xff), UInt8((seq >> 8) & 0xff)]; pl.append(contentsOf: jpg); seq += 1
            conn.write(NaviLite.frame(6, 0, 1, pl))
            let deadline = Date().addingTimeInterval(2)
            while Date() < deadline { if (try? conn.readFrame(timeout: 2))?.svc == 80 { break } }
            frames += 1; let dt = Date().timeIntervalSince(t0)
            if dt >= 1 { NSLog("PillionExt: FPS %.1f  %dKB", Double(frames) / dt, jpg.count / 1024); frames = 0; t0 = Date() }
        }
    }

    override func processSampleBuffer(_ sb: CMSampleBuffer, with type: RPSampleBufferType) {
        guard type == .video, running else { return }
        // Encode a touch faster than we send so a fresh frame is always ready, but no faster.
        let now = Date(); if now.timeIntervalSince(lastEncode) < sendInterval * 0.8 { return }; lastEncode = now
        // Broadcast extensions are killed past ~50 MB. CoreImage/JPEG temporaries pile up faster than
        // ARC drains them at frame rate, so each encode runs in its own autorelease pool.
        autoreleasepool {
            guard let pb = CMSampleBufferGetImageBuffer(sb) else { return }
            var orient = CGImagePropertyOrientation.up
            if let n = CMGetAttachment(sb, key: RPVideoSampleOrientationKey as CFString, attachmentModeOut: nil) as? NSNumber,
               let o = CGImagePropertyOrientation(rawValue: n.uint32Value) { orient = o }
            let fix: CGImagePropertyOrientation
            switch orient {
            case .left: fix = .right
            case .right: fix = .left
            case .leftMirrored: fix = .rightMirrored
            case .rightMirrored: fix = .leftMirrored
            default: fix = orient   // up/down are self-inverse
            }
            let img = CIImage(cvPixelBuffer: pb).oriented(fix)
            let e = img.extent
            // Aspect-FIT (letterbox): show the whole screen, centred on the 480×240 panel with black
            // bars. Works for landscape (near-full) and portrait (pillarboxed) without cropping.
            let scale = min(480.0 / e.width, 240.0 / e.height)
            let s = img.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
            let se = s.extent
            let tx = (480 - se.width) / 2 - se.origin.x
            let ty = (240 - se.height) / 2 - se.origin.y
            let centered = s.transformed(by: CGAffineTransform(translationX: tx, y: ty))
            let canvas = CGRect(x: 0, y: 0, width: 480, height: 240)
            let cropped = centered.composited(over: CIImage(color: .black).cropped(to: canvas)).cropped(to: canvas)
            let opts: [CIImageRepresentationOption: Any] =
                [CIImageRepresentationOption(rawValue: kCGImageDestinationLossyCompressionQuality as String): 0.4]
            guard let data = ci.jpegRepresentation(of: cropped, colorSpace: CGColorSpaceCreateDeviceRGB(), options: opts) else { return }
            lock.lock(); latest = [UInt8](data); lock.unlock()
        }
    }

    override func broadcastFinished() {
        running = false
        BroadcastSignal.post(BroadcastSignal.stopped)
        conn?.close()
    }
}
