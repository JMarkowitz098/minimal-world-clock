import Foundation
import Observation
import WorldClockCore

/// The Settings window's choices: 12/24-hour time, the color theme, and launch at login. Saved in
/// `store` (the App Group's, so the widget reads them too), except launch at login, which macOS
/// keeps (`LoginItem`). `onChange` tells the app what to update: the windows' locale, their
/// theme (views read `theme` directly), and the widget.
@MainActor @Observable public final class SettingsViewModel {
    /// What changed, so the app updates only what depends on it.
    public enum Change: Equatable, Sendable {
        /// `locale` changed: the 12/24-hour choice, or the Mac's region settings.
        case locale
        case theme
    }

    public var timeFormat: TimeFormat {
        get { settings.timeFormat }
        set {
            guard newValue != settings.timeFormat else { return }
            settings.timeFormat = newValue
            save(.locale)
        }
    }

    /// The theme both windows and the widget draw in; the default theme when the saved one is
    /// unknown (e.g. removed in a later version).
    public var theme: Theme {
        get { Theme.named(settings.theme) ?? Theme.default }
        set {
            guard newValue.id != settings.theme else { return }
            settings.theme = newValue.id
            save(.theme)
        }
    }

    /// The locale to format times and dates in: the Mac's, with the 12/24-hour choice applied.
    public var locale: Locale { baseLocale.applying(settings.timeFormat) }

    /// Whether the app opens when the user logs in. Read from macOS (`refreshLoginItem` when the
    /// window opens, since System Settings can change it); a change macOS refuses is logged and
    /// leaves the toggle as macOS has it.
    public var launchesAtLogin: Bool {
        get { loginItemEnabled }
        set {
            do {
                try loginItem.setEnabled(newValue)
            } catch {
                Log.settings.error("Couldn't \(newValue ? "add" : "remove", privacy: .public) the login item: \(String(describing: error), privacy: .public)")
            }
            loginItemEnabled = loginItem.isEnabled
        }
    }

    /// Called after a setting changes; the app updates the windows and reloads the widget.
    @ObservationIgnored public var onChange: @MainActor (Change) -> Void = { _ in }

    private var settings: AppSettings
    private var loginItemEnabled: Bool
    @ObservationIgnored private let store: SettingsStore
    @ObservationIgnored private let loginItem: LoginItem
    @ObservationIgnored private let baseLocale: Locale
    @ObservationIgnored private var localeObserver: (any NSObjectProtocol)?

    /// - Parameters:
    ///   - store: where the choices are saved; shared with the widget in the app.
    ///   - baseLocale: the Mac's locale (`.autoupdatingCurrent` in the app).
    public init(store: SettingsStore, loginItem: LoginItem, baseLocale: Locale = .autoupdatingCurrent) {
        self.store = store
        self.loginItem = loginItem
        self.baseLocale = baseLocale
        settings = store.appSettings
        loginItemEnabled = loginItem.isEnabled
        if Theme.named(settings.theme) == nil {
            store.reportUnreadable(key: SettingsKey.appSettings, error: UnknownTheme(id: settings.theme))
        }
    }

    /// Reads launch at login from macOS again. Call when the Settings window opens.
    public func refreshLoginItem() {
        loginItemEnabled = loginItem.isEnabled
    }

    /// The Mac's region settings changed (e.g. its 24-hour switch); formatters must be rebuilt.
    public func systemLocaleChanged() {
        onChange(.locale)
    }

    private func save(_ change: Change) {
        store.appSettings = settings
        onChange(change)
    }
}

extension SettingsViewModel {
    #if os(macOS)
    /// The app's model: saved in the App Group (shared with the widget), the app as login
    /// item, the Mac's locale, and `systemLocaleChanged` when its region settings change.
    public static func live() -> SettingsViewModel {
        let model = SettingsViewModel(store: AppGroup.settingsStore(), loginItem: MainAppLoginItem())
        model.localeObserver = NotificationCenter.default.addObserver(
            forName: NSLocale.currentLocaleDidChangeNotification, object: nil, queue: .main
        ) { [weak model] _ in
            MainActor.assumeIsolated { model?.systemLocaleChanged() }
        }
        return model
    }
    #endif
}

/// A saved theme identifier that no theme has.
struct UnknownTheme: Error {
    let id: String
}

/// Whether the app opens at login. macOS keeps this state; the app's is `SMAppService.mainApp`.
@MainActor public protocol LoginItem: AnyObject {
    var isEnabled: Bool { get }
    func setEnabled(_ enabled: Bool) throws
}

#if os(macOS)
import ServiceManagement

/// The app itself as a login item (`SMAppService.mainApp`, macOS 13+; no helper app needed).
@MainActor public final class MainAppLoginItem: LoginItem {
    public init() {}

    public var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    public func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}
#endif
