import Foundation
import Testing
@testable import WorldClockCore

/// Saves `json` as the app settings and reads them back.
private func settings(fromJSON json: String) -> AppSettings {
    let store = InMemorySettingsStore()
    store.setData(Data(json.utf8), forKey: SettingsKey.appSettings)
    return store.appSettings
}

@Test func settingsDefaults() {
    let settings = AppSettings()
    #expect(settings.timeFormat == .system)
    #expect(settings.theme == AppSettings.defaultTheme)
}

@Test func missingSettingsReadAsDefaults() {
    #expect(InMemorySettingsStore().appSettings == AppSettings())
}

@Test func settingsRoundTrip() {
    let store = InMemorySettingsStore()
    store.appSettings = AppSettings(timeFormat: .twentyFourHour, theme: "nord")
    #expect(store.appSettings == AppSettings(timeFormat: .twentyFourHour, theme: "nord"))
}

@Test func missingKeysUseDefaults() {
    #expect(settings(fromJSON: #"{"theme":"nord"}"#) == AppSettings(timeFormat: .system, theme: "nord"))
    #expect(settings(fromJSON: #"{"timeFormat":"twelveHour"}"#) == AppSettings(timeFormat: .twelveHour))
    #expect(settings(fromJSON: "{}") == AppSettings())
}

@Test func unknownValuesUseDefaults() {
    // A value from a newer version (or a typo) falls back for that key only.
    #expect(settings(fromJSON: #"{"timeFormat":"decimal","theme":"nord"}"#) == AppSettings(timeFormat: .system, theme: "nord"))
    #expect(settings(fromJSON: #"{"timeFormat":"twelveHour","theme":42}"#) == AppSettings(timeFormat: .twelveHour))
}

@Test func unknownKeysAreIgnored() {
    #expect(settings(fromJSON: #"{"showsSeconds":true,"theme":"nord"}"#) == AppSettings(theme: "nord"))
}

private final class ReportingStore: SettingsStore {
    var data: Data?
    var reported: [String] = []
    init(_ json: String) { data = Data(json.utf8) }
    func data(forKey key: String) -> Data? { data }
    func setData(_ data: Data?, forKey key: String) { self.data = data }
    func reportUnreadable(key: String, error: any Error) { reported.append(key) }
}

@Test func corruptSettingsReadAsDefaultsAndAreReported() {
    let store = ReportingStore("not json")
    #expect(store.appSettings == AppSettings())
    #expect(store.reported == [SettingsKey.appSettings])
}

@Test func unknownSettingValueIsReported() {
    let store = ReportingStore(#"{"timeFormat":"decimal","theme":"nord"}"#)
    _ = store.appSettings
    #expect(store.reported == [SettingsKey.appSettings])
}

@Test func missingSettingKeyIsNotReported() {
    let store = ReportingStore(#"{"theme":"nord"}"#)
    _ = store.appSettings
    #expect(store.reported.isEmpty)
}
