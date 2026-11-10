import AppKit
import SwiftUI
import WorldClockUI

@main
struct WorldClockMacApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @State private var clock = ClockViewModel.live()
    @State private var compare = CompareViewModel.live()

    /// Each `Window` scene gets a Window menu item; the shortcuts are ⌘1 and ⌘2. The first
    /// scene (Clock) is the one that opens at launch and on a Dock click.
    var body: some Scene {
        Window("Clock", id: "clock") {
            ClockView(model: clock, themes: .solarized)
        }
        // The content can grow (its text scales with the window), so without a default size
        // the window opens large. This is below the content's natural size, which is the
        // minimum, so a new window opens at exactly its natural size.
        .defaultSize(width: 200, height: 100)
        // No title bar (the close/minimize buttons stay). ClockView makes the whole clock a
        // drag handle (WindowDragGesture); the scene's background drag doesn't reach under it.
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .keyboardShortcut("1")

        Window("Compare", id: "compare") {
            CompareView(model: compare, themes: .solarized)
        }
        // No title bar, like the Clock window; CompareView makes its background a drag handle.
        .windowStyle(.hiddenTitleBar)
        // Without a default size the window opens as wide as the slider's ideal width (900 pt).
        .defaultSize(width: 640, height: 260)
        .windowResizability(.contentSize)
        .keyboardShortcut("2")
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    /// A Dock app stays open with its windows closed; clicking the Dock icon reopens the Clock window.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
