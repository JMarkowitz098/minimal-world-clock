import SwiftUI
import Testing
@testable import WorldClockUI

@Test @MainActor func uiModuleLoads() {
    _ = TimeDisplay(time: "9:00", date: "Thursday, January 15", offset: "UTC+9") { EmptyView() }
}
