import SwiftUI
import Testing
@testable import WorldClockUI

@Test @MainActor func uiModuleLoads() {
    _ = EditableTime(time: "9:00", label: "Time in Tokyo", theme: .solarizedLight) { _ in true }
}
