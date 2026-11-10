import Foundation

/// How times are written: as the Mac's region settings say, or always 12- or 24-hour.
public enum TimeFormat: String, Codable, Sendable, CaseIterable {
    case system
    case twelveHour
    case twentyFourHour
}

/// What the user chose in the Settings window, shared by both windows and the widget. (Launch
/// at login isn't here: macOS keeps that state.) Saved as one value under
/// `SettingsKey.appSettings`; reading is lenient per key, so a missing, unknown or mistyped
/// value falls back to its default without losing the others.
public struct AppSettings: Equatable, Sendable {
    public static let defaultTheme = "solarizedLight"

    public var timeFormat: TimeFormat
    /// A theme's identifier (the UI's theme list). Kept as text so a theme removed in a later
    /// version reads as unknown in the UI, which then uses the default theme.
    public var theme: String

    public init(timeFormat: TimeFormat = .system, theme: String = AppSettings.defaultTheme) {
        self.timeFormat = timeFormat
        self.theme = theme
    }
}

extension AppSettings: Codable {
    private enum CodingKeys: String, CodingKey {
        case timeFormat, theme
    }

    /// Lenient: each key that's missing or unreadable keeps its default. An unreadable one (not
    /// a missing one) is listed in the decoder's `fallbacks` collector, if any, for reporting.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let fallbacks = decoder.userInfo[.settingsFallbacks] as? FallbackCollector
        func value<T: Decodable>(_ key: CodingKeys, _ type: T.Type) -> T? {
            guard container.contains(key) else { return nil }
            do {
                return try container.decode(type, forKey: key)
            } catch {
                fallbacks?.errors.append(error)
                return nil
            }
        }
        self.init(
            timeFormat: value(.timeFormat, TimeFormat.self) ?? .system,
            theme: value(.theme, String.self) ?? AppSettings.defaultTheme
        )
    }
}

extension CodingUserInfoKey {
    fileprivate static let settingsFallbacks = CodingUserInfoKey(rawValue: "settingsFallbacks")!
}

/// Collects the errors behind per-key fallbacks while decoding `AppSettings`.
private final class FallbackCollector: @unchecked Sendable {
    var errors: [any Error] = []
}

extension SettingsStore {
    /// The Settings window's choices; defaults when nothing (or nothing readable) is saved.
    /// Unreadable data or values are reported with `reportUnreadable`.
    public var appSettings: AppSettings {
        get {
            guard let data = data(forKey: SettingsKey.appSettings) else { return AppSettings() }
            let fallbacks = FallbackCollector()
            let decoder = JSONDecoder()
            decoder.userInfo[.settingsFallbacks] = fallbacks
            do {
                let settings = try decoder.decode(AppSettings.self, from: data)
                if let error = fallbacks.errors.first { reportUnreadable(key: SettingsKey.appSettings, error: error) }
                return settings
            } catch {
                reportUnreadable(key: SettingsKey.appSettings, error: error)
                return AppSettings()
            }
        }
        set { save(newValue, forKey: SettingsKey.appSettings) }
    }
}
