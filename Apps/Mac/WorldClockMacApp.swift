import AppKit
import SwiftUI
import WorldClockUI

@main
struct WorldClockMacApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @State private var clock = ClockViewModel.live()
    @State private var compare = CompareViewModel.live()
    /// The windows' colors (a Settings choice in M7).
    private let themes = ThemePair.solarized

    /// Each `Window` scene gets a Window menu item; the shortcuts are ⌘1 and ⌘2. The first
    /// scene (Clock) is the one that opens at launch and on a Dock click.
    var body: some Scene {
        Window("Clock", id: "clock") {
            ClockView(model: clock).themed(themes)
        }
        // The content can grow (its text scales with the window), so without a default size
        // the window opens large. This is below the content's natural size, which is the
        // minimum, so a new window opens at exactly its natural size.
        .defaultSize(width: 200, height: 100)
        // No title bar (the close/minimize buttons stay). ClockView makes the whole clock a
        // drag handle (`ScalingWindow`); the scene's background drag doesn't reach under it.
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .keyboardShortcut("1")

        Window("Compare", id: "compare") {
            CompareView(model: compare).themed(themes)
        }
        // No title bar, like the Clock window; CompareView makes its background a drag handle.
        .windowStyle(.hiddenTitleBar)
        // Below the content's natural size (its minimum), so a new window opens at exactly that
        // size; the content grows with the window, like the Clock's.
        .defaultSize(width: 200, height: 100)
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
