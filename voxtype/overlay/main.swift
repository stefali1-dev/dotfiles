// voxtype-overlay: the Mac version of the strip Omarchy shows while Voxtype records.
//
// A port of Voxtype's GTK4 OSD (src/bin/voxtype_osd_gtk4.rs and src/osd/ in the voxtype repo): the same
// look, sizes and motion, drawn natively. It reads the level frames the daemon streams during a recording
// and adds one Mac-only piece: a sound and a "No mic signal" label when the mic delivers silence.
//
// Usage: voxtype-overlay [--socket PATH] [--snapshot DIR]
//   --snapshot DIR  draw the strip from made-up audio into PNGs in DIR and exit (for checking the look)

import AppKit

// Values from Voxtype's OSD defaults (src/osd/config.rs, src/osd/ipc.rs, voxtype_osd_gtk4.rs).
let frameHz = 100.0
let windowSecs = 3.0
let playoutDelayFrames = frameHz * 0.05
let waveformGain = 10.0
let hideAfterSecs = 0.15
let stripSize = NSSize(width: 400, height: 48)
let topMargin = 0.85  // top edge of the strip, as a fraction of the screen height
let meterSegments = 10
let meterFloorDb = -60.0
let peakDecayDbPerSec = 6.0

// Dead mic: every frame in the first second after a short warm-up stays below this level.
let deadMicDb: Float = -70
let deadMicWarmupFrames = 15
let deadMicWindowFrames = 100

let logPath = NSString(string: "~/Library/Logs/voxtype/overlay.log").expandingTildeInPath

struct Frame {
    var seq: UInt32
    var min: Float
    var max: Float
    var peakDb: Float
}

/// The frames of the current recording, filled by the socket thread and read when drawing.
/// Scrolling follows elapsed time rather than packet arrival, a port of voxtype's FrameRing.
final class Levels {
    private let lock = NSLock()
    private let capacity = Int(windowSecs * frameHz + playoutDelayFrames * 2) + 2
    private var frames: [Frame] = []
    private var origin: TimeInterval?
    private var received = 0
    private var lastFrameAt: TimeInterval = 0

    // Per recording, for the dead-mic check and the log.
    private var startFrames: [Float] = []
    private var loudestDb: Float = -120
    private(set) var micDead = false
    private var warned = false

    func push(_ frame: Frame, at now: TimeInterval) -> (isNewRecording: Bool, micJustDied: Bool) {
        lock.lock()
        defer { lock.unlock() }
        let isNew = frames.last.map { frame.seq != $0.seq &+ 1 } ?? true
        if isNew { reset() }
        let start = origin ?? now
        // After an underrun, resume where the display stopped instead of racing through late frames.
        if (now - start) * frameHz > Double(received) + playoutDelayFrames {
            origin = now - (Double(max(received - 1, 0)) + playoutDelayFrames) / frameHz
        } else {
            origin = start
        }
        received += 1
        frames.append(frame)
        if frames.count > capacity { frames.removeFirst() }
        lastFrameAt = now

        loudestDb = max(loudestDb, frame.peakDb)
        var died = false
        if startFrames.count < deadMicWarmupFrames + deadMicWindowFrames {
            startFrames.append(frame.peakDb)
            if startFrames.count == deadMicWarmupFrames + deadMicWindowFrames,
               startFrames.dropFirst(deadMicWarmupFrames).allSatisfy({ $0 < deadMicDb }) {
                micDead = true
                warned = true
                died = true
            }
        }
        if micDead && frame.peakDb >= deadMicDb { micDead = false }
        return (isNew, died)
    }

    func secondsSinceLastFrame(at now: TimeInterval) -> TimeInterval {
        lock.lock()
        defer { lock.unlock() }
        return now - lastFrameAt
    }

    /// Ends the recording: returns its summary for the log and clears the history.
    func finish() -> String? {
        lock.lock()
        defer { lock.unlock() }
        guard received > 0 else { return nil }
        let summary = String(format: "%.1fs, loudest %.0f dBFS%@", Double(received) / frameHz,
                             loudestDb, warned ? ", no mic signal warning" : "")
        reset()
        return summary
    }

    func snapshot(at now: TimeInterval) -> (frames: [Frame], scrollOffset: Double, micDead: Bool) {
        lock.lock()
        defer { lock.unlock() }
        guard let origin else { return (frames, 0, micDead) }
        let offset = min(0, (now - origin) * frameHz - Double(received - 1) - playoutDelayFrames)
        return (frames, offset, micDead)
    }

    private func reset() {
        frames.removeAll(keepingCapacity: true)
        origin = nil
        received = 0
        startFrames.removeAll()
        loudestDb = -120
        micDead = false
        warned = false
    }
}

struct Palette {
    var background = NSColor(red: 0.10, green: 0.10, blue: 0.12, alpha: 0.85)
    var accent = NSColor(red: 0.40, green: 0.78, blue: 1.00, alpha: 1)
    var foreground = NSColor(red: 0.92, green: 0.92, blue: 0.95, alpha: 1)
    let meterLow = NSColor(red: 0.30, green: 0.85, blue: 0.45, alpha: 1)
    let meterMid = NSColor(red: 0.95, green: 0.80, blue: 0.30, alpha: 1)
    let meterHigh = NSColor(red: 0.95, green: 0.35, blue: 0.30, alpha: 1)

    /// The Omarchy theme's colors, which the Mac follows through the same path.
    static func fromTheme() -> Palette {
        var palette = Palette()
        let path = NSString(string: "~/.local/state/omarchy/current/theme/colors.toml").expandingTildeInPath
        guard let text = try? String(contentsOfFile: path, encoding: .utf8) else { return palette }
        for line in text.split(separator: "\n") {
            let parts = line.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count == 2, let color = hexColor(parts[1].trimmingCharacters(in: CharacterSet(charactersIn: "\""))) else { continue }
            switch parts[0] {
            case "background": palette.background = color.withAlphaComponent(0.85)
            case "accent": palette.accent = color
            case "foreground": palette.foreground = color
            default: break
            }
        }
        return palette
    }

    static func hexColor(_ hex: String) -> NSColor? {
        guard hex.hasPrefix("#"), hex.count == 7, let value = UInt32(hex.dropFirst(), radix: 16) else { return nil }
        return NSColor(red: CGFloat((value >> 16) & 0xff) / 255, green: CGFloat((value >> 8) & 0xff) / 255,
                       blue: CGFloat(value & 0xff) / 255, alpha: 1)
    }
}

final class StripView: NSView {
    let levels: Levels
    var palette = Palette.fromTheme()
    var now: () -> TimeInterval = { ProcessInfo.processInfo.systemUptime }
    private var heldDb = -120.0
    private var lastDraw: TimeInterval = 0

    init(levels: Levels) {
        self.levels = levels
        super.init(frame: NSRect(origin: .zero, size: stripSize))
        wantsLayer = true
    }

    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ dirtyRect: NSRect) {
        let t = now()
        let (frames, scrollOffset, micDead) = levels.snapshot(at: t)

        palette.background.setFill()
        bounds.fill(using: .copy)

        // Layout: waveform on the left, a small gap, the peak meter on the right 7%.
        let meterWidth = max(bounds.width * 0.07, 8)
        let gap = max(bounds.width * 0.01, 2)
        let wave = NSRect(x: 0, y: 0, width: bounds.width - meterWidth - gap, height: bounds.height)
        drawWaveform(in: wave, frames: frames, scrollOffset: scrollOffset)

        let latestDb = Double(frames.last?.peakDb ?? -120)
        heldDb = max(latestDb, max(heldDb - peakDecayDbPerSec * (t - lastDraw), -120))
        if frames.isEmpty { heldDb = -120 }
        lastDraw = t
        drawMeter(in: NSRect(x: wave.maxX + gap, y: 0, width: meterWidth, height: bounds.height), latestDb: latestDb)

        if micDead { drawLabel("No mic signal", in: wave) }
    }

    /// Mirrored min/max envelope of the last few seconds, filled in the accent color.
    private func drawWaveform(in rect: NSRect, frames: [Frame], scrollOffset: Double) {
        let columns = projectEnvelope(frames, columns: Int(rect.width), windowFrames: windowSecs * frameHz,
                                      rightOffset: scrollOffset)
        let mid = rect.midY
        let half = rect.height / 2
        func y(_ sample: Float) -> CGFloat { mid + min(max(CGFloat(sample) * waveformGain, -1), 1) * half }

        let path = NSBezierPath()
        for (i, column) in columns.enumerated() {
            let point = NSPoint(x: rect.minX + CGFloat(i) + 0.5, y: y(column.max))
            i == 0 ? path.move(to: point) : path.line(to: point)
        }
        for (i, column) in columns.enumerated().reversed() {
            path.line(to: NSPoint(x: rect.minX + CGFloat(i) + 0.5, y: y(column.min)))
        }
        path.close()
        palette.accent.setFill()
        path.fill()

        palette.foreground.withAlphaComponent(0.15).setFill()
        NSRect(x: rect.minX, y: mid - 0.5, width: rect.width, height: 1).fill(using: .sourceOver)
    }

    /// Segmented level meter: green for speech, yellow when loud, red near clipping, plus a falling peak tick.
    private func drawMeter(in rect: NSRect, latestDb: Double) {
        let fill = meterFraction(latestDb)
        let segmentGap = 1.5
        let segmentHeight = max((rect.height - segmentGap * Double(meterSegments - 1)) / Double(meterSegments), 1)
        for i in 0..<meterSegments {
            let topDb = meterFloorDb * (1 - Double(i + 1) / Double(meterSegments))
            let color = topDb >= -3 ? palette.meterHigh : topDb >= -12 ? palette.meterMid : palette.meterLow
            let lit = fill >= (Double(i) + 0.5) / Double(meterSegments)
            color.withAlphaComponent(lit ? 1 : 0.18).setFill()
            NSRect(x: rect.minX, y: rect.minY + Double(i) * (segmentHeight + segmentGap),
                   width: rect.width, height: segmentHeight).fill(using: .sourceOver)
        }
        if heldDb > meterFloorDb {
            palette.foreground.withAlphaComponent(0.95).setFill()
            NSRect(x: rect.minX, y: rect.minY + meterFraction(heldDb) * rect.height - 0.75,
                   width: rect.width, height: 1.5).fill(using: .sourceOver)
        }
    }

    private func drawLabel(_ text: String, in rect: NSRect) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12, weight: .medium),
            .foregroundColor: palette.foreground,
        ]
        let size = text.size(withAttributes: attributes)
        let box = NSRect(x: rect.midX - size.width / 2 - 8, y: rect.midY - size.height / 2 - 2,
                         width: size.width + 16, height: size.height + 4)
        palette.background.withAlphaComponent(1).setFill()
        NSBezierPath(roundedRect: box, xRadius: 4, yRadius: 4).fill()
        text.draw(at: NSPoint(x: box.minX + 8, y: box.minY + 2), withAttributes: attributes)
    }
}

func meterFraction(_ db: Double) -> Double {
    db <= meterFloorDb ? 0 : (min(db, 0) - meterFloorDb) / -meterFloorDb
}

/// One min/max column per point across the visible window, a port of voxtype's project_envelope.
func projectEnvelope(_ frames: [Frame], columns: Int, windowFrames: Double, rightOffset: Double)
    -> [(min: Float, max: Float)] {
    var out = [(min: Float, max: Float)](repeating: (0, 0), count: columns)
    guard !frames.isEmpty, columns > 0 else { return out }
    let right = Double(frames.count - 1) + rightOffset
    let step = max(windowFrames, 1) / Double(max(columns - 1, 1))
    func sample(_ index: Int) -> (min: Float, max: Float) {
        frames.indices.contains(index) ? (frames[index].min, frames[index].max) : (0, 0)
    }
    func interpolate(_ position: Double) -> (min: Float, max: Float) {
        let index = Int(position.rounded(.down))
        let fraction = Float(position - position.rounded(.down))
        let a = sample(index), b = sample(index + 1)
        return (a.min + (b.min - a.min) * fraction, a.max + (b.max - a.max) * fraction)
    }
    for column in 0..<columns {
        let position = right - Double(columns - 1 - column) * step
        var value = interpolate(position)
        if step > 1 {
            let start = position - step
            let edge = interpolate(start)
            value = (min(value.min, edge.min), max(value.max, edge.max))
            let first = min(max(Int(start.rounded(.up)), 0), frames.count)
            let end = min(max(Int(position.rounded(.down)) + 1, 0), frames.count)
            for frame in frames[first..<max(first, end)] {
                value = (min(value.min, frame.min), max(value.max, frame.max))
            }
        }
        out[column] = value
    }
    return out
}

/// Reads 16-byte level frames from the daemon's socket forever, reconnecting every second.
func readFrames(from path: String, onFrame: (Frame) -> Void) -> Never {
    while true {
        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        var address = sockaddr_un()
        address.sun_family = sa_family_t(AF_UNIX)
        withUnsafeMutableBytes(of: &address.sun_path) { buffer in
            buffer.copyBytes(from: path.utf8.prefix(buffer.count - 1))
        }
        let connected = withUnsafePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                connect(fd, $0, socklen_t(MemoryLayout<sockaddr_un>.size)) == 0
            }
        }
        if connected {
            var buffer = [UInt8](repeating: 0, count: 16)
            var filled = 0
            while true {
                let count = buffer.withUnsafeMutableBytes { read(fd, $0.baseAddress! + filled, 16 - filled) }
                if count <= 0 { break }
                filled += count
                if filled < 16 { continue }
                filled = 0
                let frame = buffer.withUnsafeBytes {
                    Frame(seq: $0.loadUnaligned(fromByteOffset: 0, as: UInt32.self),
                          min: $0.loadUnaligned(fromByteOffset: 4, as: Float.self),
                          max: $0.loadUnaligned(fromByteOffset: 8, as: Float.self),
                          peakDb: $0.loadUnaligned(fromByteOffset: 12, as: Float.self))
                }
                if frame.min.isFinite && frame.max.isFinite && !frame.peakDb.isNaN { onFrame(frame) }
            }
        }
        close(fd)
        sleep(1)
    }
}

func log(_ message: String) {
    let line = "\(ISO8601DateFormatter().string(from: Date())) \(message)\n"
    if let handle = FileHandle(forWritingAtPath: logPath) {
        handle.seekToEndOfFile()
        handle.write(Data(line.utf8))
        handle.closeFile()
    } else {
        FileManager.default.createFile(atPath: logPath, contents: Data(line.utf8))
    }
}

final class Overlay: NSObject {
    let levels = Levels()
    let panel: NSPanel
    let view: StripView
    private var displayLink: CADisplayLink?
    private var visible = false

    override init() {
        view = StripView(levels: levels)
        panel = NSPanel(contentRect: NSRect(origin: .zero, size: stripSize),
                        styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: true)
        panel.level = .statusBar
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.contentView = view
        super.init()
    }

    func receive(_ frame: Frame) {
        let (_, micJustDied) = levels.push(frame, at: ProcessInfo.processInfo.systemUptime)
        if micJustDied { DispatchQueue.main.async { NSSound(named: "Basso")?.play() } }
        DispatchQueue.main.async { if !self.visible { self.show() } }
    }

    private func show() {
        visible = true
        view.palette = .fromTheme()
        let screen = (NSScreen.main ?? NSScreen.screens[0]).frame
        panel.setFrameOrigin(NSPoint(x: screen.midX - stripSize.width / 2,
                                     y: screen.maxY - screen.height * topMargin - stripSize.height))
        panel.orderFrontRegardless()
        let link = view.displayLink(target: self, selector: #selector(tick))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    @objc private func tick() {
        if levels.secondsSinceLastFrame(at: ProcessInfo.processInfo.systemUptime) > hideAfterSecs {
            visible = false
            displayLink?.invalidate()
            displayLink = nil
            panel.orderOut(nil)
            if let summary = levels.finish() { log(summary) }
        } else {
            view.needsDisplay = true
        }
    }
}

/// Draws the strip from made-up audio into PNGs, to check the look without a mic or a screen.
func writeSnapshots(to directory: String) {
    func speech(_ t: Double, level: Float) -> Float {
        let inWord = t.truncatingRemainder(dividingBy: 0.8) < 0.6
        let syllable = Float(0.5 + 0.5 * sin(2 * .pi * 4 * t))
        return 0.002 + (inWord ? level * syllable * Float.random(in: 0.6...1) : 0)
    }
    let scenes: [(name: String, seconds: Double, amplitude: (Double) -> Float)] = [
        ("speech", 4, { speech($0, level: 0.06) }),
        ("loud", 4, { speech($0, level: 0.25) }),
        ("pause", 4, { $0 < 2.5 ? speech($0, level: 0.06) : 0.002 }),
        ("start", 0.8, { speech($0, level: 0.06) }),
        ("dead", 2, { _ in 0 }),
    ]
    for scene in scenes {
        let levels = Levels()
        let view = StripView(levels: levels)
        let count = Int(scene.seconds * frameHz)
        for i in 0..<count {
            let a = scene.amplitude(Double(i) / frameHz)
            let db = a <= 1e-6 ? -120 : 20 * log10(a)
            _ = levels.push(Frame(seq: UInt32(i), min: -a * Float.random(in: 0.8...1), max: a * Float.random(in: 0.8...1),
                                  peakDb: db), at: Double(i) / frameHz)
        }
        view.now = { Double(count - 1) / frameHz }
        let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds)!
        view.cacheDisplay(in: view.bounds, to: rep)
        let path = "\(directory)/\(scene.name).png"
        try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: path))
        print(path)
    }
}

let arguments = CommandLine.arguments
func option(_ name: String) -> String? {
    arguments.firstIndex(of: name).flatMap { arguments.indices.contains($0 + 1) ? arguments[$0 + 1] : nil }
}

if let directory = option("--snapshot") {
    writeSnapshots(to: directory)
    exit(0)
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let overlay = Overlay()
let socketPath = option("--socket") ?? "/tmp/voxtype/audio.sock"
Thread.detachNewThread { readFrames(from: socketPath) { overlay.receive($0) } }
app.run()
