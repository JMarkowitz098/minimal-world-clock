import Testing
@testable import WorldClockCore

@Test func coreModuleLoads() {
    #expect(!WorldClockCore.version.isEmpty)
}
