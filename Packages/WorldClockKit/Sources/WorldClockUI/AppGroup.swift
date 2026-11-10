import Foundation
import WorldClockCore

/// The App Group the app and the widget share, so the widget reads the Settings window's
/// choices (`AppSettings`). Prefixed with the team ID, the macOS form: it needs no provisioning
/// profile (the `group.` form does) and doesn't make macOS ask the user for access to "data
/// from other apps". Both targets list it in their entitlements. The windows' zones stay in
/// the app's own defaults.
public enum AppGroup {
    public static let id = "Y7W4DC22F6.com.jaredmarkowitz.minimalworldclock"

    /// The shared store for `AppSettings`, logging values it can't read. Falls back to the
    /// process's own defaults (logged) if the group's can't be opened, e.g. when the
    /// entitlement is missing.
    public static func settingsStore() -> UserDefaultsSettingsStore {
        let defaults = UserDefaults(suiteName: id) ?? {
            Log.settings.error("Couldn't open the App Group's defaults (\(id, privacy: .public)); settings won't reach the widget.")
            return .standard
        }()
        return UserDefaultsSettingsStore(defaults: defaults) { key, error in
            Log.settings.error("Couldn't read saved \(key, privacy: .public); using the default. \(String(describing: error), privacy: .public)")
        }
    }
}
