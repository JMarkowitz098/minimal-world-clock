import Foundation
import SwiftUI
import Testing
@testable import WorldClockCore
@testable import WorldClockUI

/// A login item the test controls; `failNext` makes the next change throw, as macOS can.
@MainActor final class FakeLoginItem: LoginItem {
    var isEnabled = false
    var failNext = false
    struct Refused: Error {}

    func setEnabled(_ enabled: Bool) throws {
        if failNext {
            failNext = false
            throw Refused()
        }
        isEnabled = enabled
    }
}

/// Records what the store reports as unreadable.
private final class ReportingStore: SettingsStore {
    private let inner = InMemorySettingsStore()
    var reported: [String] = []
    func data(forKey key: String) -> Data? { inner.data(forKey: key) }
    func setData(_ data: Data?, forKey key: String) { inner.setData(data, forKey: key) }
    func reportUnreadable(key: String, error: any Error) { reported.append(key) }
}

@MainActor private func makeSettings(
    store: SettingsStore = InMemorySettingsStore(),
    loginItem: FakeLoginItem = FakeLoginItem()
) -> SettingsViewModel {
    SettingsViewModel(store: store, loginItem: loginItem, baseLocale: Locale(identifier: "en_US"))
}

@MainActor @Test func settingsModelStartsWithTheDefaults() {
    let model = makeSettings()
    #expect(model.timeFormat == .system)
    #expect(model.theme == .solarizedLight)
    #expect(model.locale.usesTwelveHourTime)
}

@MainActor @Test func settingsModelReadsSavedSettings() {
    let store = InMemorySettingsStore()
    store.appSettings = AppSettings(timeFormat: .twentyFourHour, theme: Theme.solarizedDark.id)
    let model = makeSettings(store: store)
    #expect(model.timeFormat == .twentyFourHour)
    #expect(model.theme == .solarizedDark)
    #expect(!model.locale.usesTwelveHourTime)
}

@MainActor @Test func changingTheTimeFormatSavesItAndNotifies() {
    let store = InMemorySettingsStore()
    let model = makeSettings(store: store)
    var changes: [SettingsViewModel.Change] = []
    model.onChange = { changes.append($0) }
    model.timeFormat = .twentyFourHour
    #expect(store.appSettings.timeFormat == .twentyFourHour)
    #expect(!model.locale.usesTwelveHourTime)
    #expect(changes == [.locale])
}

@MainActor @Test func changingTheThemeSavesItAndNotifies() {
    let store = InMemorySettingsStore()
    let model = makeSettings(store: store)
    var changes: [SettingsViewModel.Change] = []
    model.onChange = { changes.append($0) }
    model.theme = .solarizedDark
    #expect(store.appSettings.theme == Theme.solarizedDark.id)
    #expect(changes == [.theme])
}

@MainActor @Test func settingTheSameValueDoesNothing() {
    let model = makeSettings()
    var changes: [SettingsViewModel.Change] = []
    model.onChange = { changes.append($0) }
    model.timeFormat = .system
    model.theme = .solarizedLight
    #expect(changes.isEmpty)
}

@MainActor @Test func unknownSavedThemeUsesTheDefaultAndIsReported() {
    let store = ReportingStore()
    store.appSettings = AppSettings(theme: "retiredTheme")
    let model = makeSettings(store: store)
    #expect(model.theme == Theme.named(AppSettings.defaultTheme))
    #expect(store.reported == [SettingsKey.appSettings])
}

@MainActor @Test func everyThemeHasAUniqueID() {
    let ids = Theme.all.map(\.id)
    #expect(Set(ids).count == ids.count)
    #expect(Theme.named(AppSettings.defaultTheme) != nil)
}

@MainActor @Test func systemLocaleChangeNotifies() {
    let model = makeSettings()
    var changes: [SettingsViewModel.Change] = []
    model.onChange = { changes.append($0) }
    model.systemLocaleChanged()
    #expect(changes == [.locale])
}

@MainActor @Test func launchAtLoginFollowsTheLoginItem() {
    let item = FakeLoginItem()
    item.isEnabled = true
    let model = makeSettings(loginItem: item)
    #expect(model.launchesAtLogin)
    model.launchesAtLogin = false
    #expect(!item.isEnabled)
    #expect(!model.launchesAtLogin)
}

@MainActor @Test func refusedLaunchAtLoginChangeKeepsTheSystemState() {
    let item = FakeLoginItem()
    let model = makeSettings(loginItem: item)
    item.failNext = true
    model.launchesAtLogin = true
    #expect(!model.launchesAtLogin)
    #expect(!item.isEnabled)
}

@MainActor @Test func launchAtLoginIsReadAgainWhenTheWindowOpens() {
    // The user can turn it off in System Settings → General → Login Items meanwhile.
    let item = FakeLoginItem()
    let model = makeSettings(loginItem: item)
    item.isEnabled = true
    model.refreshLoginItem()
    #expect(model.launchesAtLogin)
}

@Test func darkThemesHaveDarkBackgrounds() {
    // `isDark` picks the window's appearance for system controls; it must match the colors.
    for theme in Theme.all {
        let c = theme.background.resolve(in: EnvironmentValues())
        let luminance = 0.2126 * c.linearRed + 0.7152 * c.linearGreen + 0.0722 * c.linearBlue
        #expect(theme.isDark == (luminance < 0.18), "\(theme.name)")
    }
}
