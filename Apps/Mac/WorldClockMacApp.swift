import SwiftUI
import WorldClockUI

@main
struct WorldClockMacApp: App {
    var body: some Scene {
        WindowGroup("Clock", id: "clock") {
            PlaceholderView()
        }
        .windowResizability(.contentSize)
    }
}
