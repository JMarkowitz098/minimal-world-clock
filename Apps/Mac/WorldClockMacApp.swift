import AppKit
import SwiftUI
import WorldClockUI

@main
struct WorldClockMacApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @State private var clock = ClockViewModel.live()

    var body: some Scene {
        Window("Clock", id: "clock") {
            ClockView(model: clock)
        }
        .windowResizability(.contentSize)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    /// A Dock app stays open with its windows closed; clicking the Dock icon reopens the Clock window.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
