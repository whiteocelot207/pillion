import Foundation
import ExternalAccessory

/// The bike transport: streams NaviLite to the real dash as an MFi External Accessory.
/// Ported from the rickdash-ios proof of concept. Runs inside the broadcast extension so it keeps
/// streaming while the phone is in Waze/Maps.
final class EAConn: NSObject, StreamDelegate, DashConn {
    private var session: EASession?
    private var input: InputStream?
    private var output: OutputStream?
    private weak var streamThread: Thread?
    private let cond = NSCondition()
    private var inBuf = Data()
    private let outLock = NSLock()
    private var outQueue = Data()
    var logger: ((String) -> Void)?

    func connect() throws {
        let mgr = EAAccessoryManager.shared()
        let accs = mgr.connectedAccessories
        logger?("connected accessories: \(accs.count)")
        for a in accs { logger?(" • \(a.name)  protocols=\(a.protocolStrings)") }
        guard let acc = accs.first(where: { $0.protocolStrings.contains(BroadcastConfig.dashProtocol) }) else {
            throw err("CCU not found (no accessory advertising \(BroadcastConfig.dashProtocol)). Pair the bike + select NAV mode.")
        }
        guard let s = EASession(accessory: acc, forProtocol: BroadcastConfig.dashProtocol) else {
            throw err("EASession creation failed (protocol rejected by accessory?)")
        }
        session = s; input = s.inputStream; output = s.outputStream
        let t = Thread { [weak self] in
            guard let self = self, let inp = self.input, let outp = self.output else { return }
            inp.delegate = self; outp.delegate = self
            inp.schedule(in: .current, forMode: .default)
            outp.schedule(in: .current, forMode: .default)
            inp.open(); outp.open()
            RunLoop.current.run()
        }
        t.name = "ea-io"; t.start(); streamThread = t
        logger?("EASession opened for \(BroadcastConfig.dashProtocol)")
    }

    func stream(_ s: Stream, handle e: Stream.Event) {
        switch e {
        case .hasBytesAvailable:
            if let inp = input {
                var tmp = [UInt8](repeating: 0, count: 8192)
                let n = inp.read(&tmp, maxLength: tmp.count)
                if n > 0 { cond.lock(); inBuf.append(contentsOf: tmp[0..<n]); cond.signal(); cond.unlock() }
            }
        case .hasSpaceAvailable:
            flush()
        case .errorOccurred:
            logger?("stream error: \(s.streamError?.localizedDescription ?? "?")")
        case .endEncountered:
            logger?("stream end")
        default: break
        }
    }

    @objc private func flush() {
        guard let out = output else { return }
        outLock.lock()
        while !outQueue.isEmpty && out.hasSpaceAvailable {
            let n = outQueue.withUnsafeBytes { (p: UnsafeRawBufferPointer) -> Int in
                out.write(p.bindMemory(to: UInt8.self).baseAddress!, maxLength: outQueue.count)
            }
            if n > 0 { outQueue.removeFirst(n) } else { break }
        }
        outLock.unlock()
    }

    func write(_ bytes: [UInt8]) {
        outLock.lock(); outQueue.append(contentsOf: bytes); outLock.unlock()
        if let t = streamThread { perform(#selector(flush), on: t, with: nil, waitUntilDone: false) }
    }

    func close() {
        input?.close(); output?.close(); session = nil
    }

    private func readBytes(_ n: Int, timeout: TimeInterval) throws -> [UInt8] {
        cond.lock(); defer { cond.unlock() }
        let deadline = Date().addingTimeInterval(timeout)
        while inBuf.count < n { if !cond.wait(until: deadline) { throw err("read timeout") } }
        let out = Array(inBuf.prefix(n)); inBuf.removeFirst(n); return out
    }

    func readFrame(timeout: TimeInterval) throws -> NaviFrame {
        var h = try readBytes(16, timeout: timeout)
        while !(h[0] == 0x6e && h[1] == 0x41 && h[2] == 0x6c && h[3] == 0x40) {
            let b = try readBytes(1, timeout: timeout); h.removeFirst(); h.append(b[0])
        }
        let size = Int(h[7]) | (Int(h[8]) << 8) | (Int(h[9]) << 16) | (Int(h[10]) << 24)
        let payload = size > 0 ? try readBytes(size, timeout: timeout) : []
        return NaviFrame(svc: Int(h[6]), payload: payload)
    }

    private func err(_ s: String) -> NSError { NSError(domain: "EAConn", code: 1, userInfo: [NSLocalizedDescriptionKey: s]) }
}
