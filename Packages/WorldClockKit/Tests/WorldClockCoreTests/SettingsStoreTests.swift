import Foundation
import Testing
@testable import WorldClockCore

/// A fresh, empty UserDefaults suite, removed when the test's closure returns.
private func withTemporaryDefaults(_ body: (UserDefaults) throws -> Void) rethrows {
    let name = "WorldClockCoreTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: name)!
    defer { defaults.removePersistentDomain(forName: name) }
    try body(defaults)
}

@Test func clockZoneRoundTripsThroughUserDefaults() {
    withTemporaryDefaults { defaults in
        UserDefaultsSettingsStore(defaults: defaults).clockZone = zone("Asia/Tokyo")
        // A new store over the same defaults stands in for a relaunch.
        #expect(UserDefaultsSettingsStore(defaults: defaults).clockZone == zone("Asia/Tokyo"))
    }
}

@Test func missingClockZoneIsNil() {
    withTemporaryDefaults { defaults in
        #expect(UserDefaultsSettingsStore(defaults: defaults).clockZone == nil)
    }
}

@Test func corruptClockZoneIsNil() {
    withTemporaryDefaults { defaults in
        defaults.set(Data("not json".utf8), forKey: SettingsKey.clockZone)
        #expect(UserDefaultsSettingsStore(defaults: defaults).clockZone == nil)
    }
}

@Test func unknownSavedZoneIsNil() {
    let store = InMemorySettingsStore()
    store.setData(Data(#""Mars/Olympus_Mons""#.utf8), forKey: SettingsKey.clockZone)
    #expect(store.clockZone == nil)
}

@Test func wrongTypeInUserDefaultsIsNil() {
    withTemporaryDefaults { defaults in
        defaults.set(42, forKey: SettingsKey.clockZone)
        #expect(UserDefaultsSettingsStore(defaults: defaults).clockZone == nil)
    }
}

@Test func inMemoryStoreRoundTrips() {
    let store = InMemorySettingsStore()
    store.clockZone = zone("Europe/London")
    #expect(store.clockZone == zone("Europe/London"))
}

@Test func savingNilRemovesTheValue() {
    let store = InMemorySettingsStore()
    store.clockZone = zone("Europe/London")
    store.clockZone = nil
    #expect(store.data(forKey: SettingsKey.clockZone) == nil)
}

@Test func valueThatFailsToEncodeKeepsTheSavedOne() {
    struct Unencodable: Encodable {
        func encode(to encoder: any Encoder) throws { throw EncodingError.invalidValue(0, .init(codingPath: [], debugDescription: "")) }
    }
    let store = InMemorySettingsStore()
    store.clockZone = zone("Europe/London")
    store.save(Unencodable(), forKey: SettingsKey.clockZone)
    #expect(store.clockZone == zone("Europe/London"))
}
