// Runs the command given as its argument on every macOS Space change. AeroSpace doesn't use Spaces,
// so here that means a window entering or leaving native fullscreen, which AeroSpace has no callback for.
import AppKit

NSWorkspace.shared.notificationCenter.addObserver(
    forName: NSWorkspace.activeSpaceDidChangeNotification, object: nil, queue: .main
) { _ in
    let process = Process()
    process.executableURL = URL(fileURLWithPath: CommandLine.arguments[1])
    try? process.run()
}
NSApplication.shared.run()
