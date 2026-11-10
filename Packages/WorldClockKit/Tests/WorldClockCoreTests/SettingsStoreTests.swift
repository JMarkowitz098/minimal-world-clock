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

@Test func compareZonesRoundTripThroughUserDefaults() {
    withTemporaryDefaults { defaults in
        let store = UserDefaultsSettingsStore(defaults: defaults)
        store.compareZoneA = zone("America/New_York")
        store.compareZoneB = zone("Asia/Tokyo")
        let relaunched = UserDefaultsSettingsStore(defaults: defaults)
        #expect(relaunched.compareZoneA == zone("America/New_York"))
        #expect(relaunched.compareZoneB == zone("Asia/Tokyo"))
    }
}

@Test func compareZonesAreSavedIndependently() {
    let store = InMemorySettingsStore()
    store.compareZoneA = zone("Europe/London")
    store.setData(Data("garbage".utf8), forKey: SettingsKey.compareZoneB)
    #expect(store.compareZoneA == zone("Europe/London"))
    #expect(store.compareZoneB == nil)
}

@Test func unreadableSavedValueIsReported() {
    // Reading still falls back to nil, but the failure isn't silent: the app logs it.
    withTemporaryDefaults { defaults in
        var reports: [String] = []
        let store = UserDefaultsSettingsStore(defaults: defaults) { key, _ in reports.append(key) }
        store.setData(Data("garbage".utf8), forKey: SettingsKey.clockZone)
        #expect(store.clockZone == nil)
        #expect(reports == [SettingsKey.clockZone])
    }
}

@Test func missingSavedValueIsNotReported() {
    withTemporaryDefaults { defaults in
        var reports: [String] = []
        let store = UserDefaultsSettingsStore(defaults: defaults) { key, _ in reports.append(key) }
        #expect(store.clockZone == nil)
        #expect(reports.isEmpty)
    }
}
