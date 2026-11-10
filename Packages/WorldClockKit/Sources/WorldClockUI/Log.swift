import os
import WorldClockCore

/// Where the app and widget log, for diagnosing bugs in Console.app (filter by the subsystem
/// `com.jaredmarkowitz.minimalworldclock`). Log what fails or falls back silently, never the
/// time on each tick.
public enum Log {
    static let subsystem = "com.jaredmarkowitz.minimalworldclock"
    /// Saved settings that can't be read.
    public static let settings = Logger(subsystem: subsystem, category: "settings")
    /// The widget's timelines and zone lookups.
    public static let widget = Logger(subsystem: subsystem, category: "widget")
}

extension UserDefaultsSettingsStore {
    /// The app's store: standard defaults, logging values it can't read.
    static func live() -> UserDefaultsSettingsStore {
        UserDefaultsSettingsStore { key, error in
            Log.settings.error("Couldn't read saved \(key, privacy: .public); using the default. \(String(describing: error), privacy: .public)")
        }
    }
}
