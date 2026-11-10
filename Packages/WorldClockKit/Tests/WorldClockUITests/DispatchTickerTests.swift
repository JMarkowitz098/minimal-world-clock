import Foundation
import Testing
@testable import WorldClockUI

// These use the real main queue and real time, with short deadlines.

@Test @MainActor func dispatchTickerFiresAtTheDeadline() async throws {
    let ticker = DispatchTicker()
    var firedAt: Date?
    let deadline = Date().addingTimeInterval(0.05)
    ticker.schedule(at: deadline) { firedAt = Date() }
    try await Task.sleep(for: .milliseconds(300))
    let fired = try #require(firedAt)
    #expect(fired >= deadline.addingTimeInterval(-0.01))
}

@Test @MainActor func dispatchTickerCancelDropsThePendingCall() async throws {
    let ticker = DispatchTicker()
    var fired = false
    ticker.schedule(at: Date().addingTimeInterval(0.05)) { fired = true }
    ticker.cancel()
    try await Task.sleep(for: .milliseconds(300))
    #expect(!fired)
}

@Test @MainActor func dispatchTickerScheduleReplacesThePendingCall() async throws {
    let ticker = DispatchTicker()
    var calls: [String] = []
    ticker.schedule(at: Date().addingTimeInterval(0.05)) { calls.append("first") }
    ticker.schedule(at: Date().addingTimeInterval(0.05)) { calls.append("second") }
    try await Task.sleep(for: .milliseconds(300))
    #expect(calls == ["second"])
}
