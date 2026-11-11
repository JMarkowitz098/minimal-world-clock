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
        UserDefaultsSettingsStore(defaults: defaults).clockPlace = place("Asia/Tokyo")
        // A new store over the same defaults stands in for a relaunch.
        #expect(UserDefaultsSettingsStore(defaults: defaults).clockPlace == place("Asia/Tokyo"))
    }
}

@Test func missingClockZoneIsNil() {
    withTemporaryDefaults { defaults in
        #expect(UserDefaultsSettingsStore(defaults: defaults).clockPlace == nil)
    }
}

@Test func corruptClockZoneIsNil() {
    withTemporaryDefaults { defaults in
        defaults.set(Data("not json".utf8), forKey: SettingsKey.clockZone)
        #expect(UserDefaultsSettingsStore(defaults: defaults).clockPlace == nil)
    }
}

@Test func unknownSavedZoneIsNil() {
    let store = InMemorySettingsStore()
    store.setData(Data(#""Mars/Olympus_Mons""#.utf8), forKey: SettingsKey.clockZone)
    #expect(store.clockPlace == nil)
}

@Test func wrongTypeInUserDefaultsIsNil() {
    withTemporaryDefaults { defaults in
        defaults.set(42, forKey: SettingsKey.clockZone)
        #expect(UserDefaultsSettingsStore(defaults: defaults).clockPlace == nil)
    }
}

@Test func inMemoryStoreRoundTrips() {
    let store = InMemorySettingsStore()
    store.clockPlace = place("Europe/London")
    #expect(store.clockPlace == place("Europe/London"))
}

@Test func savingNilRemovesTheValue() {
    let store = InMemorySettingsStore()
    store.clockPlace = place("Europe/London")
    store.clockPlace = nil
    #expect(store.data(forKey: SettingsKey.clockZone) == nil)
}

@Test func valueThatFailsToEncodeKeepsTheSavedOne() {
    struct Unencodable: Encodable {
        func encode(to encoder: any Encoder) throws { throw EncodingError.invalidValue(0, .init(codingPath: [], debugDescription: "")) }
    }
    let store = InMemorySettingsStore()
    store.clockPlace = place("Europe/London")
    store.save(Unencodable(), forKey: SettingsKey.clockZone)
    #expect(store.clockPlace == place("Europe/London"))
}

@Test func compareZonesRoundTripThroughUserDefaults() {
    withTemporaryDefaults { defaults in
        let store = UserDefaultsSettingsStore(defaults: defaults)
        store.comparePlaceA = place("America/New_York")
        store.comparePlaceB = place("Asia/Tokyo")
        let relaunched = UserDefaultsSettingsStore(defaults: defaults)
        #expect(relaunched.comparePlaceA == place("America/New_York"))
        #expect(relaunched.comparePlaceB == place("Asia/Tokyo"))
    }
}

@Test func compareZonesAreSavedIndependently() {
    let store = InMemorySettingsStore()
    store.comparePlaceA = place("Europe/London")
    store.setData(Data("garbage".utf8), forKey: SettingsKey.compareZoneB)
    #expect(store.comparePlaceA == place("Europe/London"))
    #expect(store.comparePlaceB == nil)
}

@Test func unreadableSavedValueIsReported() {
    // Reading still falls back to nil, but the failure isn't silent: the app logs it.
    withTemporaryDefaults { defaults in
        var reports: [String] = []
        let store = UserDefaultsSettingsStore(defaults: defaults) { key, _ in reports.append(key) }
        store.setData(Data("garbage".utf8), forKey: SettingsKey.clockZone)
        #expect(store.clockPlace == nil)
        #expect(reports == [SettingsKey.clockZone])
    }
}

@Test func missingSavedValueIsNotReported() {
    withTemporaryDefaults { defaults in
        var reports: [String] = []
        let store = UserDefaultsSettingsStore(defaults: defaults) { key, _ in reports.append(key) }
        #expect(store.clockPlace == nil)
        #expect(reports.isEmpty)
    }
}
